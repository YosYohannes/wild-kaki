package app.wildkaki

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.viewmodel.compose.viewModel
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
        )
        setContent {
            WildTheme {
                var devTools by remember { mutableStateOf(false) }
                BackHandler(devTools) { devTools = false }
                if (devTools) {
                    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) { SyncScreen() }
                } else {
                    var home by remember { mutableStateOf(MockData.home()) }
                    var refreshing by remember { mutableStateOf(false) }
                    val scope = rememberCoroutineScope()
                    SceneScreen(
                        home = home,
                        refreshing = refreshing,
                        onRefresh = {
                            scope.launch {
                                refreshing = true
                                delay(1200)
                                home = home.copy(lastSynced = Instant.now())
                                refreshing = false
                            }
                        },
                        onReveal = { outing ->
                            home = home.copy(
                                waiting = home.waiting - outing,
                                sightings = listOf(Sighting(outing, Buddy.NAME)) + home.sightings,
                            )
                        },
                        onDevTools = if (BuildConfig.DEBUG) ({ devTools = true }) else null,
                    )
                }
            }
        }
    }
}

private val DATE_FORMAT = DateTimeFormatter.ofPattern("EEE d MMM, HH:mm", Locale.getDefault())
    .withZone(ZoneId.systemDefault())

@Composable
private fun SyncScreen(vm: SyncViewModel = viewModel()) {
    val permissions = rememberLauncherForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { vm.onPermissionResult(it) }

    LazyColumn(
        modifier = Modifier.fillMaxSize().safeDrawingPadding().padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item { Text("WildKaki", style = MaterialTheme.typography.headlineMedium) }
        item { Text("Today's buddy: ${Buddy.NAME}", style = MaterialTheme.typography.titleMedium) }
        item {
            Button(
                onClick = { vm.onSyncClicked { permissions.launch(it) } },
                enabled = vm.available && !vm.busy,
                modifier = Modifier.fillMaxWidth(),
            ) { Text(if (vm.busy) "Working…" else "Sync from Health Connect") }
        }
        if (BuildConfig.DEBUG) {
            item {
                OutlinedButton(
                    onClick = { vm.onSeedClicked { permissions.launch(it) } },
                    enabled = vm.available && !vm.busy,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Debug: write a fake run") }
            }
            item {
                OutlinedButton(
                    onClick = { vm.onInventoryClicked { permissions.launch(it) } },
                    enabled = vm.available && !vm.busy,
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Debug: what's in Health Connect") }
            }
        }
        vm.report?.let { item { Text(it, style = MaterialTheme.typography.bodySmall) } }
        vm.message?.let { item { Text(it, style = MaterialTheme.typography.bodyMedium) } }
        vm.lastSync?.let {
            item { Text("Last sync: ${DATE_FORMAT.format(it)}", style = MaterialTheme.typography.bodySmall) }
        }
        items(vm.rows, key = { it.session.id }) { SessionCard(it) }
    }
}

@Composable
private fun SessionCard(row: SessionRow) {
    val session = row.session
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text(DATE_FORMAT.format(session.start), style = MaterialTheme.typography.titleSmall)
                Text(if (row.isNew) "NEW · ${Buddy.forSession(session)}" else Buddy.forSession(session))
            }
            Text(details(session), style = MaterialTheme.typography.bodyMedium)
            Text("from ${session.source}", style = MaterialTheme.typography.bodySmall)
        }
    }
}

private fun details(session: SyncedSession): String {
    val minutes = Duration.between(session.start, session.end).toMinutes()
    val parts = mutableListOf(session.type)
    session.distanceM?.let { parts += String.format(Locale.US, "%.2f km", it / 1000) }
    parts += "$minutes min"
    session.avgHeartRate?.let { parts += "$it bpm avg" }
    session.elevationGainM?.let { parts += String.format(Locale.US, "+%.0f m", it) }
    return parts.joinToString(" · ")
}
