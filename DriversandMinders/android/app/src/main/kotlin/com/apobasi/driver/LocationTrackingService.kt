package com.apobasi.driver

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import kotlinx.coroutines.*
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import android.util.Log
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant

class LocationTrackingService : Service() {

    companion object {
        private const val TAG = "ApoBasi.LocationSvc"
        const val CHANNEL_ID = "LocationTrackingChannel"
        // Dedicated high-importance channel for active child-transport trips
        const val TRIP_CHANNEL_ID = "TripActiveChannel"
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

    // ── WebSocket state ────────────────────────────────────────────────────────
    private val okHttpClient = OkHttpClient()
    private var webSocket: WebSocket? = null
    private var reconnectJob: Job? = null
    private var reconnectAttempts = 0
    private var isStopping = false

    override fun onCreate() {
        super.onCreate()

        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "ApoBasi::LocationTrackingWakeLock"
        )
        wakeLock.acquire(10 * 60 * 60 * 1000L) // 10 hours max

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    handleLocationUpdate(location)
                }
            }
        }

        // Note: Notification channels are created in LocationApp.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                authToken = intent.getStringExtra(EXTRA_TOKEN)
                busId = intent.getIntExtra(EXTRA_BUS_ID, -1)
                apiUrl = intent.getStringExtra(EXTRA_API_URL)

                if (authToken != null && busId != -1 && apiUrl != null) {
                    prefs.edit().apply {
                        putString(KEY_AUTH_TOKEN, authToken)
                        putInt(KEY_BUS_ID, busId!!)
                        putString(KEY_API_URL, apiUrl)
                        putBoolean(KEY_IS_TRACKING, true)
                        apply()
                    }
                    startLocationTracking()
                    isStopping = false
                    connectWebSocket()
                }
            }
            ACTION_STOP -> {
                prefs.edit().apply {
                    putBoolean(KEY_IS_TRACKING, false)
                    apply()
                }
                stopLocationTracking()
                stopSelf()
            }
            null -> {
                // Service restarted by system — restore from SharedPreferences
                val wasTracking = prefs.getBoolean(KEY_IS_TRACKING, false)
                if (wasTracking) {
                    authToken = prefs.getString(KEY_AUTH_TOKEN, null)
                    busId = prefs.getInt(KEY_BUS_ID, -1)
                    apiUrl = prefs.getString(KEY_API_URL, null)

                    if (authToken != null && busId != -1 && apiUrl != null) {
                        startLocationTracking()
                        isStopping = false
                        connectWebSocket()
                    }
                }
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)

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

    // ── WebSocket ──────────────────────────────────────────────────────────────

    private fun buildWsUrl(apiUrl: String, busId: Int, token: String): String {
        val wsBase = apiUrl
            .replace("https://", "wss://")
            .replace("http://", "ws://")
            .trimEnd('/')
        return "$wsBase/ws/bus/$busId/?token=$token"
    }

    private fun connectWebSocket() {
        val token = authToken ?: return
        val id = busId?.takeIf { it != -1 } ?: return
        val base = apiUrl ?: return

        val url = buildWsUrl(base, id, token)
        Log.d(TAG, "WS connecting → $url")
        val request = Request.Builder().url(url).build()
        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(ws: WebSocket, response: Response) {
                reconnectAttempts = 0
                Log.d(TAG, "WS connected ✓ (bus $id)")
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                Log.w(TAG, "WS failure: ${t.message} | HTTP ${response?.code}")
                webSocket = null
                if (!isStopping) scheduleReconnect()
            }

            override fun onClosed(ws: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WS closed: code=$code reason=$reason")
                webSocket = null
                if (!isStopping) scheduleReconnect()
            }
        })
    }

    private fun scheduleReconnect() {
        reconnectJob?.cancel()
        reconnectJob = serviceScope.launch {
            // Exponential backoff: 2s, 4s, 8s, 16s, 30s (capped)
            val delayMs = minOf(2_000L * (1 shl reconnectAttempts.coerceAtMost(4)), 30_000L)
            reconnectAttempts++
            delay(delayMs)
            if (!isStopping) connectWebSocket()
        }
    }

    private fun disconnectWebSocket() {
        isStopping = true
        reconnectJob?.cancel()
        reconnectJob = null
        webSocket?.close(1000, "Trip ended")
        webSocket = null
    }

    // ── Location ───────────────────────────────────────────────────────────────

    @SuppressLint("MissingPermission")
    private fun startLocationTracking() {
        if (isTracking) return
        isTracking = true

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            5000L // 5 seconds interval
        ).apply {
            setMinUpdateIntervalMillis(3000L)
            setMinUpdateDistanceMeters(10f)
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

        disconnectWebSocket()
        fusedLocationClient.removeLocationUpdates(locationCallback)

        if (wakeLock.isHeld) {
            wakeLock.release()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun handleLocationUpdate(location: Location) {
        locationUpdateCount++
        serviceScope.launch {
            try {
                sendLocation(location)
                updateNotification(location)
            } catch (e: Exception) {
                // Silently handle errors — service continues running
            }
        }
    }

    /**
     * Sends the location via WebSocket (primary path).
     * Falls back to HTTP POST if the WebSocket is not connected.
     */
    private suspend fun sendLocation(location: Location) {
        val json = JSONObject().apply {
            put("type", "location_update")
            put("latitude", location.latitude)
            put("longitude", location.longitude)
            put("speed", location.speed * 3.6)        // m/s → km/h
            put("heading", location.bearing.toDouble())
            put("timestamp", Instant.now().toString())
        }

        // WebSocket.send() is thread-safe and non-blocking; returns false if closed
        val sent = webSocket?.send(json.toString()) == true
        if (!sent) {
            sendLocationViaHttp(location)
        }
    }

    /** HTTP fallback — used when WebSocket is disconnected or reconnecting. */
    private suspend fun sendLocationViaHttp(location: Location) = withContext(Dispatchers.IO) {
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
                put("speed", location.speed * 3.6) // m/s → km/h
                put("heading", location.bearing.toDouble())
                put("accuracy", location.accuracy.toDouble())
            }

            connection.outputStream.use { os ->
                os.write(jsonData.toString().toByteArray())
            }

            connection.responseCode
            connection.disconnect()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ── Notifications ──────────────────────────────────────────────────────────

    private fun createNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val busLabel = if (busId != null && busId != -1) "Bus #$busId" else "Bus"

        return NotificationCompat.Builder(this, TRIP_CHANNEL_ID)
            .setContentTitle("ApoBasi — Active School Route")
            .setContentText("$busLabel • Children on board • Location active")
            .setSubText("Tap to open the app")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(openAppPendingIntent)
            .build()
    }

    private fun updateNotification(location: Location) {
        val speedKmh = location.speed * 3.6
        val busLabel = if (busId != null && busId != -1) "Bus #$busId" else "Bus"
        val contentText = "$busLabel — ${"%.1f".format(speedKmh)} km/h • $locationUpdateCount GPS updates"

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, TRIP_CHANNEL_ID)
            .setContentTitle("ApoBasi — Active School Route")
            .setContentText(contentText)
            .setSubText("Children on board • End trip in-app to stop")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppPendingIntent)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()

        if (isTracking) {
            stopLocationTracking()
        } else {
            // Ensure WebSocket is closed even if tracking already stopped
            disconnectWebSocket()
        }

        serviceScope.cancel()

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.cancel(NOTIFICATION_ID)
    }
}
