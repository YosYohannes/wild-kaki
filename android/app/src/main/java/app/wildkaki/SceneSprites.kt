package app.wildkaki

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap

/** Every sprite is its own PNG in res/drawable-nodpi, made by tools/make_sprites.py. */
class SceneSprites(context: Context) {
    private val res = context.resources

    private fun load(id: Int): Bitmap =
        BitmapFactory.decodeResource(res, id, BitmapFactory.Options().apply { inScaled = false })

    private fun flipped(src: Bitmap): Bitmap =
        Bitmap.createBitmap(src, 0, 0, src.width, src.height, Matrix().apply { preScale(-1f, 1f) }, false)

    private val foxWalk = listOf(R.drawable.fox_walk_1, R.drawable.fox_walk_2).map { load(it) }
    private val birdFly = listOf(R.drawable.bird_1, R.drawable.bird_2).map { load(it) }
    private val duckBitmap = load(R.drawable.duck)

    val foxRight: List<ImageBitmap> = foxWalk.map { it.asImageBitmap() }
    val foxLeft: List<ImageBitmap> = foxWalk.map { flipped(it).asImageBitmap() }
    val foxSleep: ImageBitmap = load(R.drawable.fox_sleep).asImageBitmap()
    val duckRight: ImageBitmap = duckBitmap.asImageBitmap()
    val duckLeft: ImageBitmap = flipped(duckBitmap).asImageBitmap()
    val birdRight: List<ImageBitmap> = birdFly.map { it.asImageBitmap() }
    val birdLeft: List<ImageBitmap> = birdFly.map { flipped(it).asImageBitmap() }
    val bush: ImageBitmap = load(R.drawable.bush).asImageBitmap()
    val bushBlink: ImageBitmap = load(R.drawable.bush_blink).asImageBitmap()
    val bench: ImageBitmap = load(R.drawable.bench).asImageBitmap()
    val lamppost: ImageBitmap = load(R.drawable.lamppost).asImageBitmap()
    val gear: ImageBitmap = load(R.drawable.ui_gear).asImageBitmap()
}
