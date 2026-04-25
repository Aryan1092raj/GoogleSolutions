package com.example.resqlink_mobile

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.concurrent.thread

class AudioCaptureChannelHandler : MethodChannel.MethodCallHandler {
    private val pendingChunks = ConcurrentLinkedQueue<String>()

    @Volatile
    private var isRecording = false

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                try {
                    startRecording()
                    result.success(null)
                } catch (error: SecurityException) {
                    result.error(
                        "audio_permission_denied",
                        "Microphone permission is required to capture SOS audio.",
                        null,
                    )
                } catch (error: IllegalStateException) {
                    result.error("audio_start_failed", error.message, null)
                }
            }

            "pullChunk" -> result.success(pendingChunks.poll() ?: "")
            "stop" -> {
                stopRecording()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    fun dispose() {
        stopRecording()
    }

    private fun startRecording() {
        if (isRecording) {
            return
        }

        val sampleRate = 16000
        val minBufferSize = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )

        if (minBufferSize <= 0) {
            throw IllegalStateException("Unable to determine microphone buffer size.")
        }

        val bufferSize = maxOf(minBufferSize, sampleRate / 2)
        val recorder = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize,
        )

        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            throw IllegalStateException("Microphone recorder failed to initialize.")
        }

        recorder.startRecording()
        audioRecord = recorder
        isRecording = true

        recordingThread = thread(
            start = true,
            isDaemon = true,
            name = "ResQLinkAudioCapture",
        ) {
            val buffer = ByteArray(bufferSize)
            while (isRecording) {
                val read = recorder.read(buffer, 0, buffer.size)
                if (read <= 0) {
                    continue
                }

                val encoded = Base64.encodeToString(
                    buffer.copyOf(read),
                    Base64.NO_WRAP,
                )
                pendingChunks.offer(encoded)
                while (pendingChunks.size > 8) {
                    pendingChunks.poll()
                }
            }
        }
    }

    private fun stopRecording() {
        if (!isRecording && audioRecord == null) {
            pendingChunks.clear()
            return
        }

        isRecording = false
        recordingThread?.join(200)
        recordingThread = null

        val recorder = audioRecord
        audioRecord = null
        if (recorder != null) {
            try {
                recorder.stop()
            } catch (_: IllegalStateException) {
                // Ignore stop failures during teardown.
            }
            recorder.release()
        }

        pendingChunks.clear()
    }
}
