package app.wildkaki

import java.time.Duration
import java.time.Instant

enum class OutingType(val label: String) { Run("Run"), Walk("Walk"), Climb("Climb") }

data class Outing(
    val id: String,
    val type: OutingType,
    val start: Instant,
    val distanceKm: Double?,
    val minutes: Int,
)

data class Sighting(val outing: Outing, val animal: String)

data class HomeState(
    val waiting: List<Outing>,
    val sightings: List<Sighting>,
    val lastSynced: Instant?,
)

object MockData {
    fun home(): HomeState {
        val now = Instant.now()
        fun outing(id: String, type: OutingType, daysAgo: Long, km: Double?, minutes: Int) =
            Outing(id, type, now.minus(Duration.ofDays(daysAgo)), km, minutes)

        return HomeState(
            waiting = listOf(
                outing("w1", OutingType.Run, 0, 3.57, 22),
                outing("w2", OutingType.Climb, 1, null, 48),
            ),
            sightings = listOf(
                Sighting(outing("s1", OutingType.Run, 2, 5.2, 31), Buddy.NAME),
                Sighting(outing("s2", OutingType.Walk, 4, 2.4, 35), Buddy.NAME),
                Sighting(outing("s3", OutingType.Run, 6, 4.8, 29), Buddy.NAME),
            ),
            lastSynced = now.minus(Duration.ofMinutes(2)),
        )
    }
}
