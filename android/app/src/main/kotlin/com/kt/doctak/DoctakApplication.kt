package com.kt.doctak

import android.app.Application
import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import java.io.File

class DoctakApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Clean up corrupted DataTransport databases
        // cleanupCorruptedDatabases()

        // Initialize Firebase
        FirebaseApp.initializeApp(this)

        // Enable Crashlytics collection
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(true)
    }

    private fun cleanupCorruptedDatabases() {
        try {
            // DataTransport stores its databases in the app's database directory
            val databasesDir = getDatabasePath("dummy").parentFile
            if (databasesDir != null && databasesDir.exists()) {
                // Look for Google DataTransport database files
                val transportDatabases =
                        databasesDir.listFiles { file ->
                            file.name.contains("com.google.android.datatransport") ||
                                    file.name.contains("google_app_measurement") ||
                                    file.name.contains("firebase") ||
                                    file.name.contains("datatransport")
                        }

                transportDatabases?.forEach { dbFile ->
                    try {
                        // Check if the database file might be corrupted
                        if (isDatabaseCorrupted(dbFile)) {
                            // Delete the corrupted database and its journal files
                            deleteDatabase(dbFile.name)

                            // Also delete related files
                            val journalFile = File(dbFile.absolutePath + "-journal")
                            if (journalFile.exists()) {
                                journalFile.delete()
                            }

                            val walFile = File(dbFile.absolutePath + "-wal")
                            if (walFile.exists()) {
                                walFile.delete()
                            }

                            val shmFile = File(dbFile.absolutePath + "-shm")
                            if (shmFile.exists()) {
                                shmFile.delete()
                            }

                            android.util.Log.d(
                                    "DoctakApplication",
                                    "Deleted potentially corrupted database: ${dbFile.name}"
                            )
                        }
                    } catch (e: Exception) {
                        android.util.Log.e(
                                "DoctakApplication",
                                "Error checking database ${dbFile.name}",
                                e
                        )
                    }
                }
            }

            // Clear DataTransport cache directory
            clearDataTransportCache()
        } catch (e: Exception) {
            android.util.Log.e("DoctakApplication", "Error cleaning up databases", e)
        }
    }

    private fun isDatabaseCorrupted(dbFile: File): Boolean {
        // Basic heuristic: if the database file is very small (< 4KB) or
        // has been modified recently but is empty, it might be corrupted
        if (!dbFile.exists()) return false

        val fileSize = dbFile.length()

        // SQLite database header is at least 100 bytes
        if (fileSize < 100) {
            return true
        }

        // Check for SQLite header magic string
        try {
            dbFile.inputStream().use { stream ->
                val header = ByteArray(16)
                if (stream.read(header) == 16) {
                    val magicString = String(header, 0, 15)
                    if (!magicString.startsWith("SQLite format 3")) {
                        return true
                    }
                }
            }
        } catch (e: Exception) {
            // If we can't read the file, consider it corrupted
            return true
        }

        return false
    }

    private fun clearDataTransportCache() {
        try {
            // Clear cache directories that might contain DataTransport data
            val cacheDir = cacheDir
            val transportCacheDir = File(cacheDir, "com.google.android.datatransport")
            if (transportCacheDir.exists()) {
                transportCacheDir.deleteRecursively()
            }

            // Clear files cache
            val filesDir = filesDir
            val transportFilesDir = File(filesDir, "com.google.android.datatransport")
            if (transportFilesDir.exists()) {
                transportFilesDir.deleteRecursively()
            }
        } catch (e: Exception) {
            android.util.Log.e("DoctakApplication", "Error clearing DataTransport cache", e)
        }
    }

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)

        // Handle any uncaught exceptions related to SQLite corruption
        Thread.setDefaultUncaughtExceptionHandler { thread, exception ->
            if (exception.message?.contains("database disk image is malformed") == true ||
                            exception.message?.contains("SQLITE_CORRUPT") == true
            ) {

                android.util.Log.e(
                        "DoctakApplication",
                        "SQLite corruption detected, scheduling cleanup on next launch",
                        exception
                )

                // Mark that we need to clean databases on next launch
                getSharedPreferences("app_prefs", MODE_PRIVATE)
                        .edit()
                        .putBoolean("needs_database_cleanup", true)
                        .apply()
            }

            // Re-throw to let the system handle it
            throw exception
        }
    }
}
