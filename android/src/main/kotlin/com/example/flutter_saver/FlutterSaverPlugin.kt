package com.example.flutter_saver

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

/** FlutterSaverPlugin */
class FlutterSaverPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    // Pending save request waiting for permission result
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingDirectory: String? = null
    private var pendingResult: Result? = null

    companion object {
        private const val REQUEST_WRITE_STORAGE = 100
    }

    // ─────────────────────────────────────────────────────────────
    // FlutterPlugin
    // ─────────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flutter_saver")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        ioExecutor.shutdown()
    }

    // ─────────────────────────────────────────────────────────────
    // ActivityAware
    // ─────────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activity = null
        activityBinding = null
    }

    // ─────────────────────────────────────────────────────────────
    // MethodCallHandler
    // ─────────────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "getDirectoryPath" -> {
                val directory = call.argument<String>("directory") ?: "DOWNLOADS"
                val path = getDirectoryPath(directory)
                if (path != null) result.success(path)
                else result.error("DIR_NOT_FOUND", "Could not resolve directory: $directory", null)
            }

            "saveFile" -> {
                val rawBytes = call.argument<Any>("bytes")
                val bytes: ByteArray? = when (rawBytes) {
                    is ByteArray -> rawBytes
                    is List<*>   -> ByteArray(rawBytes.size) { i -> (rawBytes[i] as Number).toByte() }
                    else         -> null
                }
                val fileName  = call.argument<String>("fileName")
                val directory = call.argument<String>("directory") ?: "DOWNLOADS"

                if (bytes == null) {
                    result.error("INVALID_ARGS", "bytes must not be null", null)
                    return
                }
                if (fileName.isNullOrBlank()) {
                    result.error("INVALID_ARGS", "fileName must not be null or blank", null)
                    return
                }

                // On Android 10+ MediaStore needs no runtime permission — save directly.
                // On Android 9 and below WRITE_EXTERNAL_STORAGE is required at runtime.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                    !hasWritePermission()
                ) {
                    // Store the request and ask for permission; result delivered via callback
                    pendingBytes     = bytes
                    pendingFileName  = fileName
                    pendingDirectory = directory
                    pendingResult    = result
                    requestWritePermission()
                } else {
                    executeSave(bytes, fileName, directory, result)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Permission handling (legacy Android ≤ 9)
    // ─────────────────────────────────────────────────────────────

    private fun hasWritePermission(): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED

    private fun requestWritePermission() {
        val act = activity ?: run {
            pendingResult?.error(
                "PERMISSION_ERROR",
                "Cannot request permission: no Activity attached",
                null
            )
            clearPending()
            return
        }
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            REQUEST_WRITE_STORAGE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != REQUEST_WRITE_STORAGE) return false

        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

        val bytes     = pendingBytes
        val fileName  = pendingFileName
        val directory = pendingDirectory
        val result    = pendingResult
        clearPending()

        if (result == null) return true

        if (!granted) {
            result.error(
                "PERMISSION_DENIED",
                "WRITE_EXTERNAL_STORAGE permission was denied by the user",
                null
            )
            return true
        }

        if (bytes == null || fileName == null || directory == null) {
            result.error("INVALID_ARGS", "Pending save data is missing", null)
            return true
        }

        executeSave(bytes, fileName, directory, result)
        return true
    }

    private fun clearPending() {
        pendingBytes     = null
        pendingFileName  = null
        pendingDirectory = null
        pendingResult    = null
    }

    // ─────────────────────────────────────────────────────────────
    // Save dispatcher
    // ─────────────────────────────────────────────────────────────

    private fun executeSave(
        bytes: ByteArray,
        fileName: String,
        directory: String,
        result: Result
    ) {
        ioExecutor.execute {
            try {
                val savedPath = saveFile(bytes, fileName, directory)
                mainHandler.post { result.success(savedPath) }
            } catch (e: Exception) {
                mainHandler.post { result.error("SAVE_FAILED", e.message, null) }
            }
        }
    }

    private fun getDirectoryPath(directory: String): String? {
        val envDir = mapToEnvironmentDirectory(directory)
        return Environment.getExternalStoragePublicDirectory(envDir)?.absolutePath
    }

    private fun saveFile(bytes: ByteArray, fileName: String, directory: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveFileViaMediaStore(bytes, fileName, directory)
        } else {
            saveFileLegacy(bytes, fileName, directory)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Android Q+ : MediaStore (no permission needed)
    // ─────────────────────────────────────────────────────────────

    private fun saveFileViaMediaStore(
        bytes: ByteArray,
        fileName: String,
        directory: String
    ): String {
        val envDir      = mapToEnvironmentDirectory(directory)
        val relativeDir = environmentDirectoryToRelative(envDir)
        val mimeType    = guessMimeType(fileName)
        val collection  = resolveMediaStoreCollection(envDir)
        val resolver    = context.contentResolver

        val uniqueName = resolveUniqueMediaStoreName(collection, relativeDir, fileName)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, uniqueName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values)
            ?: throw IOException("MediaStore insert returned null for \"$uniqueName\"")

        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IOException("Could not open output stream for $uri")

            val update = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, update, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }

        // Try real path first; fall back to URI string (safe on all API levels)
        resolver.query(
            uri,
            arrayOf(MediaStore.MediaColumns.DATA),
            null, null, null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idx = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                if (idx != -1) {
                    val path = cursor.getString(idx)
                    if (!path.isNullOrEmpty()) return path
                }
            }
        }

        return uri.toString()
    }

    private fun resolveUniqueMediaStoreName(
        collection: android.net.Uri,
        relativeDir: String,
        fileName: String
    ): String {
        val resolver = context.contentResolver
        val name = fileName.substringBeforeLast('.')
        val ext  = fileName.substringAfterLast('.', "")
            .let { if (it.isNotEmpty()) ".$it" else "" }

        var candidate = fileName
        var counter   = 1
        while (true) {
            val cursor = resolver.query(
                collection,
                arrayOf(MediaStore.MediaColumns.DISPLAY_NAME),
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND " +
                        "${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
                arrayOf(candidate, relativeDir),
                null
            )
            val exists = (cursor?.count ?: 0) > 0
            cursor?.close()
            if (!exists) return candidate
            candidate = "${name}_($counter)$ext"
            counter++
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Android ≤ 9 : direct filesystem write (permission already granted)
    // ─────────────────────────────────────────────────────────────

    private fun saveFileLegacy(
        bytes: ByteArray,
        fileName: String,
        directory: String
    ): String {
        val envDir = mapToEnvironmentDirectory(directory)
        val dir    = Environment.getExternalStoragePublicDirectory(envDir)

        if (!dir.exists() && !dir.mkdirs()) {
            throw IOException("Could not create directory: ${dir.absolutePath}")
        }

        val file = resolveUniqueFile(dir, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }

    // ─────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────

    private fun mapToEnvironmentDirectory(key: String): String = when (key.uppercase()) {
        "DOWNLOADS"     -> Environment.DIRECTORY_DOWNLOADS
        "PICTURES"      -> Environment.DIRECTORY_PICTURES
        "MOVIES"        -> Environment.DIRECTORY_MOVIES
        "DCIM"          -> Environment.DIRECTORY_DCIM
        "DOCUMENTS"     -> Environment.DIRECTORY_DOCUMENTS
        "MUSIC"         -> Environment.DIRECTORY_MUSIC
        "RINGTONES"     -> Environment.DIRECTORY_RINGTONES
        "ALARMS"        -> Environment.DIRECTORY_ALARMS
        "NOTIFICATIONS" -> Environment.DIRECTORY_NOTIFICATIONS
        "PODCASTS"      -> Environment.DIRECTORY_PODCASTS
        else            -> Environment.DIRECTORY_DOWNLOADS
    }

    private fun environmentDirectoryToRelative(envDir: String): String = when (envDir) {
        Environment.DIRECTORY_DOWNLOADS     -> "Download/"
        Environment.DIRECTORY_PICTURES      -> "Pictures/"
        Environment.DIRECTORY_MOVIES        -> "Movies/"
        Environment.DIRECTORY_DCIM          -> "DCIM/"
        Environment.DIRECTORY_DOCUMENTS     -> "Documents/"
        Environment.DIRECTORY_MUSIC         -> "Music/"
        Environment.DIRECTORY_RINGTONES     -> "Ringtones/"
        Environment.DIRECTORY_ALARMS        -> "Alarms/"
        Environment.DIRECTORY_NOTIFICATIONS -> "Notifications/"
        Environment.DIRECTORY_PODCASTS      -> "Podcasts/"
        else                                -> "Download/"
    }

    private fun resolveMediaStoreCollection(envDir: String) = when (envDir) {
        Environment.DIRECTORY_PICTURES,
        Environment.DIRECTORY_DCIM ->
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        Environment.DIRECTORY_MOVIES ->
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI

        Environment.DIRECTORY_MUSIC,
        Environment.DIRECTORY_RINGTONES,
        Environment.DIRECTORY_ALARMS,
        Environment.DIRECTORY_NOTIFICATIONS,
        Environment.DIRECTORY_PODCASTS ->
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        else -> MediaStore.Downloads.EXTERNAL_CONTENT_URI
    }

    private fun guessMimeType(fileName: String): String =
        when (fileName.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png"         -> "image/png"
            "gif"         -> "image/gif"
            "webp"        -> "image/webp"
            "bmp"         -> "image/bmp"
            "heic"        -> "image/heic"
            "mp4"         -> "video/mp4"
            "mov"         -> "video/quicktime"
            "avi"         -> "video/x-msvideo"
            "mkv"         -> "video/x-matroska"
            "mp3"         -> "audio/mpeg"
            "aac"         -> "audio/aac"
            "wav"         -> "audio/wav"
            "ogg"         -> "audio/ogg"
            "flac"        -> "audio/flac"
            "pdf"         -> "application/pdf"
            "txt"         -> "text/plain"
            "json"        -> "application/json"
            "xml"         -> "text/xml"
            "zip"         -> "application/zip"
            else          -> "application/octet-stream"
        }

    private fun resolveUniqueFile(dir: File, fileName: String): File {
        val name = fileName.substringBeforeLast('.')
        val ext  = fileName.substringAfterLast('.', "")
            .let { if (it.isNotEmpty()) ".$it" else "" }

        var file    = File(dir, fileName)
        var counter = 1
        while (file.exists()) {
            file = File(dir, "${name}_($counter)$ext")
            counter++
        }
        return file
    }
}
