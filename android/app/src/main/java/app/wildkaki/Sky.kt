package app.wildkaki

import java.time.LocalTime

class Sky(val top: Int, val bottom: Int, val stars: Float)

private class SkyKey(val hour: Float, val top: Int, val bottom: Int, val stars: Float)

private val NIGHT_TOP = rgb(0x0A1620)
private val NIGHT_BOTTOM = rgb(0x1B3427)
private val DAY_TOP = rgb(0x2B5E52)
private val DAY_BOTTOM = rgb(0x3E7A66)

private val SKY_KEYS = listOf(
    SkyKey(0f, NIGHT_TOP, NIGHT_BOTTOM, 1f),
    SkyKey(4.75f, NIGHT_TOP, NIGHT_BOTTOM, 1f),
    SkyKey(5.75f, rgb(0x16223C), rgb(0x35405A), 0.75f),
    SkyKey(6.75f, rgb(0x3B4A6B), rgb(0xD98A5B), 0.3f),
    SkyKey(9f, DAY_TOP, DAY_BOTTOM, 0f),
    SkyKey(16f, DAY_TOP, DAY_BOTTOM, 0f),
    SkyKey(18f, rgb(0x4A3F6B), rgb(0xE0875A), 0.3f),
    SkyKey(19.1f, rgb(0x262448), rgb(0x5A3A55), 0.65f),
    SkyKey(20.5f, NIGHT_TOP, NIGHT_BOTTOM, 1f),
    SkyKey(24f, NIGHT_TOP, NIGHT_BOTTOM, 1f),
)

fun currentHour(): Float = LocalTime.now().let { it.hour + it.minute / 60f }

fun skyAt(hour: Float): Sky {
    val i = SKY_KEYS.indexOfLast { it.hour <= hour }.coerceAtMost(SKY_KEYS.size - 2)
    val a = SKY_KEYS[i]
    val b = SKY_KEYS[i + 1]
    val t = ((hour - a.hour) / (b.hour - a.hour)).coerceIn(0f, 1f)
    return Sky(mixColor(a.top, b.top, t), mixColor(a.bottom, b.bottom, t), a.stars + (b.stars - a.stars) * t)
}
