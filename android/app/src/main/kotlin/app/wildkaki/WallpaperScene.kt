package app.wildkaki

import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.Random
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

private const val WORLD_W = 120
private const val SPRITE = 32

class AnimalSpec(
    val lane: String,
    val frames: List<String>,
    val heads: List<IntArray>,
    val hat: String?,
)

class Rain(
    val slant: Double,
    val speed: Double,
    val dayColor: Int,
    val nightColor: Int,
    val drops: List<DoubleArray>,
)

class Manifest(
    val rows: Int,
    val k: Double,
    val animate: Boolean,
    val waterline: Int,
    val lanes: Map<String, IntArray>,
    val backdrops: List<String>,
    val night: DoubleArray,
    val rain: Rain?,
    val animals: List<AnimalSpec>,
    val writtenAt: Long,
    val waiting: Int,
    val bushes: List<IntArray>,
)

private fun JSONArray.ints() = IntArray(length()) { getInt(it) }

fun parseManifest(text: String): Manifest {
    val j = JSONObject(text)
    val lanes = j.getJSONObject("lanes")
    val rain = j.optJSONObject("rain")?.let { r ->
        val drops = r.getJSONArray("drops")
        Rain(
            r.getDouble("slant"),
            r.getDouble("speed"),
            r.getInt("dayColor"),
            r.getInt("nightColor"),
            List(drops.length()) { i ->
                val d = drops.getJSONArray(i)
                doubleArrayOf(d.getDouble(0), d.getDouble(1), d.getDouble(2))
            },
        )
    }
    val animals = j.getJSONArray("animals")
    val night = j.getJSONArray("night")
    val backdrops = j.getJSONArray("backdrops")
    return Manifest(
        rows = j.getInt("rows"),
        k = j.getDouble("k"),
        animate = j.getBoolean("animate"),
        waterline = j.getInt("waterline"),
        lanes = lanes.keys().asSequence().associateWith { lanes.getJSONArray(it).ints() },
        backdrops = List(backdrops.length()) { backdrops.getString(it) },
        night = DoubleArray(night.length()) { night.getDouble(it) },
        rain = rain,
        animals = List(animals.length()) { i ->
            val a = animals.getJSONObject(i)
            val frames = a.getJSONArray("frames")
            val heads = a.getJSONArray("heads")
            AnimalSpec(
                lane = a.getString("lane"),
                frames = List(frames.length()) { frames.getString(it) },
                heads = List(heads.length()) { heads.getJSONArray(it).ints() },
                hat = if (a.isNull("hat")) null else a.getString("hat"),
            )
        },
        writtenAt = j.optLong("writtenAt"),
        waiting = j.optInt("waiting", 0),
        bushes = j.optJSONArray("bushes")?.let { b -> List(b.length()) { b.getJSONArray(it).ints() } }
            ?: emptyList(),
    )
}

private fun roundHalfUp(v: Double) = floor(v + 0.5).toInt()

abstract class Actor(val spec: AnimalSpec) {
    var x = 0.0
    var dir = 1
    var t = 0.0
    abstract val frame: Int
    abstract val feet: Int
    abstract val top: Int
    abstract fun step(dt: Double)
}

class Walker(spec: AnimalSpec, private val rnd: Random, override val feet: Int) : Actor(spec) {
    private var walking = true
    private var left = 1 + rnd.nextDouble() * 3
    private val speed = 9 + rnd.nextDouble() * 4

    init {
        t = rnd.nextDouble() * 3
    }

    override val frame get() = if (walking) (t / 0.2).toInt() % 2 else 0
    override val top get() = feet - SPRITE

    override fun step(dt: Double) {
        left -= dt
        if (walking) {
            x += dir * speed * dt
            t += dt
            if (x <= -2) { x = -2.0; dir = 1 }
            if (x >= WORLD_W - 30.0) { x = WORLD_W - 30.0; dir = -1 }
        }
        if (left <= 0) {
            walking = !walking
            left = if (walking) 1.5 + rnd.nextDouble() * 3.5 else 1 + rnd.nextDouble() * 2.5
            if (walking && rnd.nextDouble() < 0.35) dir = -dir
        }
    }
}

class Paddler(spec: AnimalSpec, private val rnd: Random, override val feet: Int) : Actor(spec) {
    private var moving = true
    private var left = 2 + rnd.nextDouble() * 4
    private val speed = 4 + rnd.nextDouble() * 3

    init {
        t = rnd.nextDouble() * 3
    }

