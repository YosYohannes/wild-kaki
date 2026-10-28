package app.wildkaki

import android.provider.Settings
import android.text.format.DateUtils
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.gestures.detectTapGestures
import kotlinx.coroutines.delay
import java.time.Instant
import kotlin.math.ceil
import kotlin.math.roundToInt
import kotlin.math.sin

private enum class ScenePage { Scene, Collection, Settings }

private fun DrawScope.sprite(img: ImageBitmap, x: Int, y: Int, s: Float, filter: ColorFilter? = null) {
    val x0 = (x * s).roundToInt()
    val y0 = (y * s).roundToInt()
    drawImage(
        img,
        srcOffset = IntOffset.Zero,
        srcSize = IntSize(img.width, img.height),
        dstOffset = IntOffset(x0, y0),
        dstSize = IntSize(((x + img.width) * s).roundToInt() - x0, ((y + img.height) * s).roundToInt() - y0),
        filterQuality = FilterQuality.None,
        colorFilter = filter,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SceneScreen(
    home: HomeState,
    refreshing: Boolean,
    onRefresh: () -> Unit,
    onReveal: (Outing) -> Unit,
    onDevTools: (() -> Unit)?,
) {
    val context = LocalContext.current
    val sprites = remember { SceneSprites(context) }
    val world = remember { SceneState() }

    var hour by remember { mutableFloatStateOf(currentHour()) }
    LaunchedEffect(Unit) { while (true) { delay(60_000); hour = currentHour() } }
    val sky = skyAt(hour)
    val night by rememberUpdatedState(sky.stars)

    val systemMotion = remember { Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) != 0f }
    var motion by remember { mutableStateOf(systemMotion) }
    val motionNow by rememberUpdatedState(motion)

    var tick by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        var last = withFrameNanos { it }
        while (true) {
            val now = withFrameNanos { it }
            val dt = ((now - last) / 1_000_000_000f).coerceAtMost(0.05f)
            last = now
            world.step(dt, motionNow, night)
            tick++
        }
    }

    val bushes = remember(home.waiting.map { it.id }) { placeBushes(home.waiting.take(2).map { it.id }) }
    var page by remember { mutableStateOf(ScenePage.Scene) }
    var revealing by remember { mutableStateOf<Outing?>(null) }
    var showFox by remember { mutableStateOf(false) }

    PullToRefreshBox(isRefreshing = refreshing, onRefresh = onRefresh, modifier = Modifier.fillMaxSize()) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val widthPx = with(LocalDensity.current) { maxWidth.toPx() }
            val heightPx = with(LocalDensity.current) { maxHeight.toPx() }
            val boxHeight = maxHeight
            val scale = widthPx / WORLD_W
            val rows = ceil(heightPx / scale).toInt()
            val worldImage = remember(hour.times(12f).toInt(), rows) { paintWorld(hour, rows) }

            Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                Canvas(
                    Modifier
                        .fillMaxWidth()
                        .height(boxHeight)
                        .pointerInput(bushes, home.waiting) {
                            detectTapGestures { tap ->
                                val s = size.width / WORLD_W.toFloat()
                                val px = tap.x / s
                                val py = tap.y / s
                                val fox = world.foxes.firstOrNull { it.hit(px, py) }
                                val bush = bushes.firstOrNull { px >= it.x - 1 && px < it.x + 25 && py >= it.base - 21 && py < it.base + 1 }
                                when {
                                    fox != null -> showFox = true
                                    bush != null -> revealing = home.waiting.firstOrNull { it.id == bush.id }
                                    px >= 12 && px < 48 && py >= 107 && py < 130 -> page = ScenePage.Collection
                                    BuildConfig.DEBUG && py < Layout.GROUND -> hour = (hour + 3f) % 24f
                                }
                            }
                        },
                ) {
                    tick
                    val s = size.width / WORLD_W
                    drawImage(
                        worldImage,
                        srcOffset = IntOffset.Zero,
                        srcSize = IntSize(worldImage.width, worldImage.height),
                        dstOffset = IntOffset.Zero,
                        dstSize = IntSize(size.width.roundToInt(), (worldImage.height * s).roundToInt()),
                        filterQuality = FilterQuality.None,
                    )
                    val dim = if (night > 0.01f) ColorFilter.tint(Color(0xFF0B1510).copy(alpha = night * 0.55f), BlendMode.SrcAtop) else null
                    sprite(sprites.bench, Layout.BENCH_X, Layout.BENCH_Y, s, dim)
                    sprite(sprites.lamppost, Layout.LAMP_X, Layout.LAMP_Y, s, dim)
                    if (night > 0.05f) {
                        drawRect(
                            Color(0xFFFFE9A0).copy(alpha = night),
                            Offset(4 * s, 92 * s),
                            androidx.compose.ui.geometry.Size(6 * s, 6 * s),
                        )
                    }
                    world.birds.filter { it.active }.forEach { b ->
                        sprite((if (b.dir > 0) sprites.birdRight else sprites.birdLeft)[b.frame], b.x.roundToInt(), b.y.roundToInt(), s)
                    }

                    class Item(val feet: Int, val draw: () -> Unit)
                    val items = mutableListOf<Item>()
                    val blink = motion && (world.clock % 3.2f) > 3.0f
                    bushes.forEach { b ->
                        items += Item(b.base) {
                            val rustle = if (motion && ((world.clock + b.x * 0.03f) % 5f) < 0.45f) (if ((world.clock * 24f).toInt() % 2 == 1) 1 else -1) else 0
                            sprite(if (blink) sprites.bushBlink else sprites.bush, b.x - 5 + rustle, b.base - 32, s)
                        }
                    }
                    val breathe = if (motion && (world.clock % 2.4f) > 1.2f) 1 else 0
                    items += Item(world.sleeperFeet) { sprite(sprites.foxSleep, world.sleeperX, world.sleeperFeet - 32 + breathe, s) }
                    world.ducks.forEach { d ->
                        items += Item(d.feet) {
                            val bob = if (motion && d.moving && ((world.clock * 1.5f + d.x) % 2f) > 1f) 1 else 0
                            sprite(if (d.dir > 0) sprites.duckRight else sprites.duckLeft, d.x.roundToInt() - 8, d.feet - 32 + bob, s)
                        }
                    }
                    world.foxes.forEach { f ->
                        items += Item(f.feet) { sprite((if (f.dir > 0) sprites.foxRight else sprites.foxLeft)[f.frame], f.x.roundToInt(), f.feet - 32, s) }
                    }
                    items.sortedBy { it.feet }.forEach { it.draw() }
                }
            }
        }

        home.lastSynced?.let {
            val ago = DateUtils.getRelativeTimeSpanString(it.toEpochMilli(), System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS)
            Text(
                "synced $ago",
                modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(top = 8.dp, end = 20.dp),
                style = TextStyle(fontFamily = PixelFont, fontWeight = FontWeight.Medium, fontSize = 11.sp, color = Wild.Fern),
            )
        }

        when (page) {
            ScenePage.Collection -> CollectionPage(
                sprites = sprites,
                foxFound = home.sightings.any { it.animal == Buddy.NAME },
                onSettings = { page = ScenePage.Settings },
                onClose = { page = ScenePage.Scene },
            )
            ScenePage.Settings -> SettingsPage(
                motion = motion,
                onMotion = { motion = it },
                onBack = { page = ScenePage.Collection },
                onDevTools = onDevTools,
            )
            ScenePage.Scene -> Unit
        }

        revealing?.let { outing ->
            AnimalSheet(
                sprites = sprites,
                title = "Fox joined your ${outing.type.label.lowercase()}",
                note = "Trotted beside you for the last ten minutes, then wandered off.",
                meta = outingMeta(outing),
                button = "Nice",
                onDone = {
                    world.addFox(bushes.firstOrNull { it.id == outing.id }?.x?.toFloat() ?: 40f)
                    revealing = null
                    onReveal(outing)
                },
            )
        }
        if (showFox) {
            AnimalSheet(
                sprites = sprites,
                title = "Fox",
                note = "A fox trotted beside you for the last ten minutes, then wandered off.",
                meta = "Met ${home.sightings.count { it.animal == Buddy.NAME }} times",
                button = "Close",
                onDone = { showFox = false },
            )
        }
    }
}
