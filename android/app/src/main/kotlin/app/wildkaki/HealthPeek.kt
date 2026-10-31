package app.wildkaki

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import org.json.JSONArray
import java.time.Duration
import java.time.Instant
import kotlin.reflect.KClass

object HealthPeek {
    const val BACKGROUND = "android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND"
    private const val EXERCISE = "android.permission.health.READ_EXERCISE"
    private const val SLEEP = "android.permission.health.READ_SLEEP"
    private val lookback = Duration.ofDays(7)

    suspend fun backgroundAllowed(context: Context): Boolean = try {
        HealthConnectClient.getOrCreate(context).permissionController
            .getGrantedPermissions().contains(BACKGROUND)
    } catch (e: Exception) {
        false
    }

    suspend fun waiting(context: Context): Int? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val baseline = try {
            prefs.getLong("flutter.baseline", -1)
        } catch (e: Exception) {
            -1
        }
        if (baseline < 0) return null
        val revealed = revealedIds(prefs.getString("flutter.sightings", null))
        return try {
            val client = HealthConnectClient.getOrCreate(context)
            val granted = client.permissionController.getGrantedPermissions()
            if (!granted.containsAll(listOf(BACKGROUND, EXERCISE, SLEEP))) return null
            val since = Instant.ofEpochMilli(baseline)
            val range = TimeRangeFilter.between(since.minus(lookback), Instant.now())
            val ids = HashSet<String>()
            for (session in readAll(client, ExerciseSessionRecord::class, range)) {
                if (!session.startTime.isBefore(since)) ids.add(session.metadata.id)
            }
            for (sleep in readAll(client, SleepSessionRecord::class, range)) {
                if (!sleep.endTime.isBefore(since)) ids.add(sleep.metadata.id)
            }
            ids.count { it !in revealed }
        } catch (e: Exception) {
            null
        }
    }

    private fun revealedIds(json: String?): Set<String> {
        if (json == null) return emptySet()
        return try {
            val list = JSONArray(json)
            (0 until list.length()).map { list.getJSONObject(it).getString("id") }.toSet()
        } catch (e: Exception) {
            emptySet()
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
