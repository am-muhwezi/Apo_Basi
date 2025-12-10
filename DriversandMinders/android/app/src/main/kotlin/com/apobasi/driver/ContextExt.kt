package com.apobasi.driver

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Extension functions for Context to check location permissions
 */

/**
 * Check if the app has both fine and coarse location permissions
 */
fun Context.hasLocationPermission(): Boolean {
    val fineLocation = ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED

    val coarseLocation = ContextCompat.checkSelfPermission(
        this,
        Manifest.permission.ACCESS_COARSE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED

    return fineLocation && coarseLocation
}

/**
 * Check if the app has background location permission (Android 10+)
 */
fun Context.hasBackgroundLocationPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    } else {
        // Background location not required on Android 9 and below
        true
    }
}

/**
 * Check if the app has all required location permissions including background
 */
fun Context.hasAllLocationPermissions(): Boolean {
    return hasLocationPermission() && hasBackgroundLocationPermission()
}

/**
 * Check if the app can post notifications (Android 13+)
 */
fun Context.hasNotificationPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    } else {
        // Notification permission not required on Android 12 and below
        true
    }
}
