package com.example.spam_blocker

import android.app.role.RoleManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.example.spam_blocker/channel"
  private lateinit var methodChannel: MethodChannel

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    methodChannel.setMethodCallHandler { call, result ->
      when (call.method) {
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
        else -> result.notImplemented()
      }
    }
  }
}
