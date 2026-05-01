package com.solvo.medsync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
import io.flutter.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val rescheduleIntent = Intent(context, ScheduledNotificationBootReceiver::class.java).apply {
                action = intent.action
            }
            context.sendBroadcast(rescheduleIntent)
            Log.i("MedSync", "Boot receiver triggered: ${intent.action}")
        }
    }
}
