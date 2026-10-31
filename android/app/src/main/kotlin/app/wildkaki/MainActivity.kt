package app.wildkaki

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import java.io.File
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.util.TimeZone
import kotlin.reflect.KClass
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pendingBackground: MethodChannel.Result? = null
    private val backgroundRequest = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        pendingBackground?.success(granted.contains(HealthPeek.BACKGROUND))
        pendingBackground = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.wildkaki/health")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSettings" -> openSettings(result)
                    "timeZone" -> result.success(TimeZone.getDefault().id)
                    "readOutings" -> readOutings(call, result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.wildkaki/wallpaper")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dir" -> result.success(java.io.File(filesDir, "wallpaper").apply { mkdirs() }.absolutePath)
                    "active" -> result.success(wallpaperActive())
                    "set" -> result.success(chooseWallpaper())
                    "log" -> {
                        android.util.Log.w("WildWallpaper", "dart: ${call.arguments}")
                        result.success(null)
                    }
                    "backgroundAllowed" -> scope.launch {
                        result.success(HealthPeek.backgroundAllowed(applicationContext))
                    }
                    "requestBackground" -> requestBackground(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.wildkaki/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "version" -> result.success(packageManager.getPackageInfo(packageName, 0).versionName)
                    "abis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "open" -> try {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments as String)))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("open", e.message, null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun requestBackground(result: MethodChannel.Result) {
        if (pendingBackground != null) {
            result.success(false)
            return
        }
        pendingBackground = result
        try {
            backgroundRequest.launch(setOf(HealthPeek.BACKGROUND))
        } catch (e: Exception) {
            pendingBackground = null
            result.success(false)
        }
    }

    private fun wallpaperActive(): Boolean {
        val manager = WallpaperManager.getInstance(this)
        val home = try {
            manager.wallpaperInfo?.packageName
        } catch (e: Exception) {
            null
        }
        val lock = try {
            if (Build.VERSION.SDK_INT >= 34) {
                manager.getWallpaperInfo(WallpaperManager.FLAG_LOCK)?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
        val started = File(filesDir, "wallpaper/started").exists()
        android.util.Log.i("WildWallpaper", "active? home=$home lock=$lock started=$started")
        return home == packageName || lock == packageName || started
    }

    private fun chooseWallpaper(): Boolean {
        val direct = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).putExtra(
            WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
            ComponentName(this, WildWallpaperService::class.java),
        )
        for (intent in listOf(direct, Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))) {
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                continue
            }
        }
        return false
    }

    private fun openSettings(result: MethodChannel.Result) {
        val intents = listOf(
            HealthConnectClient.getHealthConnectManageDataIntent(this),
            Intent("android.health.connect.action.HEALTH_HOME_SETTINGS"),
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"),
        )
        for (intent in intents) {
            try {
                startActivity(intent)
                result.success(null)
                return
            } catch (e: Exception) {
                continue
            }
        }
        result.error("unavailable", "no Health Connect settings screen", null)
    }

    private fun readOutings(call: MethodCall, result: MethodChannel.Result) {
        val since = call.argument<Number>("sinceMillis")?.toLong()
        if (since == null) {
            result.error("bad_args", "sinceMillis is required", null)
            return
        }
        scope.launch {
            try {
                val outings = withContext(Dispatchers.IO) { loadOutings(Instant.ofEpochMilli(since)) }
                result.success(outings)
            } catch (e: Exception) {
                result.error("read_failed", e.message ?: e.javaClass.simpleName, null)
            }
        }
    }

    private suspend fun loadOutings(since: Instant): List<Map<String, Any?>> {
        val client = HealthConnectClient.getOrCreate(applicationContext)
        val range = TimeRangeFilter.between(since, Instant.now())
        val sessions = readAll(client, ExerciseSessionRecord::class, range)
        val sleeps = readAll(client, SleepSessionRecord::class, range)
        val exercises = sessions.map { session ->
            val totals = client.aggregate(
                AggregateRequest(
                    metrics = setOf(DistanceRecord.DISTANCE_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(session.startTime, session.endTime),
                )
            )
            mapOf(
                "id" to session.metadata.id,
                "exerciseType" to session.exerciseType,
                "startMillis" to session.startTime.toEpochMilli(),
                "endMillis" to session.endTime.toEpochMilli(),
                "distanceMeters" to totals[DistanceRecord.DISTANCE_TOTAL]?.inMeters,
            )
        }
        return exercises + sleeps.map { sleep ->
            mapOf(
                "id" to sleep.metadata.id,
                "kind" to "sleep",
                "startMillis" to sleep.startTime.toEpochMilli(),
                "endMillis" to sleep.endTime.toEpochMilli(),
            )
        }
    }

    private suspend fun <T : Record> readAll(
        client: HealthConnectClient,
        type: KClass<T>,
        range: TimeRangeFilter,
    ): List<T> {
        val records = mutableListOf<T>()
        var token: String? = null
        do {
            val page = client.readRecords(
                ReadRecordsRequest(type, range, pageSize = 500, pageToken = token)
            )
            records += page.records
            token = page.pageToken
        } while (token != null)
        return records
    }
}
