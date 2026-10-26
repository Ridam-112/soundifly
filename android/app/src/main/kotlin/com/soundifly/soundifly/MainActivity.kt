package com.soundifly.soundifly

import com.ryanheise.audioservice.AudioServiceActivity
import android.os.Bundle
import android.os.PowerManager
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.Settings

class MainActivity : AudioServiceActivity() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Soundifly::AudioPlaybackWakeLock"
        )
        wakeLock?.acquire(24 * 60 * 60 * 1000L) // 24h keep-alive for background audio
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.soundifly.soundifly/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        if (wakeLock?.isHeld == false) {
            wakeLock?.acquire(24 * 60 * 60 * 1000L)
        }
        resumeAllWebViews()
    }

    override fun onPause() {
        super.onPause()
        resumeAllWebViews()
    }

    override fun onStop() {
        super.onStop()
        resumeAllWebViews()
    }

    override fun onDestroy() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        super.onDestroy()
    }

    private fun resumeAllWebViews() {
        try {
            val root = window?.decorView ?: return
            fun findAndResume(view: View) {
                if (view is WebView) {
                    view.onResume()
                    view.resumeTimers()
                } else if (view is ViewGroup) {
                    for (i in 0 until view.childCount) {
                        findAndResume(view.getChildAt(i))
                    }
                }
            }
            findAndResume(root)
        } catch (_: Exception) {}
    }
}
