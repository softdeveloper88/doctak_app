package com.kt.doctak

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.res.Configuration
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    
    companion object {
        private const val TAG = "DocTakDeepLink"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
        
        // Handle deep link if app is launched from a URL
        handleDeepLink(intent)
        
        // Create notification channel for incoming calls
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Channel for incoming calls with high importance
            val callChannel = NotificationChannel(
                "fcm_fallback_notification_channel",
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for incoming calls"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
                
                // Set default ringtone sound
                val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .build()
                setSound(defaultSoundUri, audioAttributes)
            }
            
            notificationManager?.createNotificationChannel(callChannel)
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep link when app is already running and brought to foreground
        handleDeepLink(intent)
    }
    
    private fun handleDeepLink(intent: Intent?) {
        intent?.data?.let { uri ->
            Log.d(TAG, "🔗 Deep link received: $uri")
            Log.d(TAG, "🔗 Scheme: ${uri.scheme}")
            Log.d(TAG, "🔗 Host: ${uri.host}")
            Log.d(TAG, "🔗 Path: ${uri.path}")
            // Flutter's app_links plugin will pick up the intent automatically
            // No additional handling needed here - just logging for debugging
        }
    }
}
