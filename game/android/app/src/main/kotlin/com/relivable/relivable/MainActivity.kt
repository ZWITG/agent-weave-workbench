package com.relivable.relivable

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Hosts the "relivable/updater" channel used by lib/updater.dart: downloads
  a newer APK with the system DownloadManager, then opens Android's
  installer (the player confirms the install, as Android requires). */
class MainActivity : FlutterActivity() {
    private val apkMime = "application/vnd.android.package-archive"
    private var receiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "relivable/updater")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "downloadAndInstall" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.success("error")
                        } else {
                            result.success(downloadAndInstall(url, call.argument<String>("version") ?: "update"))
                        }
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        }
                        result.success("opened")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun downloadAndInstall(url: String, version: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
            )
            return "needs_permission"
        }
        val name = "relivable-$version.apk"
        File(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), name).delete()
        val dm = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("Relivable $version")
            .setDescription("Downloading the latest version")
            .setMimeType(apkMime)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(this, Environment.DIRECTORY_DOWNLOADS, name)
        val id = dm.enqueue(request)

        receiver?.let { runCatching { unregisterReceiver(it) } }
        val done = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L) != id) return
                runCatching { unregisterReceiver(this) }
                receiver = null
                val uri = dm.getUriForDownloadedFile(id) ?: return
                val install = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, apkMime)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(install)
            }
        }
        receiver = done
        val filter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(done, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(done, filter)
        }
        return "started"
    }
}
