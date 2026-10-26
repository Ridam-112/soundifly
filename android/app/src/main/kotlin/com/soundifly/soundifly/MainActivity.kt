package com.soundifly.soundifly

import com.ryanheise.audioservice.AudioServiceActivity
import android.os.Bundle
import android.os.PowerManager
import android.content.Context

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

    override fun onResume() {
        super.onResume()
        if (wakeLock?.isHeld == false) {
            wakeLock?.acquire(24 * 60 * 60 * 1000L)
        }
    }

    override fun onDestroy() {
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        super.onDestroy()
    }
}
