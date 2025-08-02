package com.example.spam_blocker

import android.app.role.RoleManager
import android.content.Context
import android.content.pm.PackageManager
import android.Manifest
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.firebase.messaging.FirebaseMessaging
import android.telephony.TelephonyManager
import android.telephony.SubscriptionManager
import androidx.annotation.RequiresPermission


class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.example.spam_blocker/channel"
  private lateinit var methodChannel: MethodChannel

  private val CALL_LOG_PERMISSION_REQUEST_CODE = 1001
  private val CONTACT_PERMISSION_REQUEST_CODE = 1002
  private val SIM_PERMISSION_REQUEST_CODE = 2001

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    FirebaseMessaging.getInstance().subscribeToTopic("blockedUpdates")
      .addOnCompleteListener { task ->
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
          GetBlockList().fetchNumbers(this)
          result.success(true)
        }

        "CheckBlocked" ->{
          val num = call.argument<String>("number") ?: ""
          Log.d("check", num)
          val prefs = context
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
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
            ActivityCompat.requestPermissions(
              this,
              arrayOf(Manifest.permission.READ_CALL_LOG),
              CALL_LOG_PERMISSION_REQUEST_CODE
            )
            result.success(false)
          } else {
            result.success(true)
          }
        }

        "requestContactPermission" -> {
          val permsNeeded = mutableListOf<String>()
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            permsNeeded += Manifest.permission.READ_CONTACTS
          }
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            permsNeeded += Manifest.permission.WRITE_CONTACTS
          }

          if (permsNeeded.isEmpty()) {
            result.success(true)
          } else {
            ActivityCompat.requestPermissions(this, permsNeeded.toTypedArray(), CONTACT_PERMISSION_REQUEST_CODE)
            result.success(false)
          }
        }

        "requestSimPermission" -> {
          val permsNeeded = mutableListOf<String>()
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            permsNeeded += Manifest.permission.READ_PHONE_STATE
          }
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) != PackageManager.PERMISSION_GRANTED) {
            permsNeeded += Manifest.permission.READ_PHONE_NUMBERS
          }
          Log.d("SIm", permsNeeded.toString())
          if (permsNeeded.isEmpty()) {
            result.success(true)
          } else {
            ActivityCompat.requestPermissions(this, permsNeeded.toTypedArray(), SIM_PERMISSION_REQUEST_CODE)
            result.success(false)
          }
        }

        "getSimInfo" -> {
          Log.d("Sim info", "Started")
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED) {
            Log.d("Sim", "granted1")
            result.success(fetchAllSimInfo())
          } else {
            Log.d("Sim", "not granted1")
            result.error(
              "PERMISSION_DENIED",
              "SIM permissions not granted",
              null
            )
          }
        }

        "getCallLogs" -> {
          GetBlockList().fetchNumbers(context)
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

  // Handle both CALL_LOG and CONTACT permission results
  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)

    when (requestCode) {
      CALL_LOG_PERMISSION_REQUEST_CODE -> {
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        methodChannel.invokeMethod("callLogPermissionGranted", granted)
      }
      SIM_PERMISSION_REQUEST_CODE -> {
        val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        methodChannel.invokeMethod("simPermissionGranted", allGranted)
      }
      CONTACT_PERMISSION_REQUEST_CODE -> {
        val denied = grantResults.any { it != PackageManager.PERMISSION_GRANTED }
        Log.d("Sim", "Granted now2")
        methodChannel.invokeMethod("contactPermissionGranted", !denied)
      }
    }
  }

  @RequiresPermission(Manifest.permission.READ_PHONE_STATE)
  private fun fetchAllSimInfo(): List<Map<String, Any>> {
    val subMgr = getSystemService(SubscriptionManager::class.java)
      ?: return emptyList()

    val subs = subMgr.activeSubscriptionInfoList ?: emptyList()
    Log.d("SIm", subs.toString())
    return subs.mapNotNull { info ->
      val slot    = info.simSlotIndex
      val carrier = info.carrierName?.toString().orEmpty()
      val subId   = info.subscriptionId

      val number: String = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED) {
            subMgr.getPhoneNumber(subId).orEmpty()
          } else {
            ""
          }
        } else {
          if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
            && ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED) {
            val tmForSim = getSystemService(TelephonyManager::class.java)
              ?.createForSubscriptionId(subId)
            tmForSim?.line1Number.orEmpty()
          } else {
            ""
          }
        }
      } catch (secEx: SecurityException) {
        Log.w("SIM_INFO", "Permission denied reading SIM #$slot", secEx)
        ""
      }
      Log.d("sim", number)

      mapOf(
        "slot"    to slot,
        "carrier" to carrier,
        "number"  to number
      )
    }
  }

}

