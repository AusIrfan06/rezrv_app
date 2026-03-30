package com.rezrv.app

import android.os.Bundle // 🟢 1. ADD THIS IMPORT
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.rezrv.app/security"

    // 🟢 2. ADD THIS ONCREATE METHOD
    // This sets the security flag the MOMENT the app process starts
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Optional: If you want it secure by default before Flutter loads:
        // window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                val enable = call.argument<Boolean>("enable") ?: false
                if (enable) {
                    // 🟢 Hides content in app switcher and blocks screenshots
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    // 🟢 Allows content in app switcher and screenshots
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}