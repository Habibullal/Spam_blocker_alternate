package com.example.spam_blocker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import androidx.core.content.edit
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response

data class FetchResponse(
    val data: List<String>,
    val codes: List<String>,
    val error: Boolean
)

class GetBlockList: BroadcastReceiver(){
    private lateinit var prefs: SharedPreferences
    private val client = OkHttpClient()
    private val JSON = "application/json; charset=utf-8".toMediaType()

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent != null) {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED) {

                Log.d("BootReceiver", "Device booted — running firestore code")
                fetchNumbers(context)
            }
        }
    }

    fun fetchNumbers(context: Context?){
        prefs = context!!.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        io.flutter.Log.d("FetchNumbers", "Change database")
        val token = prefs.getString("flutter.authToken", "") ?: ""
        Log.d("fetchnums", token)
        val jsonBody = """ {"token" : "$token"}"""
        try {
            val req = Request.Builder().url("http://10.251.0.182:3000/api/numbers").post(jsonBody.toRequestBody(JSON)).build()

            client.newCall(req).execute().use { res: Response ->
                Log.d("FetchNums", res.code.toString())
                if(res.code == 200) {
                    val moshi = Moshi.Builder()
                        .add(KotlinJsonAdapterFactory())
                        .build()

                    val adapter = moshi.adapter(FetchResponse::class.java)

                    val parsedData = res.body?.string()?.let { adapter.fromJson(it) }
                    if (parsedData != null) {
                        val dataSet = parsedData.data.toSet()
                        Utils.updateContacts(context, dataSet, prefs)
                        prefs.edit { putStringSet("blockedNumbersSet", dataSet)
                            putStringSet("blockedCodesSet", parsedData.codes.toSet()) }
                    }
                }
                else if (res.code == 403){
                    // Unauthorized Access, wipe app
                    Utils.nukeApp(context)
                }
            }
        } catch (e: Exception) {
            Log.e("fetchNums", "error:",e)
        }
    }
}