package app.wildkaki

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.ElevationGainedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.units.Length
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.random.Random

object FakeFitbit {
    val WRITE_PERMISSIONS = setOf(
        HealthPermission.getWritePermission(ExerciseSessionRecord::class),
        HealthPermission.getWritePermission(DistanceRecord::class),
        HealthPermission.getWritePermission(HeartRateRecord::class),
        HealthPermission.getWritePermission(ElevationGainedRecord::class),
    )

    suspend fun seedRun(client: HealthConnectClient) {
        val minutes = Random.nextLong(25, 70)
        val start = Instant.now()
            .minus(Random.nextLong(2, 14 * 24), ChronoUnit.HOURS)
            .truncatedTo(ChronoUnit.MINUTES)
        val end = start.plus(minutes, ChronoUnit.MINUTES)
        val offset = ZoneId.systemDefault().rules.getOffset(start)
        val distanceM = minutes * 60 * Random.nextDouble(2.6, 3.4)
        val baseBpm = Random.nextLong(135, 165)

        client.insertRecords(
            listOf<Record>(
                ExerciseSessionRecord(
                    startTime = start,
                    startZoneOffset = offset,
                    endTime = end,
                    endZoneOffset = offset,
                    metadata = Metadata.manualEntry(),
                    exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,
                    title = "Fake run",
                ),
                DistanceRecord(
                    startTime = start,
                    startZoneOffset = offset,
                    endTime = end,
                    endZoneOffset = offset,
                    distance = Length.meters(distanceM),
                    metadata = Metadata.manualEntry(),
                ),
                HeartRateRecord(
                    startTime = start,
                    startZoneOffset = offset,
                    endTime = end,
                    endZoneOffset = offset,
                    samples = List(minutes.toInt()) {
                        HeartRateRecord.Sample(
                            start.plus(it.toLong(), ChronoUnit.MINUTES),
                            baseBpm + Random.nextLong(-8, 9),
                        )
                    },
                    metadata = Metadata.manualEntry(),
                ),
                ElevationGainedRecord(
                    startTime = start,
                    startZoneOffset = offset,
                    endTime = end,
                    endZoneOffset = offset,
                    elevation = Length.meters(Random.nextDouble(5.0, 120.0)),
                    metadata = Metadata.manualEntry(),
                ),
            )
        )
    }
}
