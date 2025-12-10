package com.apobasi.driver

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat

object LocationServiceManager {

    fun startService(
        context: Context,
        authToken: String,
        busId: Int,
        apiUrl: String
    ) {
        val intent = Intent(context, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_START
            putExtra(LocationTrackingService.EXTRA_TOKEN, authToken)
            putExtra(LocationTrackingService.EXTRA_BUS_ID, busId)
            putExtra(LocationTrackingService.EXTRA_API_URL, apiUrl)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(context, intent)
        } else {
            context.startService(intent)
        }
    }

    fun stopService(context: Context) {
        val intent = Intent(context, LocationTrackingService::class.java).apply {
            action = LocationTrackingService.ACTION_STOP
        }
        context.startService(intent)
    }
}
