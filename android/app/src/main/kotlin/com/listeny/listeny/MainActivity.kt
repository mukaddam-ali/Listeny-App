package com.listeny.listeny

import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

// AudioServiceActivity (from the audio_service plugin) instead of plain
// FlutterActivity — it correctly forwards hardware media-button events
// (headset/Bluetooth) to the background audio service.
class MainActivity : AudioServiceActivity() {
    private val mediaStoreChannel = "listeny/media_store"

    // MediaStore queries (contentResolver.query AND the full cursor walk) run
    // here, never on the Android main thread; results are posted back to the
    // main thread for the MethodChannel reply. Single thread: scans are
    // serialized, and one wedged query can't fan out into many.
    private val queryExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaStoreChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "queryAudioFiles" -> runQuery(result) { queryAudioFiles() }
                    // Library sync, step 1: the concrete storage volumes to
                    // scan. Each is paged independently (an _ID is only unique
                    // within one volume).
                    "mp3Volumes" -> runQuery(result) { mp3Volumes() }
                    // Library sync, step 2: one keyset page of MP3 rows from ONE
                    // volume, with explicit continuation (see queryMp3Page).
                    "queryMp3Files" -> {
                        val volume = call.argument<String>("volume") ?: "external"
                        val afterId = (call.argument<Number>("afterId") ?: 0L).toLong()
                        val limit = (call.argument<Number>("limit") ?: 500).toInt()
                            .coerceIn(1, 2000)
                        runQuery(result) { queryMp3Page(volume, afterId, limit) }
                    }
                    "deleteMediaFiles" -> deleteMediaFiles(
                        call.argument<List<Map<String, Any?>>>("items") ?: emptyList(),
                        result
                    )
                    // Copies a finished download into the public Music/Listeny
                    // folder; the library then references it in place (no second copy).
                    "saveToMusic" -> {
                        val path = call.argument<String>("path") ?: ""
                        val name = call.argument<String>("name") ?: ""
                        runQuery(result) { saveToMusic(path, name) ?: emptyMap<String, Any?>() }
                    }
                    "discardSaved" -> {
                        val volume = call.argument<String>("volume") ?: ""
                        val id = (call.argument<Number>("id") ?: -1L).toLong()
                        runQuery(result) { discardSaved(volume, id) }
                    }
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    else -> result.notImplemented()
                }
            }
    }

    private val deleteRequestCode = 7311

    private class DeleteBatch(
        val result: MethodChannel.Result,
        val outcomes: MutableList<Boolean>,
        val indices: List<Int>,
        val uris: List<Uri>,
        val bulkRequest: Boolean,
    ) {
        var next = 0
        var retried = false
    }

    private var pendingDelete: DeleteBatch? = null

    // Deletes the user's ORIGINAL audio files (library-sync references). Each
    // item carries the synced MediaStore identity (volume, id, path, size); a
    // row is only deleted when that identity still matches exactly, so a
    // different file that later took over the old path is never touched.
    // Android 11+: ONE system confirmation (createDeleteRequest) for the whole
    // batch. Android 10: per-file RecoverableSecurityException prompt, then
    // retry. Older: direct delete. Replies a list of booleans (true = gone).
    private fun deleteMediaFiles(
        items: List<Map<String, Any?>>,
        result: MethodChannel.Result
    ) {
        if (pendingDelete != null) {
            result.success(items.map { false })
            return
        }
        val outcomes = MutableList(items.size) { false }
        val indices = mutableListOf<Int>()
        val uris = mutableListOf<Uri>()
        try {
            items.forEachIndexed { i, item ->
                val path = item["path"] as? String ?: ""
                val volume = item["volume"] as? String ?: ""
                val id = (item["id"] as? Number)?.toLong() ?: -1L
                val size = (item["size"] as? Number)?.toLong() ?: 0L
                if (path.isEmpty() || volume.isEmpty() || id < 0) return@forEachIndexed
                val uri = ContentUris.withAppendedId(collectionFor(volume), id)
                var found = false
                var matches = false
                contentResolver.query(
                    uri,
                    arrayOf(MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.SIZE),
                    null, null, null
                )?.use { c ->
                    if (c.moveToFirst()) {
                        found = true
                        matches = c.getString(0) == path &&
                            (size <= 0L || c.getLong(1) == size)
                    }
                }
                if (found && matches) {
                    indices.add(i)
                    uris.add(uri)
                } else if (!found && !java.io.File(path).exists()) {
                    outcomes[i] = true // already gone
                }
            }
            if (indices.isEmpty()) {
                result.success(outcomes)
                return
            }
            val bulk = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
            val batch = DeleteBatch(result, outcomes, indices, uris, bulk)
            pendingDelete = batch
            if (bulk) {
                val sender = MediaStore.createDeleteRequest(contentResolver, uris).intentSender
                startIntentSenderForResult(sender, deleteRequestCode, null, 0, 0, 0)
            } else {
                processNextDelete(batch)
            }
        } catch (e: Exception) {
            pendingDelete = null
            result.success(outcomes)
        }
    }

    private fun finishDelete(batch: DeleteBatch) {
        pendingDelete = null
        batch.result.success(batch.outcomes)
    }

    private fun processNextDelete(batch: DeleteBatch) {
        while (batch.next < batch.indices.size) {
            val uri = batch.uris[batch.next]
            try {
                val rows = contentResolver.delete(uri, null, null)
                batch.outcomes[batch.indices[batch.next]] = rows > 0
            } catch (e: SecurityException) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    e is android.app.RecoverableSecurityException &&
                    !batch.retried
                ) {
                    batch.retried = true
                    try {
                        startIntentSenderForResult(
                            e.userAction.actionIntent.intentSender,
                            deleteRequestCode, null, 0, 0, 0
                        )
                        return
                    } catch (_: Exception) {
                    }
                }
            } catch (_: Exception) {
            }
            batch.retried = false
            batch.next++
        }
        finishDelete(batch)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == deleteRequestCode) {
            val batch = pendingDelete
            if (batch == null) return
            if (batch.bulkRequest) {
                if (resultCode == Activity.RESULT_OK) {
                    batch.indices.forEach { batch.outcomes[it] = true }
                }
                finishDelete(batch)
            } else if (resultCode == Activity.RESULT_OK) {
                processNextDelete(batch) // retry the same file once
            } else {
                batch.retried = false
                batch.next++
                processNextDelete(batch)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        // Pending/in-flight queries are abandoned with the activity; their
        // cursors close via `use`, and replies are dropped (see runQuery).
        queryExecutor.shutdownNow()
        super.onDestroy()
    }

    // Publishes [path] into the public Music/Listeny folder via MediaStore and
    // returns the new row's identity (the same fields the library sync keys
    // on), or null if it could not be saved. The app OWNS the row it creates,
    // so on Android 11+ it can read/play it by path and delete it with no
    // storage permission. IS_MUSIC is set so a later permissioned sync sees it
    // as the same source instead of a new file.
    private fun saveToMusic(path: String, rawName: String): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val src = java.io.File(path)
        if (!src.isFile) return null
        val name = rawName.replace(Regex("[\\\\/:*?\"<>|]"), "_").ifBlank { src.name }
        val volume = MediaStore.VOLUME_EXTERNAL_PRIMARY
        val values = android.content.ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, name)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeForName(name))
            put(MediaStore.Audio.Media.RELATIVE_PATH, "Music/Listeny")
            put(MediaStore.Audio.Media.IS_MUSIC, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Audio.Media.getContentUri(volume), values)
            ?: return null
        try {
            contentResolver.openOutputStream(uri)?.use { out ->
                src.inputStream().use { it.copyTo(out) }
            } ?: throw java.io.IOException("no output stream")
            contentResolver.update(
                uri,
                android.content.ContentValues().apply {
                    put(MediaStore.Audio.Media.IS_PENDING, 0)
                },
                null, null
            )
            contentResolver.query(
                uri,
                arrayOf(
                    MediaStore.Audio.Media.DATA,
                    MediaStore.Audio.Media.SIZE,
                    MediaStore.Audio.Media.DATE_MODIFIED
                ),
                null, null, null
            )?.use { c ->
                if (c.moveToFirst()) {
                    return mapOf(
                        "id" to ContentUris.parseId(uri),
                        "volume" to volume,
                        "path" to c.getString(0),
                        "size" to c.getLong(1),
                        "modifiedSec" to c.getLong(2)
                    )
                }
            }
            throw java.io.IOException("saved row not found")
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            return null
        }
    }

    // MIME type for a published file, from its extension (MP3 by default).
    private fun mimeForName(name: String): String =
        when (name.substringAfterLast('.', "").lowercase()) {
            "m4a" -> "audio/mp4"
            "aac" -> "audio/aac"
            "wav" -> "audio/wav"
            "flac" -> "audio/flac"
            "aif", "aiff" -> "audio/aiff"
            else -> "audio/mpeg"
        }

    // Removes a row this app just created with saveToMusic (e.g. the import
    // turned out to be a duplicate). Own rows delete without a prompt.
    private fun discardSaved(volume: String, id: Long): Boolean = try {
        contentResolver.delete(ContentUris.withAppendedId(collectionFor(volume), id), null, null) > 0
    } catch (e: Exception) {
        false
    }

    // Runs [block] off the main thread and replies on the main thread. A
    // missing audio permission surfaces as PERMISSION_DENIED (distinct from a
    // generic failure) so Dart can show the right message.
    private fun runQuery(result: MethodChannel.Result, block: () -> Any) {
        try {
            queryExecutor.execute {
                var value: Any? = null
                var errorCode = "QUERY_FAILED"
                var errorMessage: String? = null
                try {
                    value = block()
                } catch (e: SecurityException) {
                    errorCode = "PERMISSION_DENIED"
                    errorMessage = e.message
                } catch (e: Exception) {
                    errorMessage = e.message
                }
                val finalValue = value
                val finalCode = errorCode
                val finalMessage = errorMessage
                if (!isDestroyed && !isFinishing) {
                    runOnUiThread {
                        if (!isDestroyed) {
                            if (finalValue != null) {
                                result.success(finalValue)
                            } else {
                                result.error(finalCode, finalMessage, null)
                            }
                        }
                    }
                }
            }
        } catch (e: java.util.concurrent.RejectedExecutionException) {
            result.error("QUERY_FAILED", "activity is shutting down", null)
        }
    }

    // Enumerates audio already indexed by the device's own media scanner
    // (MediaStore) instead of launching Android's document picker — that
    // picker (com.android.documentsui) is what crashes with a SecurityException
    // in ProvidersCache.loadRootsForAuthority on this device's Knox/Work
    // Profile configuration, taking our activity down with it. Querying
    // MediaStore directly never starts another app's Activity, so that crash
    // path doesn't exist here. It's also scoped-storage compliant: reading the
    // DATA column for audio rows only needs READ_MEDIA_AUDIO/
    // READ_EXTERNAL_STORAGE (already declared), not MANAGE_EXTERNAL_STORAGE.
    private fun queryAudioFiles(): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DURATION
        )
        // Excludes ringtones/notification/alarm sounds that are technically
        // audio rows but not music the user would want in their library.
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        contentResolver.query(
            collection, projection, selection, null,
            "${MediaStore.Audio.Media.DISPLAY_NAME} ASC"
        )?.use { cursor: Cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val durationCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)

            while (cursor.moveToNext()) {
                val path = if (dataCol >= 0) cursor.getString(dataCol) else null
                if (path.isNullOrEmpty()) continue
                results.add(
                    mapOf(
                        "id" to cursor.getLong(idCol),
                        "name" to cursor.getString(nameCol),
                        "path" to path,
                        "sizeBytes" to cursor.getLong(sizeCol),
                        "durationMs" to if (durationCol >= 0) cursor.getLong(durationCol) else 0L
                    )
                )
            }
        }
        return results
    }

    // The concrete external storage volumes to scan. API 29+: every volume
    // MediaStore reports (primary + SD cards, ...), each addressed by its own
    // name. Before 29 there is one logical "external" collection.
    private fun mp3Volumes(): List<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.getExternalVolumeNames(this).toList().sorted()
        } else {
            listOf("external")
        }

    private fun collectionFor(volume: String): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && volume != "external") {
            MediaStore.Audio.Media.getContentUri(volume)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

    // One page (at most [limit] RAW rows with _ID > [afterId], ascending) of
    // MP3 rows from a single [volume]. No filesystem walk, no
    // MANAGE_EXTERNAL_STORAGE. IS_PENDING = 0 skips files still being
    // written (API 29+); trashed items are excluded by default on 30+.
    //
    // Continuation is explicit and based on RAW cursor progress, never on how
    // many usable rows came back:
    //   rawCount - rows the cursor returned (before dropping pathless ones)
    //   lastId   - _ID of the last raw row (the next page's afterId)
    //   hasMore  - rawCount == limit (a full raw page may be followed by more)
    // so rows without a path can't shorten a page and end the scan early.
    private fun queryMp3Page(volume: String, afterId: Long, limit: Int): Map<String, Any?> {
        val rows = mutableListOf<Map<String, Any?>>()
        val q = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_MODIFIED
        )
        var selection =
            "${MediaStore.Audio.Media._ID} > ? AND " +
            "(${MediaStore.Audio.Media.MIME_TYPE} = 'audio/mpeg' OR " +
            "${MediaStore.Audio.Media.DISPLAY_NAME} LIKE '%.mp3') AND " +
            "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        if (q) selection += " AND ${MediaStore.Audio.Media.IS_PENDING} = 0"
        val collection = collectionFor(volume)
        val cursorOrNull: Cursor? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 11+ rejects a "LIMIT" smuggled into sortOrder; the
                // Bundle query args are the supported way (API 26+).
                val args = Bundle().apply {
                    putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                    putStringArray(
                        ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                        arrayOf(afterId.toString())
                    )
                    putString(
                        ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                        "${MediaStore.Audio.Media._ID} ASC"
                    )
                    putInt(ContentResolver.QUERY_ARG_LIMIT, limit)
                }
                contentResolver.query(collection, projection, args, null)
            } else {
                contentResolver.query(
                    collection,
                    projection,
                    selection,
                    arrayOf(afterId.toString()),
                    "${MediaStore.Audio.Media._ID} ASC LIMIT $limit"
                )
            }
        var rawCount = 0
        var lastId = afterId
        cursorOrNull?.use { cursor: Cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val durationCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val modifiedCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)
            while (cursor.moveToNext()) {
                rawCount++
                val id = cursor.getLong(idCol)
                if (id > lastId) lastId = id
                val path = if (dataCol >= 0) cursor.getString(dataCol) else null
                if (path.isNullOrEmpty()) continue
                rows.add(
                    mapOf(
                        "id" to id,
                        "name" to cursor.getString(nameCol),
                        "path" to path,
                        "sizeBytes" to cursor.getLong(sizeCol),
                        "durationMs" to if (durationCol >= 0) cursor.getLong(durationCol) else 0L,
                        "modifiedSec" to if (modifiedCol >= 0) cursor.getLong(modifiedCol) else 0L,
                        "volume" to volume
                    )
                )
            }
        }
        return mapOf(
            "rows" to rows,
            "lastId" to lastId,
            "hasMore" to (rawCount >= limit)
        )
    }
}
