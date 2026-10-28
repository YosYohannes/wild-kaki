package app.wildkaki

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.health.connect.client.HealthConnectClient
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch
import java.time.Instant

data class SessionRow(val session: SyncedSession, val isNew: Boolean)

private enum class Pending { SEED, INVENTORY }

class SyncViewModel(app: Application) : AndroidViewModel(app) {
    private val prefs = app.getSharedPreferences("sync", Context.MODE_PRIVATE)
    private val sdkStatus = HealthConnectClient.getSdkStatus(app)
    private val sync =
        if (sdkStatus == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectSync(HealthConnectClient.getOrCreate(app))
        } else {
            null
        }
    private val client get() = HealthConnectClient.getOrCreate(getApplication<Application>())
    private var pending: Pending? = null

    var rows by mutableStateOf<List<SessionRow>>(emptyList())
        private set
    var message by mutableStateOf<String?>(null)
        private set
    var busy by mutableStateOf(false)
        private set
    var lastSync by mutableStateOf<Instant?>(null)
        private set
    var report by mutableStateOf<String?>(null)
        private set

    val available get() = sync != null

    init {
        message = when (sdkStatus) {
            HealthConnectClient.SDK_AVAILABLE -> null
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED ->
                "Health Connect needs an update from the Play Store."
            else -> "Health Connect is not available on this device."
        }
    }

    fun onSyncClicked(requestPermissions: (Set<String>) -> Unit) {
        val sync = sync ?: return
        viewModelScope.launch {
            if (sync.hasAccess()) runSync() else requestPermissions(READ_PERMISSIONS)
        }
    }

    fun onInventoryClicked(requestPermissions: (Set<String>) -> Unit) {
        viewModelScope.launch {
            if (client.permissionController.getGrantedPermissions().containsAll(INVENTORY_PERMISSIONS)) {
                showInventory()
            } else {
                pending = Pending.INVENTORY
                requestPermissions(INVENTORY_PERMISSIONS)
            }
        }
    }

    fun onSeedClicked(requestPermissions: (Set<String>) -> Unit) {
        viewModelScope.launch {
            if (client.permissionController.getGrantedPermissions().containsAll(FakeFitbit.WRITE_PERMISSIONS)) {
                seedFakeRun()
            } else {
                pending = Pending.SEED
                requestPermissions(FakeFitbit.WRITE_PERMISSIONS)
            }
        }
    }

    fun onPermissionResult(granted: Set<String>) {
        val action = pending
        pending = null
        when (action) {
            Pending.SEED ->
                if (granted.containsAll(FakeFitbit.WRITE_PERMISSIONS)) seedFakeRun() else message = "Write permission denied."
            Pending.INVENTORY -> showInventory()
            null ->
                if (granted.containsAll(READ_PERMISSIONS)) {
                    viewModelScope.launch { runSync() }
                } else {
                    message = "Permission denied. Sync needs read access to exercise, distance, heart rate and elevation."
                }
        }
    }

    private fun showInventory() {
        val sync = sync ?: return
        viewModelScope.launch {
            busy = true
            report = runCatching { sync.inventory() }.getOrElse { "Report failed: ${it.message}" }
            Log.i("WildKaki", "inventory\n$report")
            busy = false
        }
    }

    private fun seedFakeRun() {
        viewModelScope.launch {
            busy = true
            runCatching { FakeFitbit.seedRun(client) }
                .onSuccess { message = "Wrote a fake run to Health Connect. Press Sync to read it." }
                .onFailure { message = "Seeding failed: ${it.message}" }
            busy = false
        }
    }

    private suspend fun runSync() {
        val sync = sync ?: return
        busy = true
        runCatching { sync.recentSessions() }
            .onSuccess { sessions ->
                val seen = prefs.getStringSet(SEEN_KEY, emptySet()).orEmpty()
                rows = sessions.map { SessionRow(it, it.id !in seen) }
                prefs.edit().putStringSet(SEEN_KEY, seen + sessions.map { it.id }).apply()
                lastSync = Instant.now()
                val fresh = rows.count { it.isNew }
                message = if (sessions.isEmpty()) {
                    "No exercise sessions found."
                } else {
                    "Synced ${sessions.size} sessions, $fresh new."
                }
            }
            .onFailure { message = "Sync failed: ${it.message}" }
        busy = false
    }

    private companion object {
        const val SEEN_KEY = "seen_run_ids"
    }
}
