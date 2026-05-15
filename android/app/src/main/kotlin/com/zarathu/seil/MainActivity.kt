package com.zarathu.seil

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zarathu.seil/session_retention",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val durationSeconds = call.argument<Int>("durationSeconds") ?: 600
                    val activeSessions = call.argument<Int>("activeSessions") ?: 0
                    val intent = Intent(this, SessionRetentionService::class.java).apply {
                        action = SessionRetentionService.ACTION_START
                        putExtra(
                            SessionRetentionService.EXTRA_DURATION_SECONDS,
                            durationSeconds,
                        )
                        putExtra(
                            SessionRetentionService.EXTRA_ACTIVE_SESSIONS,
                            activeSessions,
                        )
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stop" -> {
                    val intent = Intent(this, SessionRetentionService::class.java).apply {
                        action = SessionRetentionService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
