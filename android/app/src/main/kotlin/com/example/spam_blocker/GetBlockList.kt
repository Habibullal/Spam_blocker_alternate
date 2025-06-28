package com.example.spam_blocker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.core.content.edit
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.MemoryCacheSettings

class GetBlockList: BroadcastReceiver(){

    private lateinit var  firestore: FirebaseFirestore
    private lateinit var prefs: SharedPreferences

    override fun onReceive(context: Context?, intent: Intent?) {

        if (intent != null) {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {

                Log.d("BootReceiver", "Device booted — running firestore code")
                initializeFirebase(context)
            }
        }
    }

    fun initializeFirebase(context: Context?){

        if(::firestore.isInitialized){
            return
        }

        FirebaseApp.initializeApp(context!!)
        prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        firestore = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setLocalCacheSettings(
                MemoryCacheSettings
                    .newBuilder()
                    .build()
            )
            .build()
        firestore.firestoreSettings = settings

        firestore.collection("BlockedNumbers").document("numbers")
            .addSnapshotListener { snapshot: DocumentSnapshot?, error: Exception? ->
                if (error != null) {
                    io.flutter.Log.e("SnapShot_Listener", "Snapshot listener error", error)
                    return@addSnapshotListener
                }
                if (snapshot != null && snapshot.exists()) {
                    fetchNumbers()
                    io.flutter.Log.d("SnapShot_Listener", "number updated")
                }
            }
        firestore.collection("BlockedNumbers").document("country_codes")
            .addSnapshotListener { snapshot: DocumentSnapshot?, error: Exception? ->
                if (error != null) {
                    io.flutter.Log.e("SnapShot_Listener", "Snapshot listener error", error)
                    return@addSnapshotListener
                }
                if (snapshot != null && snapshot.exists()) {
                    fetchCodes()
                    io.flutter.Log.d("SnapShot_Listener", "codes updated")
                }
            }

    }
    private fun fetchNumbers(){
        io.flutter.Log.d("FetchNumbers", "Change database")
        firestore.collection("BlockedNumbers").document("numbers").get()
            .addOnSuccessListener {document -> document.data?.keys?.let { keys ->
                prefs.edit { putStringSet("blockedNumbersSet", keys) }
            }}
            .addOnFailureListener{error -> io.flutter.Log.d("Data_update", "Failed to get Number:", error)}
    }

    private fun fetchCodes(){
        io.flutter.Log.d("FetchNumbers", "Change database")
        firestore.collection("BlockedNumbers").document("country_codes").get()
            .addOnSuccessListener {document -> document.data?.keys?.let { keys ->
                prefs.edit { putStringSet("blockedCodesSet", keys) }
            }}
            .addOnFailureListener{error -> io.flutter.Log.d("Data_update", "Failed to get codes:", error)}
    }
}