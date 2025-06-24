package com.example.spam_blocker

import android.content.Context
import android.provider.CallLog
import android.util.Log
import java.util.Date
import java.text.SimpleDateFormat
import java.util.Locale

object CallLogReader {

    fun getCallLogs(context: Context): List<Map<String, Any>> {
        val callLogList = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.CACHED_NAME // Contact name
        )

        val cursor = context.contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            null,
            null,
            CallLog.Calls.DATE + " DESC" // Order by date descending (most recent first)
        )

        cursor?.use {
            val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
            val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
            val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
            val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)

            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

            while (it.moveToNext()) {
                val number = it.getString(numberIndex) ?: "Unknown"
                val type = it.getInt(typeIndex)
                val date = it.getLong(dateIndex)
                val duration = it.getLong(durationIndex)
                val name = it.getString(nameIndex) ?: "Unknown"

                val callType = when (type) {
                    CallLog.Calls.INCOMING_TYPE -> "Incoming"
                    CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                    CallLog.Calls.MISSED_TYPE -> "Missed"
                    CallLog.Calls.BLOCKED_TYPE -> "Blocked"
                    else -> "Unknown"
                }

                // Format the date
                val callDate = Date(date)
                val formattedDate = dateFormat.format(callDate)

                // Add country code if missing and it's a typical mobile number (heuristic)
                // This is a basic heuristic. More robust solutions might involve libphonenumber.
                val formattedNumber = if (!number.startsWith("+") && number.length >= 10) {
                    "+91$number" // Assuming India's +91
                } else {
                    number
                }


                val callMap = mapOf(
                    "number" to formattedNumber,
                    "type" to callType,
                    "date" to formattedDate,
                    "duration" to duration, // in seconds
                    "name" to name
                )
                callLogList.add(callMap)
            }
        } ?: run {
            Log.e("CallLogReader", "Cursor is null, could not read call logs.")
        }
        return callLogList
    }
}