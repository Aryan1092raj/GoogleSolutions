package com.example.resqlink_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var audioCaptureHandler: AudioCaptureChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = AudioCaptureChannelHandler()
        audioCaptureHandler = handler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "resqlink/audio_capture",
        ).setMethodCallHandler(handler)
    }

    override fun onDestroy() {
        audioCaptureHandler?.dispose()
        audioCaptureHandler = null
        super.onDestroy()
    }
}
