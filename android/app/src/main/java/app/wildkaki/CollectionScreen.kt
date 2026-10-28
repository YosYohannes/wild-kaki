package app.wildkaki

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale

private fun pixelText(size: Int, color: Color = Wild.Ink, weight: FontWeight = FontWeight.SemiBold) =
    TextStyle(fontFamily = PixelFont, fontWeight = weight, fontSize = size.sp, color = color)

fun outingMeta(outing: Outing): String {
    val parts = mutableListOf(outing.type.label)
    outing.distanceKm?.let { parts += String.format(Locale.US, "%.1f km", it) }
    parts += "${outing.minutes} min"
    return parts.joinToString(" · ")
}

private class Entry(val name: String, val found: Boolean)

@Composable
fun CollectionPage(sprites: SceneSprites, foxFound: Boolean, onSettings: () -> Unit, onClose: () -> Unit) {
    val entries = remember(foxFound) { listOf(Entry("Fox", foxFound)) + List(17) { Entry("???", false) } }
    Box(Modifier.fillMaxSize().background(Wild.Parchment)) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
                Image(
                    sprites.gear, "Settings",
                    Modifier.clickable(onClick = onSettings).padding(6.dp).size(26.dp),
                    filterQuality = FilterQuality.None,
                )
                Text("x", Modifier.clickable(onClick = onClose).padding(horizontal = 14.dp, vertical = 6.dp), style = pixelText(20, Wild.Bark))
            }
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                modifier = Modifier.weight(1f).padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                items(entries) { e ->
                    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                        if (e.found) {
                            Image(sprites.foxRight[0], e.name, Modifier.size(96.dp), filterQuality = FilterQuality.None, contentScale = ContentScale.Fit)
                        } else {
                            Box(Modifier.size(96.dp), contentAlignment = Alignment.BottomCenter) {
                                Text("?", Modifier.padding(bottom = 14.dp), style = pixelText(26, Wild.Bark.copy(alpha = 0.3f)))
                            }
                        }
                        Text(
                            e.name,
                            textAlign = TextAlign.Center,
                            style = pixelText(14, if (e.found) Wild.Ink else Wild.Bark.copy(alpha = 0.45f)),
                        )
                    }
                }
                item(span = { androidx.compose.foundation.lazy.grid.GridItemSpan(3) }) { Box(Modifier.navigationBarsPadding().size(24.dp)) }
            }
        }
    }
}

@Composable
fun SettingsPage(motion: Boolean, onMotion: (Boolean) -> Unit, onBack: () -> Unit, onDevTools: (() -> Unit)?) {
    var counts by remember { mutableStateOf(setOf("Run", "Walk", "Climb", "Sleep")) }
    Box(Modifier.fillMaxSize().background(Wild.Parchment)) {
        Column(Modifier.fillMaxSize().statusBarsPadding().padding(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("< Back", Modifier.clickable(onClick = onBack).padding(vertical = 8.dp), style = pixelText(16, Wild.Bark))
            Text("Settings", style = pixelText(24, Wild.Forest))
            Text("Health Connect is connected.", style = TextStyle(fontSize = 14.sp, color = Wild.Bark))
            Text("What counts as an outing", style = pixelText(16, Wild.Forest))
            listOf("Run", "Walk", "Climb", "Sleep").forEach { name ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text(name, style = TextStyle(fontSize = 16.sp, color = Wild.Ink))
                    Checkbox(
                        checked = name in counts,
                        onCheckedChange = { on -> counts = if (on) counts + name else counts - name },
                        colors = CheckboxDefaults.colors(checkedColor = Wild.Ember),
                    )
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("Distance units", style = TextStyle(fontSize = 16.sp, color = Wild.Ink))
                Text("km", style = TextStyle(fontSize = 16.sp, color = Wild.Bark))
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("Animate the scene", style = TextStyle(fontSize = 16.sp, color = Wild.Ink))
                Checkbox(checked = motion, onCheckedChange = onMotion, colors = CheckboxDefaults.colors(checkedColor = Wild.Ember))
            }
            if (onDevTools != null) {
                Text("Developer tools", Modifier.clickable(onClick = onDevTools).padding(vertical = 14.dp), style = pixelText(16, Wild.Ember))
            }
        }
    }
}

@Composable
fun AnimalSheet(sprites: SceneSprites, title: String, note: String, meta: String, button: String, onDone: () -> Unit) {
    Box(Modifier.fillMaxSize().background(Color(0x66000000)).clickable(onClick = onDone), contentAlignment = Alignment.BottomCenter) {
        Column(
            Modifier
                .navigationBarsPadding()
                .padding(16.dp)
                .background(Wild.Parchment)
                .border(BorderStroke(3.dp, Color(0xFF2E2218)))
                .clickable(enabled = false) {}
                .padding(18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(title, style = pixelText(22, Wild.Forest), textAlign = TextAlign.Center)
            Image(sprites.foxRight[0], title, Modifier.size(128.dp), filterQuality = FilterQuality.None)
            Text(note, style = TextStyle(fontSize = 15.sp, color = Wild.Ink, fontStyle = androidx.compose.ui.text.font.FontStyle.Italic), textAlign = TextAlign.Center)
            Text(meta, style = TextStyle(fontSize = 13.sp, color = Wild.Bark))
            Text(
                button,
                Modifier.background(Wild.Ember).clickable(onClick = onDone).padding(horizontal = 24.dp, vertical = 8.dp),
                style = pixelText(16, Wild.Parchment),
            )
        }
    }
}
