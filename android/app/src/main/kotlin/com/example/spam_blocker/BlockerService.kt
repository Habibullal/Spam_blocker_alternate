package com.example.spam_blocker

import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.Call.Details
import io.flutter.Log

class BlockerService : CallScreeningService() {
  override fun onCreate() {
    super.onCreate()
    Log.d("BlockerService", "Service created – ready to screen calls")
  }
  override fun onScreenCall(callDetails: Details) {
    Log.d("debug", "Hello there, from kotlin")
    val prefs = applicationContext.getSharedPreferences("call_blocker_prefs", MODE_PRIVATE)
    val isIncoming = callDetails.callDirection == Call.Details.DIRECTION_INCOMING

    if(isIncoming){
      val incoming = callDetails.handle.schemeSpecificPart
      Log.d("in", "call coming in")
      val builder = CallResponse.Builder()
      FlutterBridge.checkNumber(incoming) { isValid ->
        Log.d("e", isValid.toString())
        if (isValid) {
          Log.d("blocker", "hello")
          builder.setDisallowCall(true).setRejectCall(true).setSkipCallLog(true)
            .setSkipNotification(true)
        } else {
          builder.setDisallowCall(false)
        }
        respondToCall(callDetails, builder.build())
      }
    }
  }
}