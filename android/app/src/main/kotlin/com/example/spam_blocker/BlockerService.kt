package com.example.spam_blocker

import android.content.Context
import android.content.SharedPreferences
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.Call.Details
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.MemoryCacheSettings
import io.flutter.Log
import androidx.core.content.edit

class BlockerService : CallScreeningService() {

  private lateinit var  firestore: FirebaseFirestore
  private lateinit var prefs: SharedPreferences

  override fun onCreate() {
    super.onCreate()

    FirebaseApp.initializeApp(this)
    prefs = this.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    firestore = FirebaseFirestore.getInstance()
    val settings = FirebaseFirestoreSettings.Builder()
      .setLocalCacheSettings(
        MemoryCacheSettings
          .newBuilder()
          .build()
      )
      .build()
    firestore.firestoreSettings = settings

    firestore.collection("BlockedNumbers")
      .document("numbers")
      .addSnapshotListener { snapshot: DocumentSnapshot?, error: Exception? ->
        if (error != null) {
          Log.e("SnapShot_Listener", "Snapshot listener error", error)
          return@addSnapshotListener
        }
        if (snapshot != null && snapshot.exists()) {
          fetchNumbers()
          Log.d("SnapShot_Listener", "boo")
        }
      }

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
      getNumber.checkNumber(this,incoming) { isValid ->
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

  private fun fetchNumbers(){
    Log.d("FetchNumbers", "Change database")
    firestore.collection("BlockedNumbers").document("numbers").get()
      .addOnSuccessListener {document -> document.data?.keys?.let { keys ->
        prefs.edit { putStringSet("blockedNumbersSet", keys) }
        prefs.edit { putString("flutter.blockedNumbers", keys.joinToString("|")) }
      }}
      .addOnFailureListener{error -> Log.d("Data_update", "Failed to get Number:", error)}
  }
}