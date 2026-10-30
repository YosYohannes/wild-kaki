package app.wildkaki

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.health.connect.client.HealthConnectClient
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

    private fun openSettings(result: MethodChannel.Result) {
        try {
            startActivity(Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"))
            result.success(null)
        } catch (e: Exception) {
            result.error("unavailable", e.message, null)
        }
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
