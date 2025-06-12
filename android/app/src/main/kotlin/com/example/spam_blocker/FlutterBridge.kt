package com.example.spam_blocker

import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object FlutterBridge {
    private const val CHANNEL = "com.example.spam_blocker/channel"
    private lateinit var methodChannel: MethodChannel

    fun init(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, CHANNEL)
    }

    fun checkNumber(num: String, onResult: (Boolean)->Unit){
        val args = mapOf("text" to num)
        Log.d("MainActivity", "CheckingNumber")
        methodChannel.invokeMethod("checkNumber",args, object: MethodChannel.Result{
            override fun success(result: Any?) {
                val isValid = result as? Boolean?: false
                Log.d("MainActivity_success", isValid.toString())
                onResult(isValid)
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.d("MainActivity", "Error from Flutter: $errorCode $errorMessage")
                onResult(false)
            }
            override fun notImplemented() {
                Log.w("MainActivity", "Method not implemented in Flutter")
                onResult(false)
            }
        })
    }
}