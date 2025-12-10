package com.apobasi.driver

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

class LocationTrackingService : Service() {

    companion object {
        const val CHANNEL_ID = "LocationTrackingChannel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "START_LOCATION_TRACKING"
        const val ACTION_STOP = "STOP_LOCATION_TRACKING"
        const val EXTRA_TOKEN = "auth_token"
        const val EXTRA_BUS_ID = "bus_id"
        const val EXTRA_API_URL = "api_url"

        // SharedPreferences keys
        private const val PREFS_NAME = "LocationServicePrefs"
        private const val KEY_AUTH_TOKEN = "auth_token"
        private const val KEY_BUS_ID = "bus_id"
        private const val KEY_API_URL = "api_url"
        private const val KEY_IS_TRACKING = "is_tracking"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var wakeLock: PowerManager.WakeLock
    private lateinit var prefs: SharedPreferences
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var authToken: String? = null
    private var busId: Int? = null
    private var apiUrl: String? = null
    private var isTracking = false
    private var locationUpdateCount = 0

    override fun onCreate() {
        super.onCreate()

        // Initialize SharedPreferences
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Initialize FusedLocationProviderClient
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        // Acquire wake lock to keep service running
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "ApoBasi::LocationTrackingWakeLock"
        )
        wakeLock.acquire(10 * 60 * 60 * 1000L) // 10 hours max

        // Setup location callback
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    handleLocationUpdate(location)
                }
            }
        }

        // Note: Notification channel is created in LocationApp.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                authToken = intent.getStringExtra(EXTRA_TOKEN)
                busId = intent.getIntExtra(EXTRA_BUS_ID, -1)
                apiUrl = intent.getStringExtra(EXTRA_API_URL)

                if (authToken != null && busId != -1 && apiUrl != null) {
                    // Save to SharedPreferences for service restart
                    prefs.edit().apply {
                        putString(KEY_AUTH_TOKEN, authToken)
                        putInt(KEY_BUS_ID, busId!!)
                        putString(KEY_API_URL, apiUrl)
                        putBoolean(KEY_IS_TRACKING, true)
                        apply()
                    }

                    startLocationTracking()
                }
            }
            ACTION_STOP -> {

                // Clear SharedPreferences
                prefs.edit().apply {
                    putBoolean(KEY_IS_TRACKING, false)
                    apply()
                }

                stopLocationTracking()
                stopSelf()
            }
            null -> {
                // Service restarted by system - restore from SharedPreferences
                val wasTracking = prefs.getBoolean(KEY_IS_TRACKING, false)

                if (wasTracking) {
                    authToken = prefs.getString(KEY_AUTH_TOKEN, null)
                    busId = prefs.getInt(KEY_BUS_ID, -1)
                    apiUrl = prefs.getString(KEY_API_URL, null)

                    if (authToken != null && busId != -1 && apiUrl != null) {
                        startLocationTracking()
                    }
                }
            }
        }

        // START_STICKY: Service will be restarted if killed by system
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)

        // Restart the service when app is swiped away
        val restartServiceIntent = Intent(applicationContext, LocationTrackingService::class.java).apply {
            action = ACTION_START
            putExtra(EXTRA_TOKEN, authToken)
            putExtra(EXTRA_BUS_ID, busId)
            putExtra(EXTRA_API_URL, apiUrl)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartServiceIntent)
        } else {
            applicationContext.startService(restartServiceIntent)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startLocationTracking() {
        if (isTracking) return
        isTracking = true

        // Create and show foreground notification
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Request location updates
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            5000L // 5 seconds interval
        ).apply {
            setMinUpdateIntervalMillis(3000L) // Minimum 3 seconds
            setMinUpdateDistanceMeters(10f) // Minimum 10 meters
            setWaitForAccurateLocation(false)
            setMaxUpdateDelayMillis(10000L)
        }.build()

        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        )
    }

    private fun stopLocationTracking() {
        if (!isTracking) return

        isTracking = false

        // Remove location updates
        fusedLocationClient.removeLocationUpdates(locationCallback)

        // Release wake lock
        if (wakeLock.isHeld) {
            wakeLock.release()
        }

        // Stop foreground service and remove notification
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun handleLocationUpdate(location: Location) {
        locationUpdateCount++

        // Send location to backend via coroutine
        serviceScope.launch {
            try {
                sendLocationToBackend(location)
                updateNotification(location)
            } catch (e: Exception) {
                // Silently handle errors - service continues running
            }
        }
    }

    private suspend fun sendLocationToBackend(location: Location) = withContext(Dispatchers.IO) {
        try {
            val url = URL("$apiUrl/api/buses/push-location/")
            val connection = url.openConnection() as HttpURLConnection

            connection.apply {
                requestMethod = "POST"
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Authorization", "Bearer $authToken")
                connectTimeout = 10000
                readTimeout = 10000
            }

            val jsonData = JSONObject().apply {
                put("lat", location.latitude)
                put("lng", location.longitude)
                put("speed", location.speed * 3.6) // Convert m/s to km/h
                put("heading", location.bearing.toDouble())
                put("accuracy", location.accuracy.toDouble())
            }

            connection.outputStream.use { os ->
                os.write(jsonData.toString().toByteArray())
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                // Successfully sent location
            }

            connection.disconnect()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, LocationTrackingService::class.java).apply {
            action = ACTION_STOP
        }

        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ApoBasi - Trip Active")
            .setContentText("Tracking bus location...")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop Tracking",
                stopPendingIntent
            )
            .build()
    }

    private fun updateNotification(location: Location) {
        val speedKmh = location.speed * 3.6
        val contentText = "Speed: ${"%.1f".format(speedKmh)} km/h | Updates: $locationUpdateCount"

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val stopIntent = Intent(this, LocationTrackingService::class.java).apply {
            action = ACTION_STOP
        }

        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ApoBasi - Sharing Location")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()

        // Ensure tracking is stopped
        if (isTracking) {
            stopLocationTracking()
        }

        // Cancel all coroutines
        serviceScope.cancel()

        // Remove notification completely
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.cancel(NOTIFICATION_ID)
    }
}
