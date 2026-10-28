package app.wildkaki

import androidx.compose.ui.graphics.ImageBitmap
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.roundToInt
import kotlin.math.sin

object Layout {
    const val GROUND = 108
    const val BENCH_X = 14
    const val BENCH_Y = 110
    const val LAMP_X = 3
    const val LAMP_Y = 87
    const val BUSH_FROM = 52
    const val BUSH_TO = 94

    fun riverTop(x: Int): Int = 136 + roundHalfUp(2f * sin(x * 0.08f))
    fun riverBot(x: Int): Int = 184 + roundHalfUp(2f * sin(x * 0.06f + 1f))
}

private val BAYER = arrayOf(
    intArrayOf(0, 8, 2, 10), intArrayOf(12, 4, 14, 6), intArrayOf(3, 11, 1, 9), intArrayOf(15, 7, 13, 5),
)

private fun quant(c: Int): Int {
    fun ch(shift: Int) = (Math.round(((c shr shift) and 0xFF) / 16f) * 16).coerceAtMost(255)
    return 0xFF000000.toInt() or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
}

private class Tower(val x: Int, val w: Int, val top: Int, val crown: String, val wall: Boolean)

/** Paints the sky, skyline, trees, meadow and river at 120 pixels wide and [rows] tall. */
fun paintWorld(hour: Float, rows: Int): ImageBitmap {
    val g = Layout.GROUND
    val w = WORLD_W
    val buf = PixelBuffer(w, rows)
    val sky = skyAt(hour)
    val night = sky.stars
    val r = Mulberry(7)
    fun t(c: Int, k: Float) = mixColor(mixColor(c, sky.bottom, k), rgb(0x08121A), night * 0.5f)
    fun f(c: Int) = mixColor(c, rgb(0x0B1510), night * 0.55f)
    val skyBottom = mixColor(sky.bottom, rgb(0x10222E), night * 0.75f)

    for (y in 0 until g) {
        val k = y / (g - 2f)
        val base = FloatArray(3) { i ->
            val shift = 16 - 8 * i
            val a = (sky.top shr shift) and 0xFF
            val b = (skyBottom shr shift) and 0xFF
            a + (b - a) * k
        }
        for (x in 0 until w) {
            val th = (BAYER[y and 3][x and 3] + 0.5f) / 16f
            val c = IntArray(3) { i -> minOf(255, floor(base[i] / 8f + th).toInt() * 8) }
            buf.set(x, y, rgb((c[0] shl 16) or (c[1] shl 8) or c[2]))
        }
    }

    val stars = Mulberry(3)
    repeat(26) {
        val sx = stars.below(w)
        val sy = (stars.below(90) * 0.5f).toInt()
        buf.rect(sx, sy, 1, 1, rgb(0xF3ECDC), (night * 0.85f).coerceIn(0f, 1f))
    }
    val day = hour in 6f..18f
    val shifted = if (hour < 6f) hour + 24f else hour
    val p = if (day) (hour - 6f) / 12f else ((shifted - 18f) / 12f).coerceIn(0f, 1f)
    val cx = (w * (0.12f + 0.76f * p)).roundToInt()
    val cy = roundHalfUp(54f - 36f * sin(PI.toFloat() * p))
    val body = if (day) rgb(0xF6D77A) else rgb(0xF1E3B8)
    buf.disc(cx, cy, 10, body, 0.16f)
    buf.disc(cx, cy, 6, body)

    buf.ridge(48f, 5f, 2f, 1.4f, t(rgb(0x2F4F3E), 0.5f))
    listOf(intArrayOf(62, 6, 50), intArrayOf(76, 5, 42), intArrayOf(90, 6, 46), intArrayOf(101, 5, 36), intArrayOf(113, 6, 44))
        .forEach { (x, tw, top) -> buf.rect(x, top, tw, g - top, t(rgb(0x20383A), 0.7f)) }
    buf.ridge(70f, 5f, 3.4f, 1.4f, t(rgb(0x1B3427), 0.3f))

    val towers = listOf(Tower(70, 12, 40, "garden", true), Tower(83, 10, 24, "spire", false), Tower(94, 13, 54, "stepped", true), Tower(108, 12, 34, "garden", false))
    for (tw in towers) {
        val col = t(rgb(0x20383A), 0.28f)
        val leaf = t(rgb(0x2F6A45), 0.15f)
        buf.rect(tw.x, tw.top, tw.w, g - tw.top, col)
        when (tw.crown) {
            "stepped" -> buf.rect(tw.x + 3, tw.top - 5, tw.w - 6, 5, col)
            "spire" -> buf.rect(tw.x + tw.w / 2, tw.top - 9, 1, 9, col)
            "garden" -> {
                buf.rect(tw.x, tw.top - 1, tw.w, 1, leaf)
                var i = 0
                while (i < tw.w) { buf.rect(tw.x + i, tw.top - 2, 2, 1, leaf); i += 3 }
                buf.rect(tw.x + tw.w - 4, tw.top - 5, 1, 4, t(rgb(0x12261C), 0.2f))
                buf.disc(tw.x + tw.w - 4, tw.top - 7, 2, t(rgb(0x1C4630), 0.15f))
            }
        }
        var wy = tw.top + 3
        while (wy < g - 6) {
            var wx = tw.x + 2
            while (wx < tw.x + tw.w - 1) {
                buf.rect(wx, wy, 1, 2, if (r.next() < night * 0.55f) rgb(0xFFD98A) else t(rgb(0x2F5A52), 0.35f))
                wx += 3
            }
            wy += 4
        }
        if (tw.wall) {
            val ly = tw.top + ((g - tw.top) * 0.3f).roundToInt()
            buf.rect(tw.x, ly, tw.w, 1, leaf)
            buf.rect(tw.x + 2, ly + 1, 1, 4, leaf)
        }
    }

    val leaf = t(rgb(0x1C4630), 0.2f)
    val light = t(rgb(0x2A5A3A), 0.2f)
    fun tree(tx: Int, top: Int, k: Float) {
        fun s(v: Int) = (v * k).roundToInt()
        buf.rect(tx - 1, top + s(18), 3, g - top - s(18), t(rgb(0x12261C), 0.2f))
        buf.rect(tx - 3, g - 4, 7, 4, t(rgb(0x12261C), 0.2f))
        buf.blob(tx, top + s(10), s(12), s(10), leaf)
        buf.blob(tx - s(8), top + s(14), s(8), s(7), leaf)
        buf.blob(tx + s(8), top + s(13), s(9), s(7), leaf)
        buf.blob(tx - 2, top + s(6), s(7), s(5), light)
    }
    tree(22, 50, 1f)
    tree(47, 68, 0.75f)
    for (x in 0 until w) {
        val y = g - 8 + roundHalfUp(2f * sin(x * 0.35f) + r.next() * 2f)
        buf.rect(x, y, 1, g + 4 - y, leaf)
    }

    var y = g
    while (y < rows) {
        buf.rect(0, y, w, minOf(8, rows - y), if (((y - g) / 8) % 2 != 0) f(rgb(0x2B6038)) else f(rgb(0x2F6A3F)))
        y += 8
    }
    buf.rect(0, g, w, 3, f(rgb(0x3A7A45)))
    val span = (rows - g - 12).coerceAtLeast(60)
    repeat(220 * span / 148) {
        buf.rect(r.below(w), g + 4 + r.below(span), 1, 1, if (r.next() < 0.5f) f(rgb(0x1F4A30)) else f(rgb(0x47904F)))
    }

    val waterTop = mixColor(rgb(0x58A8C0), sky.bottom, 0.2f)
    val waterBottom = mixColor(rgb(0x2F7A94), sky.bottom, 0.2f)
    for (x in 0 until w) {
        val top = Layout.riverTop(x)
        val bot = Layout.riverBot(x)
        buf.rect(x, top - 3, 1, bot - top + 6, f(rgb(0xA89A68)))
        for (yy in top until bot) buf.rect(x, yy, 1, 1, f(quant(mixColor(waterTop, waterBottom, (yy - top) / (bot - top).toFloat()))))
    }
    repeat(64) {
        val x = r.below(w - 6)
        val yy = 139 + r.below(42)
        if (yy > Layout.riverTop(x) + 1 && yy < Layout.riverBot(x) - 1) buf.rect(x, yy, 3 + r.below(4), 1, f(rgb(0x9FD0E0)))
    }

    if (night > 0.05f) {
        buf.disc(7, 95, 14, rgb(0xFFD98A), 0.07f * night)
        buf.disc(7, 95, 8, rgb(0xFFD98A), 0.12f * night)
    }
    return buf.toImageBitmap()
}
