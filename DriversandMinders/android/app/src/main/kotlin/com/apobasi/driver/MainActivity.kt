package com.apobasi.driver

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.apobasi.driver/location_service"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationService" -> {
                    try {
                        val token = call.argument<String>("token")
                        val busId = call.argument<Int>("busId")
                        val apiUrl = call.argument<String>("apiUrl")

                        if (token.isNullOrBlank()) {
                            result.error("INVALID_TOKEN", "Auth token is required", null)
                            return@setMethodCallHandler
                        }

                        if (busId == null || busId <= 0) {
                            result.error("INVALID_BUS_ID", "Valid bus ID is required", null)
                            return@setMethodCallHandler
                        }

                        if (apiUrl.isNullOrBlank()) {
                            result.error("INVALID_API_URL", "API URL is required", null)
                            return@setMethodCallHandler
                        }

                        if (!checkLocationPermission()) {
                            result.error("PERMISSION_DENIED", "Location permissions not granted", null)
                            return@setMethodCallHandler
                        }

                        LocationServiceManager.startService(this, token, busId, apiUrl)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_ERROR", e.message, null)
                    }
                }
                "stopLocationService" -> {
                    try {
                        LocationServiceManager.stopService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                "checkLocationPermission" -> {
                    try {
                        val hasPermission = checkLocationPermission()
                        result.success(hasPermission)
                    } catch (e: Exception) {
                        result.error("PERMISSION_CHECK_ERROR", e.message, null)
                    }
                }
                "requestLocationPermission" -> {
                    try {
                        requestLocationPermissions()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PERMISSION_REQUEST_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkLocationPermission(): Boolean {
        // Foreground location is sufficient for a foreground service with
        // foregroundServiceType="location". ACCESS_BACKGROUND_LOCATION is only
        // needed for background (non-visible) location access — not required here.
        return this.hasLocationPermission()
    }

    private fun checkAndRequestPermissions(): Boolean {
        if (checkLocationPermission()) {
            return true
        }
        requestLocationPermissions()
        return false
    }

    private fun requestLocationPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        ActivityCompat.requestPermissions(
            this,
            permissions.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            // Notify Flutter about permission result via method channel if needed
        }
    }
}
