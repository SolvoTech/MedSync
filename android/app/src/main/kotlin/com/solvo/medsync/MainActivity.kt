package com.solvo.medsync

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val SYSTEM_SETTINGS_CHANNEL = "med_syn/system_settings"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			SYSTEM_SETTINGS_CHANNEL,
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"openNotificationSettings" -> {
					result.success(openNotificationSettings())
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun openNotificationSettings(): Boolean {
		val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
			putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
			putExtra("app_package", packageName)
			putExtra("app_uid", applicationInfo.uid)
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		return try {
			startActivity(intent)
			true
		} catch (_: ActivityNotFoundException) {
			openAppDetailsSettings()
		}
	}

	private fun openAppDetailsSettings(): Boolean {
		val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
			data = Uri.fromParts("package", packageName, null)
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		return try {
			startActivity(intent)
			true
		} catch (_: Exception) {
			false
		}
	}
}
