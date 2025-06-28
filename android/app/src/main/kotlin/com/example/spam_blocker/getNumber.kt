package com.example.spam_blocker

import android.util.Log
import android.content.Context
import android.content.SharedPreferences

object getNumber {
    fun checkNumber(context: Context, num: String, onResult: (Boolean)->Unit){
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAllowed = prefs.getBoolean("flutter.isLoggedIn", false)
        if(isAllowed) {
            val numSet = prefs.getStringSet("blockedNumbersSet", emptySet()) ?: emptySet()
            val codeSet = prefs.getStringSet("blockedCodesSet", emptySet()) ?: emptySet()

            Log.d("getNumber", "$numSet")
            Log.d("getNumber", "$codeSet")

            val isBlocked = numSet.contains(num) || codeSet.any{ code -> num.startsWith(code)}

            Log.d("getNumber", "checkNumber: is $num blocked? $isBlocked")
            onResult(isBlocked)
        }
        else{
            onResult(false)
        }
    }
}