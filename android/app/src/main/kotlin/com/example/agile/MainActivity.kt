package com.example.agile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val manager = getSystemService(NotificationManager::class.java)
        val sound = Uri.parse("android.resource://$packageName/${R.raw.agile_notification}")
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            "agile_notifications",
            "Notifikasi Agile",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(sound, attributes)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }
}
