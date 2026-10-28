package app.wildkaki

import android.graphics.Bitmap
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import kotlin.math.PI
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin

const val WORLD_W = 120

fun rgb(hex: Int): Int = 0xFF000000.toInt() or hex

fun mixColor(a: Int, b: Int, t: Float): Int {
    val k = t.coerceIn(0f, 1f)
    fun ch(shift: Int): Int {
        val x = (a shr shift) and 0xFF
        val y = (b shr shift) and 0xFF
        return (x + (y - x) * k).roundToInt()
    }
    return 0xFF000000.toInt() or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
}

fun roundHalfUp(v: Float): Int = floor(v + 0.5f).toInt()

class Mulberry(seed: Int) {
    private var s = seed

    fun next(): Float {
        s += 0x6D2B79F5
        var t = (s xor (s ushr 15)) * (1 or s)
        t = (t + ((t xor (t ushr 7)) * (61 or t))) xor t
        return ((t xor (t ushr 14)).toLong() and 0xFFFFFFFFL).toFloat() / 4294967296f
    }

    fun below(n: Int): Int = (next() * n).toInt()
}

class PixelBuffer(val width: Int, val height: Int) {
    private val pixels = IntArray(width * height)

    fun set(x: Int, y: Int, color: Int) {
        if (x in 0 until width && y in 0 until height) pixels[y * width + x] = color
    }

    fun rect(x: Int, y: Int, w: Int, h: Int, color: Int, alpha: Float = 1f) {
        val x1 = min(width, x + w)
        val y1 = min(height, y + h)
        for (yy in max(0, y) until y1) for (xx in max(0, x) until x1) {
            val i = yy * width + xx
            pixels[i] = if (alpha >= 1f) color else mixColor(pixels[i], color, alpha)
        }
    }

    fun disc(cx: Int, cy: Int, r: Int, color: Int, alpha: Float = 1f) {
        for (y in -r..r) for (x in -r..r) if (x * x + y * y <= r * r + r * 0.6) rect(cx + x, cy + y, 1, 1, color, alpha)
    }

    fun blob(cx: Int, cy: Int, rx: Int, ry: Int, color: Int) {
        for (y in -ry..ry) for (x in -rx..rx) {
            if ((x.toDouble() / rx).pow(2) + (y.toDouble() / ry).pow(2) <= 1.0) rect(cx + x, cy + y, 1, 1, color)
        }
    }

    fun ridge(base: Float, amp: Float, phase: Float, freq: Float, color: Int) {
        for (x in 0 until width) {
            val y = roundHalfUp(base + amp * sin(x.toFloat() / WORLD_W * 2f * PI.toFloat() * freq + phase))
            rect(x, y, 1, height - y, color)
        }
    }

    fun toImageBitmap(): ImageBitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888).asImageBitmap()
}
