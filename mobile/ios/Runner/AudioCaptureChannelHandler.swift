import AVFoundation
import Flutter
import Foundation

final class AudioCaptureChannelHandler: NSObject {
  private let audioEngine = AVAudioEngine()
  private let syncQueue = DispatchQueue(label: "resqlink.audio.capture")
  private var pendingChunks: [String] = []
  private var converter: AVAudioConverter?
  private var outputFormat: AVAudioFormat?
  private var isRecording = false

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      do {
        try startRecording()
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "audio_start_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    case "pullChunk":
      result(pullChunk())
    case "stop":
      stopRecording()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func dispose() {
    stopRecording()
  }

  private func startRecording() throws {
    if isRecording {
      return
    }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker])
    try session.setActive(true, options: [])

    let inputNode = audioEngine.inputNode
    let inputFormat = inputNode.outputFormat(forBus: 0)
    let targetFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: 16_000,
      channels: 1,
      interleaved: true
    )

    guard let targetFormat else {
      throw NSError(
        domain: "ResQLinkAudio",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to create the target audio format."]
      )
    }

    converter = AVAudioConverter(from: inputFormat, to: targetFormat)
    outputFormat = targetFormat
    pendingChunks.removeAll(keepingCapacity: true)

    inputNode.removeTap(onBus: 0)
    inputNode.installTap(
      onBus: 0,
      bufferSize: 1024,
      format: inputFormat
    ) { [weak self] buffer, _ in
      self?.append(buffer: buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()
    isRecording = true
  }

  private func stopRecording() {
    if audioEngine.inputNode.numberOfInputs > 0 {
      audioEngine.inputNode.removeTap(onBus: 0)
    }

    if audioEngine.isRunning {
      audioEngine.stop()
    }

    converter = nil
    outputFormat = nil
    isRecording = false

    syncQueue.sync {
      pendingChunks.removeAll(keepingCapacity: false)
    }

    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }

  private func append(buffer: AVAudioPCMBuffer) {
    guard let converter, let outputFormat else {
      return
    }

    let targetFrames = AVAudioFrameCount(
      (Double(buffer.frameLength) * outputFormat.sampleRate / buffer.format.sampleRate).rounded(.up)
    )

    guard
      let convertedBuffer = AVAudioPCMBuffer(
        pcmFormat: outputFormat,
        frameCapacity: max(targetFrames, 1)
      )
    else {
      return
    }

    var error: NSError?
    var sourceConsumed = false

    let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
      if sourceConsumed {
        outStatus.pointee = .endOfStream
        return nil
      }

      sourceConsumed = true
      outStatus.pointee = .haveData
      return buffer
    }

    if status == .error || convertedBuffer.frameLength == 0 {
      return
    }

    guard let channelData = convertedBuffer.int16ChannelData else {
      return
    }

    let sampleCount = Int(convertedBuffer.frameLength * outputFormat.channelCount)
    let data = Data(
      bytes: channelData.pointee,
      count: sampleCount * MemoryLayout<Int16>.size
    )

    let encoded = data.base64EncodedString()
    syncQueue.async { [weak self] in
      guard let self else {
        return
      }
      self.pendingChunks.append(encoded)
      if self.pendingChunks.count > 8 {
        self.pendingChunks.removeFirst(self.pendingChunks.count - 8)
      }
    }
  }

  private func pullChunk() -> String {
    syncQueue.sync {
      guard !pendingChunks.isEmpty else {
        return ""
      }
      return pendingChunks.removeFirst()
    }
  }
}
