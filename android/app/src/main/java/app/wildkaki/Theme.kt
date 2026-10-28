package app.wildkaki

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight

object Wild {
    val Night = Color(0xFF0F2119)
    val Forest = Color(0xFF1F3A2E)
    val Moss = Color(0xFF4F6F4A)
    val Fern = Color(0xFF8FAE74)
    val Parchment = Color(0xFFF3ECDC)
    val Paper = Color(0xFFE9DFC8)
    val Bark = Color(0xFF5B4636)
    val Ember = Color(0xFFC8672B)
    val Ink = Color(0xFF2A2A22)
}

@OptIn(androidx.compose.ui.text.ExperimentalTextApi::class)
val PixelFont = FontFamily(
    Font(R.font.pixelify_sans, FontWeight.Medium, variationSettings = FontVariation.Settings(FontVariation.weight(500))),
    Font(R.font.pixelify_sans, FontWeight.SemiBold, variationSettings = FontVariation.Settings(FontVariation.weight(600))),
)

@Composable
fun WildTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = Wild.Forest,
            onPrimary = Wild.Parchment,
            secondary = Wild.Ember,
            background = Wild.Parchment,
            onBackground = Wild.Ink,
            surface = Wild.Paper,
            onSurface = Wild.Ink,
        ),
        content = content,
    )
}
