import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioCaptureHandler: AudioCaptureChannelHandler?
  private var audioCaptureChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioCaptureChannel(with: engineBridge.pluginRegistry)
  }

  private func registerAudioCaptureChannel(with registry: FlutterPluginRegistry) {
    guard audioCaptureHandler == nil else {
      return
    }

    guard let registrar = registry.registrar(forPlugin: "ResQLinkAudioCaptureChannel") else {
      return
    }

    let handler = AudioCaptureChannelHandler()
    audioCaptureHandler = handler

    let channel = FlutterMethodChannel(
      name: "resqlink/audio_capture",
      binaryMessenger: registrar.messenger()
    )
    audioCaptureChannel = channel
    channel.setMethodCallHandler { [weak handler] call, result in
      handler?.handle(call: call, result: result)
    }
  }

  deinit {
    audioCaptureChannel?.setMethodCallHandler(nil)
    audioCaptureHandler?.dispose()
  }
}
