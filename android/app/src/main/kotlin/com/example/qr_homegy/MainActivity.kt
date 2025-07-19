package com.example.qr_homegy

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qr_homegy.share_channel").setMethodCallHandler { call, result ->
            when (call.method) {
                "shareImage" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        shareImage(filePath)
                        result.success(null)
                    } else {
                        result.error("INVALID_PATH", "File path is null", null)
                    }
                }
                "shareImages" -> {
                    val filePaths = call.argument<List<String>>("filePaths")
                    if (filePaths != null) {
                        shareImages(filePaths)
                        result.success(null)
                    } else {
                        result.error("INVALID_PATHS", "File paths are null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareImage(filePath: String) {
        val file = File(filePath)
        val uri: Uri = FileProvider.getUriForFile(
            this,
            applicationContext.packageName + ".fileprovider",
            file
        )
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "image/png"
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(Intent.createChooser(intent, "Chia sẻ ảnh QR"))
    }

    private fun shareImages(filePaths: List<String>) {
        val uris = ArrayList<Uri>()
        for (path in filePaths) {
            val file = File(path)
            val uri = FileProvider.getUriForFile(
                this,
                applicationContext.packageName + ".fileprovider",
                file
            )
            uris.add(uri)
        }
        val intent = Intent(Intent.ACTION_SEND_MULTIPLE)
        intent.type = "image/png"
        intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(Intent.createChooser(intent, "Chia sẻ các ảnh QR"))
    }
}
