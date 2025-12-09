package com.example.cheez_admin_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.content.ContentValues
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.ByteArrayInputStream

class MainActivity : FlutterActivity() {
    private val WHATSAPP_CHANNEL = "com.example.cheez_admin_app/whatsapp"
    private val GALLERY_CHANNEL = "com.example.cheez_admin_app/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // WhatsApp channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val phoneNumber = call.argument<String>("phone")
                val imagePath = call.argument<String>("imagePath")
                
                if (phoneNumber != null && imagePath != null) {
                    shareImageToWhatsApp(phoneNumber, imagePath)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number or image path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        // Gallery channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GALLERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath != null) {
                        scanFileToGallery(filePath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                "saveImageToGallery" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val fileName = call.argument<String>("fileName") ?: "Receipt_${System.currentTimeMillis()}.png"
                    if (imageBytes != null) {
                        val saved = saveImageToGallery(imageBytes, fileName)
                        result.success(saved)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image bytes is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareImageToWhatsApp(phoneNumber: String, imagePath: String) {
        try {
            val file = File(imagePath)
            if (!file.exists()) {
                // Fallback: Open WhatsApp with phone number only
                openWhatsAppWithPhone(phoneNumber)
                return
            }

            // Use FileProvider for secure file sharing
            val imageUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            // Create intent to share image to WhatsApp
            // Note: WhatsApp doesn't support attaching image to specific chat programmatically
            // So we'll share the image and let user select the contact
            val shareIntent = Intent(Intent.ACTION_SEND)
            shareIntent.type = "image/png"
            shareIntent.setPackage("com.whatsapp")
            shareIntent.putExtra(Intent.EXTRA_STREAM, imageUri)
            shareIntent.putExtra(Intent.EXTRA_TEXT, "Receipt for your order")
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // Start the share intent (opens WhatsApp with image ready to share)
            startActivity(shareIntent)
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback: Open WhatsApp with phone number
            openWhatsAppWithPhone(phoneNumber)
        }
    }

    private fun openWhatsAppWithPhone(phoneNumber: String) {
        try {
            val uri = Uri.parse("https://wa.me/$phoneNumber")
            val intent = Intent(Intent.ACTION_VIEW, uri)
            intent.setPackage("com.whatsapp")
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun saveImageToGallery(imageBytes: ByteArray, fileName: String): Boolean {
        return try {
            // Use MediaStore to save image to gallery (Android 10+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CheezReceipts")
                }
                
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri != null) {
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        ByteArrayInputStream(imageBytes).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }
                    true
                } else {
                    false
                }
            } else {
                // For older Android versions, save to Pictures directory and scan
                val picturesDir = File(android.os.Environment.getExternalStoragePublicDirectory(
                    android.os.Environment.DIRECTORY_PICTURES), "CheezReceipts")
                if (!picturesDir.exists()) {
                    picturesDir.mkdirs()
                }
                
                val file = File(picturesDir, fileName)
                FileOutputStream(file).use { it.write(imageBytes) }
                
                // Scan file
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = Uri.fromFile(file)
                sendBroadcast(mediaScanIntent)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    private fun scanFileToGallery(filePath: String) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                return
            }
            
            // Use MediaStore to add image to gallery (Android 10+)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/CheezReceipts")
                }
                
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri != null) {
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        FileInputStream(file).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }
                }
            } else {
                // For older Android versions, use media scanner
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                val contentUri = Uri.fromFile(file)
                mediaScanIntent.data = contentUri
                sendBroadcast(mediaScanIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
