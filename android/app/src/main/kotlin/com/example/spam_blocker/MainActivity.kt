package com.example.spam_blocker

import android.app.role.RoleManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging

class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.example.spam_blocker/channel"
  private lateinit var methodChannel: MethodChannel

  private val CALL_LOG_PERMISSION_REQUEST_CODE = 1001

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    FirebaseMessaging.getInstance().subscribeToTopic("blockedUpdates").addOnCompleteListener { task ->
        Log.d("MyApp", if (task.isSuccessful)
          "Subscribed to blockedUpdates"
        else
          "Subscription failed: ${task.exception}"
        )
      }

    methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    methodChannel.setMethodCallHandler { call, result ->
      when (call.method) {
        "TriggerSnapshot" -> {
          GetBlockList().initializeFirebase(this)
          result.success(true)
        }

        "CheckBlocked" ->{
          val num = call.argument<String>("number")?: ""
          Log.d("check", num)
          val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
          val numSet = prefs.getStringSet("blockedNumbersSet", emptySet()) ?: emptySet()
          result.success(numSet.contains(num))
        }

        "hasScreeningPermission" -> {
          val rm = getSystemService(RoleManager::class.java) as RoleManager
          val hasRole = rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
          Log.d("android", hasRole.toString())
          result.success(hasRole)
        }
        "hasRedirectionPermission" -> {
          val rm = getSystemService(RoleManager::class.java) as RoleManager
          val hasRole = rm.isRoleHeld(RoleManager.ROLE_CALL_REDIRECTION)
          Log.d("android", hasRole.toString())
          result.success(hasRole)
        }
        "requestCallLogPermission" -> {
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG)
              != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                arrayOf(Manifest.permission.READ_CALL_LOG),
                CALL_LOG_PERMISSION_REQUEST_CODE)
            result.success(false) // Permission will be handled in onRequestPermissionsResult
          } else {
            result.success(true)
          }
        }
        "getCallLogs" -> {
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG)
              == PackageManager.PERMISSION_GRANTED) {
            val callLogs = CallLogReader.getCallLogs(this)
            result.success(callLogs)
          } else {
            result.error("PERMISSION_DENIED", "READ_CALL_LOG permission not granted", null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }

  // Handle permission request results
  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == CALL_LOG_PERMISSION_REQUEST_CODE) {
      if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        // Permission granted, you might want to re-trigger the getCallLogs from Flutter
        // Or send a message back to Flutter indicating success
        methodChannel.invokeMethod("callLogPermissionGranted", true)
      } else {
        // Permission denied
        methodChannel.invokeMethod("callLogPermissionGranted", false)
      }
    }
  }
}