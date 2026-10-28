package app.wildkaki

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ElevationGainedRecord
import androidx.health.connect.client.records.ExerciseRouteResult
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.FloorsClimbedRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.HeartRateVariabilityRmssdRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.SpeedRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.records.Vo2MaxRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlin.reflect.KClass

val READ_PERMISSIONS = setOf(
    HealthPermission.getReadPermission(ExerciseSessionRecord::class),
    HealthPermission.getReadPermission(DistanceRecord::class),
    HealthPermission.getReadPermission(HeartRateRecord::class),
    HealthPermission.getReadPermission(ElevationGainedRecord::class),
)

val INVENTORY_PERMISSIONS: Set<String> = setOf<KClass<out Record>>(
    ExerciseSessionRecord::class,
    DistanceRecord::class,
    HeartRateRecord::class,
    ElevationGainedRecord::class,
    StepsRecord::class,
    SpeedRecord::class,
    FloorsClimbedRecord::class,
    ActiveCaloriesBurnedRecord::class,
    TotalCaloriesBurnedRecord::class,
    SleepSessionRecord::class,
    RestingHeartRateRecord::class,
    HeartRateVariabilityRmssdRecord::class,
    Vo2MaxRecord::class,
    OxygenSaturationRecord::class,
).map { HealthPermission.getReadPermission(it) }.toSet() + HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY

private const val MAX_PAGES = 10
private val STAMP = DateTimeFormatter.ofPattern("d MMM HH:mm", Locale.getDefault())
    .withZone(ZoneId.systemDefault())

data class SyncedSession(
    val id: String,
    val type: String,
    val start: Instant,
    val end: Instant,
    val distanceM: Double?,
    val avgHeartRate: Long?,
    val elevationGainM: Double?,
    val source: String,
)

private class Page<T>(val records: List<T>, val capped: Boolean)

class HealthConnectSync(private val client: HealthConnectClient) {

    suspend fun hasAccess(): Boolean =
        client.permissionController.getGrantedPermissions().containsAll(READ_PERMISSIONS)

    suspend fun recentSessions(): List<SyncedSession> {
        val granted = client.permissionController.getGrantedPermissions()
        val days = if (HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY in granted) 365L else 30L
        val now = Instant.now()
        val range = TimeRangeFilter.between(now.minus(days, ChronoUnit.DAYS), now)
        val sessions = client.readRecords(ReadRecordsRequest(ExerciseSessionRecord::class, range)).records
        return sessions.sortedByDescending { it.startTime }.map { toSession(it) }
    }

    suspend fun inventory(): String {
        val granted = client.permissionController.getGrantedPermissions()
        val days = if (HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY in granted) 365L else 30L
        val now = Instant.now()
        val range = TimeRangeFilter.between(now.minus(days, ChronoUnit.DAYS), now)
        val lines = mutableListOf("Window: last $days days")
        lines += exerciseSection(range)
        lines += section<DistanceRecord>("Distance", range) { it.startTime }
        lines += section<HeartRateRecord>("Heart rate", range) { it.startTime }
        lines += section<ElevationGainedRecord>("Elevation gained", range) { it.startTime }
        lines += section<FloorsClimbedRecord>("Floors climbed", range) { it.startTime }
        lines += section<StepsRecord>("Steps", range) { it.startTime }
        lines += section<SpeedRecord>("Speed", range) { it.startTime }
        lines += section<ActiveCaloriesBurnedRecord>("Active calories", range) { it.startTime }
        lines += section<TotalCaloriesBurnedRecord>("Total calories", range) { it.startTime }
        lines += section<SleepSessionRecord>("Sleep sessions", range) { it.startTime }
        lines += section<RestingHeartRateRecord>("Resting heart rate", range) { it.time }
        lines += section<HeartRateVariabilityRmssdRecord>("Heart rate variability", range) { it.time }
        lines += section<Vo2MaxRecord>("VO2 max", range) { it.time }
        lines += section<OxygenSaturationRecord>("Oxygen saturation", range) { it.time }
        return lines.joinToString("\n")
    }

    private suspend fun exerciseSection(range: TimeRangeFilter): List<String> {
        val page = runCatching { readAll<ExerciseSessionRecord>(range) }
            .getOrElse { return listOf("Exercise sessions: not readable") }
        if (page.records.isEmpty()) return listOf("Exercise sessions: none")
        val lines = mutableListOf("Exercise sessions: ${page.records.size}${if (page.capped) "+" else ""}")
        page.records.groupBy { it.exerciseType }.forEach { (type, sessions) ->
            val withRoute = sessions.count { it.exerciseRouteResult !is ExerciseRouteResult.NoData }
            val newest = STAMP.format(sessions.maxOf { it.startTime })
            lines += "  ${sessions.size} x ${typeLabel(type)}, route on $withRoute, newest $newest"
        }
        lines += sourceLines(page.records)
        return lines
    }

    private suspend inline fun <reified T : Record> section(
        label: String,
        range: TimeRangeFilter,
        at: (T) -> Instant,
    ): List<String> {
        val page = runCatching { readAll<T>(range) }.getOrElse { return listOf("$label: not readable") }
        if (page.records.isEmpty()) return listOf("$label: none")
        val times = page.records.map(at)
        val count = "${page.records.size}${if (page.capped) "+" else ""}"
        val span = " (${STAMP.format(times.max())} back to ${STAMP.format(times.min())})"
        return listOf("$label: $count$span") + sourceLines(page.records)
    }

    private suspend inline fun <reified T : Record> readAll(range: TimeRangeFilter): Page<T> {
        val records = mutableListOf<T>()
        var token: String? = null
        var pages = 0
        do {
            val response = client.readRecords(
                ReadRecordsRequest(T::class, range, ascendingOrder = false, pageSize = 5000, pageToken = token)
            )
            records += response.records
            token = response.pageToken
            pages++
        } while (token != null && pages < MAX_PAGES)
        return Page(records, capped = token != null)
    }

    private fun sourceLines(records: List<Record>): List<String> =
        records.groupingBy { it.metadata.dataOrigin.packageName }.eachCount()
            .map { (source, n) -> "  $n from $source" }

    private fun typeLabel(type: Int): String =
        ExerciseSessionRecord.EXERCISE_TYPE_INT_TO_STRING_MAP[type] ?: "type $type"

    private suspend fun toSession(session: ExerciseSessionRecord): SyncedSession {
        val totals = client.aggregate(
            AggregateRequest(
                metrics = setOf(
                    DistanceRecord.DISTANCE_TOTAL,
                    HeartRateRecord.BPM_AVG,
                    ElevationGainedRecord.ELEVATION_GAINED_TOTAL,
                ),
                timeRangeFilter = TimeRangeFilter.between(session.startTime, session.endTime),
            )
        )
        return SyncedSession(
            id = session.metadata.id,
            type = typeLabel(session.exerciseType),
            start = session.startTime,
            end = session.endTime,
            distanceM = totals[DistanceRecord.DISTANCE_TOTAL]?.inMeters,
            avgHeartRate = totals[HeartRateRecord.BPM_AVG],
            elevationGainM = totals[ElevationGainedRecord.ELEVATION_GAINED_TOTAL]?.inMeters,
            source = session.metadata.dataOrigin.packageName,
        )
    }
}