    override val frame get() = if (moving) (t / 0.3).toInt() % 2 else 0
    override val top get() = feet - SPRITE

    override fun step(dt: Double) {
        left -= dt
        if (moving) {
            x += dir * speed * dt
            t += dt
            if (x <= -2) { x = -2.0; dir = 1 }
            if (x >= WORLD_W - 30.0) { x = WORLD_W - 30.0; dir = -1 }
        }
        if (left <= 0) {
            moving = !moving
            left = 2 + rnd.nextDouble() * 4
            if (moving && rnd.nextDouble() < 0.4) dir = -dir
        }
    }
}

class Glider(spec: AnimalSpec, rnd: Random, private val baseTop: Int) : Actor(spec) {
    private val phase = rnd.nextDouble() * 2 * Math.PI
    private val speed = 12 + rnd.nextDouble() * 6

    init {
        t = rnd.nextDouble() * 3
    }

    override val frame get() = (t / 0.14).toInt() % 2
    override val feet get() = top + SPRITE
    override val top get() = baseTop + (3 * sin(t * 2.2 + phase)).roundToInt()

    override fun step(dt: Double) {
        x += dir * speed * dt
        t += dt
        if (x <= -2) { x = -2.0; dir = 1 }
        if (x >= WORLD_W - 30.0) { x = WORLD_W - 30.0; dir = -1 }
    }
}

class WallpaperScene(private val assets: AssetManager, private val dir: File) {
    val manifest: Manifest
    val stamp: Long
    private val backdrops: List<Bitmap>
    private val sprites = HashMap<String, Bitmap?>()
    private val actors: List<Actor>
    private val paint = Paint().apply {
        isFilterBitmap = false
        isAntiAlias = false
        isDither = false
    }
    private val fill = Paint().apply { isAntiAlias = false }
    private var clock = 0.0
    var waitingOverride: Int? = null

    init {
        val file = File(dir, "manifest.json")
        stamp = file.lastModified()
        manifest = parseManifest(file.readText())
        backdrops = manifest.backdrops.map {
            BitmapFactory.decodeFile(File(dir, it).path) ?: throw IllegalStateException(it)
        }
        val rnd = Random()
        actors = manifest.animals.map { makeActor(it, rnd) }
    }

    val animate get() = manifest.animate

    private fun makeActor(spec: AnimalSpec, rnd: Random): Actor {
        val range = manifest.lanes.getValue(spec.lane)
        val startX = rnd.nextDouble() * (WORLD_W - 30.0)
        val ref = range[0] + rnd.nextInt(range[1])
        val dir = if (rnd.nextBoolean()) 1 else -1
        val at = roundHalfUp(ref * manifest.k)
        val actor = when (spec.lane) {
            "river" -> Paddler(spec, rnd, at)
            "sky" -> Glider(spec, rnd, at)
            else -> Walker(spec, rnd, at)
        }
        actor.x = if (spec.lane == "meadow") startX else min(max(startX, -2.0), WORLD_W - 30.0)
        actor.dir = dir
        return actor
    }

    fun step(dt: Double) {
        clock += dt
        if (!manifest.animate) return
        actors.forEach { it.step(dt) }
    }

    fun release() {
        backdrops.forEach { it.recycle() }
        sprites.values.forEach { it?.recycle() }
    }

