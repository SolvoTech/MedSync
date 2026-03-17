package com.example.med_syn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            // Alarm rescheduling will be wired in the alarm service integration slice.
            Log.i("MedSync", "Boot receiver triggered: ${intent.action}")
        }
    }
}
