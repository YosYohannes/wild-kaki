package app.wildkaki

import kotlin.math.abs
import kotlin.random.Random

class Fox(var x: Float, val feet: Int, var dir: Int) {
    var walking = true
    var t = Random.nextFloat() * 3f
    private var left = 1f + Random.nextFloat() * 3f
    private val speed = 9f + Random.nextFloat() * 4f

    fun step(dt: Float) {
        left -= dt
        if (walking) {
            x += dir * speed * dt
            t += dt
            if (x <= -2f) { x = -2f; dir = 1 }
            if (x >= WORLD_W - 30f) { x = WORLD_W - 30f; dir = -1 }
        }
        if (left <= 0f) {
            walking = !walking
            left = if (walking) 1.5f + Random.nextFloat() * 3.5f else 1f + Random.nextFloat() * 2.5f
            if (walking && Random.nextFloat() < 0.35f) dir = -dir
        }
    }

    val frame: Int get() = if (walking) ((t / 0.2f).toInt()) % 2 else 0
    fun hit(px: Float, py: Float) = px >= x + 1 && px < x + 31 && py >= feet - 17 && py < feet
}

class Duck(val feet: Int, private val lo: Float, private val hi: Float, var dir: Int) {
    var x = lo + Random.nextFloat() * (hi - lo)
    var moving = true
    private var left = 2f + Random.nextFloat() * 4f
    private val speed = 3f + Random.nextFloat() * 2f

    fun step(dt: Float) {
        left -= dt
        if (moving) {
            x += dir * speed * dt
            if (x <= lo) { x = lo; dir = 1 }
            if (x >= hi) { x = hi; dir = -1 }
        }
        if (left <= 0f) {
            moving = !moving
            left = 2f + Random.nextFloat() * 4f
            if (moving && Random.nextFloat() < 0.4f) dir = -dir
        }
    }
}

class Bird(private var wait: Float) {
    var active = false
    var x = 0f
    var y = 0f
    var dir = 1
    var t = 0f
    private var speed = 18f

    fun step(dt: Float, day: Boolean) {
        if (active) {
            x += dir * speed * dt
            t += dt
            if (x < -34f || x > WORLD_W + 2f) { active = false; wait = 10f + Random.nextFloat() * 14f }
        } else {
            wait -= dt
            if (wait <= 0f && day) {
                active = true
                dir = if (Random.nextBoolean()) 1 else -1
                x = if (dir > 0) -32f else WORLD_W.toFloat()
                y = -12f + Random.nextFloat() * 80f
                speed = 16f + Random.nextFloat() * 8f
                t = 0f
            }
        }
    }

    val frame: Int get() = ((t / 0.14f).toInt()) % 2
}

class BushSpot(val id: String, val x: Int, val base: Int)

fun placeBushes(ids: List<String>): List<BushSpot> {
    val xs = mutableListOf<Int>()
    var tries = 0
    while (xs.size < ids.size && tries++ < 500) {
        val x = Layout.BUSH_FROM + Random.nextInt(Layout.BUSH_TO - Layout.BUSH_FROM + 1)
        if (xs.all { abs(it - x) >= 27 }) xs += x
    }
    return ids.mapIndexed { i, id -> BushSpot(id, xs.getOrElse(i) { Layout.BUSH_FROM + i * 27 }, 129 + Random.nextInt(3)) }
}

class SceneState {
    var clock = 0f
    val foxes = mutableListOf(Fox(10f, 238, 1), Fox(64f, 226, -1))
    val ducks = listOf(Duck(150, 4f, 98f, 1), Duck(163, 6f, 96f, -1), Duck(176, 20f, 80f, 1))
    val birds = listOf(Bird(2f), Bird(9f))
    val sleeperX = 66
    val sleeperFeet = 222

    fun step(dt: Float, motion: Boolean, night: Float) {
        clock += dt
        if (!motion) return
        foxes.forEach { it.step(dt) }
        ducks.forEach { it.step(dt) }
        birds.forEach { it.step(dt, night < 0.5f) }
    }

    fun addFox(x: Float) {
        foxes += Fox(x, 214 + Random.nextInt(22), if (x > 60f) -1 else 1)
    }
}