    private fun sprite(name: String): Bitmap? = sprites.getOrPut(name) {
        try {
            assets.open("flutter_assets/assets/sprites/$name.png").use {
                BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inScaled = false })
            }
        } catch (e: Exception) {
            null
        }
    }

    fun draw(canvas: Canvas, w: Int, h: Int, hour: Double) {
        canvas.drawColor(Color.rgb(0x0F, 0x21, 0x19))
        val s = w / WORLD_W.toDouble()
        val index = hour.toInt().coerceIn(0, 23)
        val mix = hour - index
        val src = Rect(0, 0, WORLD_W, manifest.rows)
        val dst = Rect(0, 0, w, (manifest.rows * s).roundToInt())
        paint.alpha = 255
        canvas.drawBitmap(backdrops[index], src, dst, paint)
        if (mix > 0.004) {
            paint.alpha = (mix * 255).roundToInt()
            canvas.drawBitmap(backdrops[(index + 1) % 24], src, dst, paint)
            paint.alpha = 255
        }
        val night = manifest.night[index] + (manifest.night[(index + 1) % 24] - manifest.night[index]) * mix
        drawRain(canvas, s, night)

        actors.filter { it.spec.lane == "sky" }.forEach { drawActor(canvas, it, s, null) }
        val items = ArrayList<Pair<Int, () -> Unit>>()
        val shown = min(waitingOverride ?: manifest.waiting, manifest.bushes.size)
        for (i in 0 until shown) {
            val base = roundHalfUp(manifest.bushes[i][1] * manifest.k)
            items.add(base to { drawBush(canvas, manifest.bushes[i][0], base, s) })
        }
        for (a in actors.filter { it.spec.lane == "meadow" }) {
            items.add(a.feet to { drawActor(canvas, a, s, null) })
        }
        for (a in actors.filter { it.spec.lane == "river" }) {
            val clip = ((a.feet - manifest.waterline) * s).roundToInt()
            items.add(a.feet to { drawActor(canvas, a, s, clip) })
        }
        items.sortedBy { it.first }.forEach { it.second() }
    }

    private fun drawBush(canvas: Canvas, x: Int, base: Int, s: Double) {
        val blink = manifest.animate && (clock % 3.2) > 3.0
        val rustle = if (manifest.animate && ((clock + x * 0.03) % 5) < 0.45) {
            if ((clock * 24).toInt() % 2 == 1) 1 else -1
        } else {
            0
        }
        val bmp = sprite(if (blink) "bush_blink" else "bush") ?: return
        blit(canvas, bmp, x - 5 + rustle, base - 32, s, false)
    }

    private fun drawRain(canvas: Canvas, s: Double, night: Double) {
        val rain = manifest.rain ?: return
        if (!manifest.animate) return
        val span = manifest.rows + 3
        val k = night * 0.7
        fun ch(a: Int, b: Int, shift: Int) =
            (((a shr shift) and 0xFF) + ((((b shr shift) and 0xFF) - ((a shr shift) and 0xFF)) * k)).roundToInt()
        fill.color = Color.argb(
            (0.8 * 255).roundToInt(),
            ch(rain.dayColor, rain.nightColor, 16),
            ch(rain.dayColor, rain.nightColor, 8),
            ch(rain.dayColor, rain.nightColor, 0),
        )
        val lean = IntArray(3) { (it * rain.slant).roundToInt() }
        for (d in rain.drops) {
            val v = rain.speed * d[2]
            val y = floorMod(d[1] * span + v * clock, span.toDouble()).toInt() - 3
            val x = floorMod(d[0] * WORLD_W + v * rain.slant * clock, WORLD_W.toDouble()).toInt()
            for (i in 0 until 3) {
                val px = x + lean[i]
                val py = y + i
                canvas.drawRect(
                    (px * s).roundToInt().toFloat(),
                    (py * s).roundToInt().toFloat(),
                    ((px + 1) * s).roundToInt().toFloat(),
                    ((py + 1) * s).roundToInt().toFloat(),
                    fill,
                )
            }
        }
    }

    private fun floorMod(a: Double, m: Double) = ((a % m) + m) % m

    private fun drawActor(canvas: Canvas, a: Actor, s: Double, clipBottom: Int?) {
        val spec = a.spec
        if (spec.frames.isEmpty()) return
        val i = a.frame % spec.frames.size
        val body = sprite(spec.frames[i]) ?: return
        val left = a.dir < 0
        val x = a.x.roundToInt()
        val y = a.top
        canvas.save()
        if (clipBottom != null) canvas.clipRect(0, 0, canvas.width, clipBottom)
        blit(canvas, body, x, y, s, left)
        val hat = spec.hat?.let { sprite(it) }
        if (hat != null && spec.heads.isNotEmpty()) {
            val head = spec.heads[i % spec.heads.size]
            val hx = if (left) 31 - head[0] else head[0]
            blit(canvas, hat, x + hx - hat.width / 2, y + head[1] - hat.height + 1, s, left)
        }
        canvas.restore()
    }

    private fun blit(canvas: Canvas, bmp: Bitmap, x: Int, y: Int, s: Double, mirrored: Boolean) {
        val x0 = (x * s).roundToInt()
        val y0 = (y * s).roundToInt()
        val x1 = ((x + bmp.width) * s).roundToInt()
        val y1 = ((y + bmp.height) * s).roundToInt()
        canvas.save()
        if (mirrored) canvas.scale(-1f, 1f, (x0 + x1) / 2f, 0f)
        canvas.drawBitmap(bmp, Rect(0, 0, bmp.width, bmp.height), Rect(x0, y0, x1, y1), paint)
        canvas.restore()
    }
}
