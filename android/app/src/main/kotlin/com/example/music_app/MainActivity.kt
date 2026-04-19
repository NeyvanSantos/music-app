package com.example.music_app

import android.Manifest
import android.app.DownloadManager
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream
import java.net.URLConnection

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CHANNEL = "somax/device_music"
        private const val AUDIO_PERMISSION_REQUEST_CODE = 4102
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestAudioPermission" -> handleRequestAudioPermission(result)
                    "getDeviceSongs" -> handleGetDeviceSongs(result)
                    "enqueueSystemAudioDownload" -> handleEnqueueSystemAudioDownload(call, result)
                    "savePublicAudio" -> handleSavePublicAudio(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleRequestAudioPermission(result: MethodChannel.Result) {
        val permission = getAudioPermission()
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            AUDIO_PERMISSION_REQUEST_CODE
        )
    }

    private fun handleGetDeviceSongs(result: MethodChannel.Result) {
        val permission = getAudioPermission()
        if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        val songs = mutableListOf<Map<String, Any?>>()
        val collection =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.IS_MUSIC
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"

        contentResolver.query(collection, projection, selection, null, sortOrder)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val title = cursor.getString(titleColumn) ?: "Faixa sem nome"
                val artist = cursor.getString(artistColumn) ?: "Artista desconhecido"
                val contentUri = ContentUris.withAppendedId(collection, id)

                songs.add(
                    mapOf(
                        "id" to id.toString(),
                        "title" to title,
                        "artist" to artist,
                        "audioUrl" to contentUri.toString()
                    )
                )
            }
        }

        result.success(songs)
    }

    private fun handleSavePublicAudio(call: MethodCall, result: MethodChannel.Result) {
        val tempFilePath = call.argument<String>("tempFilePath")
        val title = call.argument<String>("title")
            ?.takeIf { it.isNotBlank() }
            ?: "Somax Track"
        val artist = call.argument<String>("artist")
            ?.takeIf { it.isNotBlank() }
            ?: "Somax"
        val originalUrl = call.argument<String>("originalUrl") ?: ""

        if (tempFilePath.isNullOrEmpty()) {
            result.error("invalid_args", "tempFilePath is required", null)
            return
        }

        val tempFile = File(tempFilePath)
        if (!tempFile.exists()) {
            result.error("missing_file", "Temporary audio file not found", null)
            return
        }

        try {
            val extension = inferExtension(originalUrl, tempFile)
            val mimeType = URLConnection.guessContentTypeFromName("track.$extension") ?: "audio/mp4"
            val fileName = "${sanitizeFileName(artist)}_${sanitizeFileName(title)}.$extension"

            val values = ContentValues().apply {
                // Keep the initial insert minimal. Some MediaStore providers are
                // sensitive to optional metadata during record creation.
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/Somax")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }

            val collection =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

            val itemUri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Failed to create MediaStore record.")

            contentResolver.openOutputStream(itemUri)?.use { output ->
                FileInputStream(tempFile).use { input ->
                    input.copyTo(output)
                }
            } ?: throw IllegalStateException("Unable to open output stream.")

            val publishValues = ContentValues().apply {
                put(MediaStore.Audio.Media.TITLE, title)
                put(MediaStore.Audio.Media.ARTIST, artist)
                put(MediaStore.Audio.Media.IS_MUSIC, 1)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }
            }
            contentResolver.update(itemUri, publishValues, null, null)

            tempFile.delete()
            result.success(itemUri.toString())
        } catch (e: Exception) {
            result.error("save_failed", e.message, null)
        }
    }

    private fun handleEnqueueSystemAudioDownload(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")
            ?.takeIf { it.isNotBlank() }
        val title = call.argument<String>("title")
            ?.takeIf { it.isNotBlank() }
            ?: "Somax Track"
        val artist = call.argument<String>("artist")
            ?.takeIf { it.isNotBlank() }
            ?: "Somax"

        if (url == null) {
            result.error("invalid_args", "url is required", null)
            return
        }

        try {
            val extension = inferExtension(url, null)
            val mimeType = URLConnection.guessContentTypeFromName("track.$extension") ?: "audio/mp4"
            val fileName = "${sanitizeFileName(artist)}_${sanitizeFileName(title)}.$extension"
            val request = DownloadManager.Request(Uri.parse(url)).apply {
                setTitle(title)
                setDescription("Baixando música para Somax")
                setMimeType(mimeType)
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                setAllowedOverMetered(true)
                setAllowedOverRoaming(true)
                setVisibleInDownloadsUi(true)
                setDestinationInExternalPublicDir(
                    Environment.DIRECTORY_MUSIC,
                    "Somax/$fileName"
                )
            }

            val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val downloadId = downloadManager.enqueue(request)
            result.success(
                mapOf(
                    "downloadId" to downloadId.toString(),
                    "fileName" to fileName
                )
            )
        } catch (e: Exception) {
            result.error("enqueue_failed", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == AUDIO_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun getAudioPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun sanitizeFileName(value: String): String {
        return value.trim()
            .replace(Regex("[<>:\"/\\\\|?*]"), "")
            .replace(Regex("\\s+"), "_")
            .ifBlank { "somax_track" }
    }

    private fun inferExtension(url: String, file: File?): String {
        val path = file?.name?.lowercase()
            ?: Uri.parse(url).path?.lowercase()
            ?: ""
        return when {
            path.endsWith(".mp3") -> "mp3"
            path.endsWith(".m4a") -> "m4a"
            path.endsWith(".aac") -> "aac"
            path.endsWith(".webm") -> "webm"
            path.endsWith(".wav") -> "wav"
            else -> "mp4"
        }
    }
}
