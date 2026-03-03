package com.apobasi.driver

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * Application class for ApoBasi Driver App
 * Initializes notification channels for location tracking
 */
class LocationApp : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // High-importance channel used when a trip is actively in progress.
            // IMPORTANCE_HIGH causes a heads-up notification to appear so the
            // driver cannot miss it, and the OS will not silently suppress it.
            val tripChannel = NotificationChannel(
                LocationTrackingService.TRIP_CHANNEL_ID,
                "Active School Trip",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical alert shown while children are being transported — cannot be dismissed"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setShowBadge(true)
                // Vibrate once on first appearance, not on every update
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250)
                enableLights(true)
                lightColor = android.graphics.Color.BLUE
            }

            // Low-importance background channel kept for general location sharing
            // outside of active child-transport trips.
            val locationChannel = NotificationChannel(
                LocationTrackingService.CHANNEL_ID,
                "Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background location tracking channel"
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setShowBadge(false)
            }

            notificationManager.createNotificationChannel(tripChannel)
            notificationManager.createNotificationChannel(locationChannel)
        }
    }
}
