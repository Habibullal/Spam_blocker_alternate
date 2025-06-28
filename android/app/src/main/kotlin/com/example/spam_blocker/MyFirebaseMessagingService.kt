package com.example.spam_blocker

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.RemoteMessage
import io.flutter.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(msg: RemoteMessage) {
        Log.d("fcm","triggered")
        msg.data["type"]?.let { type ->
            if (type == "refresh_block_list") {
                GetBlockList().apply {
                    initializeFirebase(applicationContext)
                }
            }
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Re-subscribe on token rotation
        FirebaseMessaging.getInstance().subscribeToTopic("blockedUpdates")
    }
}
