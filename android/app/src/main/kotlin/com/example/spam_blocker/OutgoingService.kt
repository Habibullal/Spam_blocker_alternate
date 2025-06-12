package com.example.spam_blocker

import android.net.Uri
import android.telecom.CallRedirectionService
import android.telecom.PhoneAccountHandle
import io.flutter.Log

class OutgoingService : CallRedirectionService() {
    override fun onPlaceCall(
        handle: Uri,
        initialPhoneAccount: PhoneAccountHandle,
        allowInteractiveResponse: Boolean
    ) {
        val number = handle.schemeSpecificPart
        FlutterBridge.checkNumber(number) { isValid ->
            Log.d("e", isValid.toString())
            if (isValid) {
                Log.d("outgoing", "Call blocked")
                cancelCall()
            } else {
                Log.d("Outgoing", "Call not blocked")
                placeCallUnmodified()
            }

        }
    }
}