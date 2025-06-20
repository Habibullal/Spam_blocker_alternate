package com.example.spam_blocker

import android.util.Log
import android.content.Context
import android.content.SharedPreferences

object getNumber {
    fun checkNumber(context: Context, num: String, onResult: (Boolean)->Unit){
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val num_set = prefs.getStringSet("blockedNumbersSet", emptySet()) ?: emptySet()

        Log.d("getNumber", "$num_set")
        val isBlocked = num_set.contains(num)

        Log.d("getNumber", "checkNumber: is $num blocked? $isBlocked")
        onResult(isBlocked)
    }
}