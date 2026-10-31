package app.wildkaki

import android.os.Handler
import android.util.Log
import android.os.Looper
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.Calendar

private const val PEEK_EVERY = 10 * 60 * 1000L
private const val TAG = "WildWallpaper"

class WildWallpaperService : WallpaperService() {
    override fun onCreateEngine(): Engine = SceneEngine()

    private inner class SceneEngine : Engine() {
        private val handler = Handler(Looper.getMainLooper())
        private val tick = Runnable { frame() }
        private var scene: WallpaperScene? = null
        private var visible = false
        private var width = 0
        private var height = 0
        private var last = 0L
        private var checked = 0L
        private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        private var peeking = false
        private var peekedAt = 0L
        private var peekCount: Int? = null
        private var peekTime = 0L

        override fun onCreate(holder: SurfaceHolder) {
            super.onCreate(holder)
            setTouchEventsEnabled(false)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, w: Int, h: Int) {
            super.onSurfaceChanged(holder, format, w, h)
            width = w
            height = h
            if (visible) frame()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            handler.removeCallbacks(tick)
            if (visible) {
                last = SystemClock.uptimeMillis()
                reload(force = true)
                frame()
            }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            visible = false
            handler.removeCallbacks(tick)
            super.onSurfaceDestroyed(holder)
        }

        override fun onDestroy() {
            handler.removeCallbacks(tick)
            scope.cancel()
            scene?.release()
            scene = null
            super.onDestroy()
        }

        private fun reload(force: Boolean) {
            val now = SystemClock.uptimeMillis()
            if (!force && now - checked < 20_000) return
            checked = now
            val dir = File(filesDir, "wallpaper")
            val file = File(dir, "manifest.json")
            if (!file.exists()) {
                Log.w(TAG, "no manifest at ${file.path}")
                return
            }
            if (scene?.stamp == file.lastModified()) return
            try {
                val next = WallpaperScene(assets, dir)
                scene?.release()
                scene = next
                applyPeek()
            } catch (e: Exception) {
                Log.w(TAG, "could not load the scene", e)
                return
            }
            Log.i(TAG, "scene loaded")
        }

        private fun applyPeek() {
            val s = scene ?: return
            val count = peekCount
            s.waitingOverride = if (count != null && peekTime > s.manifest.writtenAt) count else null
        }

        private fun peekSometimes() {
            val now = SystemClock.uptimeMillis()
            if (peeking || now - peekedAt < PEEK_EVERY) return
            peeking = true
            peekedAt = now
            scope.launch {
                val count = withContext(Dispatchers.IO) { HealthPeek.waiting(applicationContext) }
                peeking = false
                if (count != null) {
                    peekCount = count
                    peekTime = System.currentTimeMillis()
                    applyPeek()
                }
            }
        }

        private fun drawWaiting(canvas: android.graphics.Canvas) {
            canvas.drawColor(0xFF0F2119.toInt())
            val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFF3ECDC.toInt()
                textAlign = android.graphics.Paint.Align.CENTER
                textSize = canvas.width * 0.045f
            }
            canvas.drawText("Open WildKaki once to fill the park", canvas.width / 2f, canvas.height / 2f, paint)
        }

        private fun hour(): Double {
            val c = Calendar.getInstance()
            return c.get(Calendar.HOUR_OF_DAY) + c.get(Calendar.MINUTE) / 60.0 + c.get(Calendar.SECOND) / 3600.0
        }

        private fun frame() {
            handler.removeCallbacks(tick)
            if (!visible) return
            reload(force = false)
            peekSometimes()
            val now = SystemClock.uptimeMillis()
            val dt = ((now - last) / 1000.0).coerceIn(0.0, 0.1)
            last = now
            val current = scene
            current?.step(dt)
            val holder = surfaceHolder
            val canvas = try {
                holder.lockCanvas()
            } catch (e: Exception) {
                null
            }
            if (canvas != null) {
                try {
                    if (current != null) {
                        current.draw(canvas, canvas.width, canvas.height, hour())
                    } else {
                        drawWaiting(canvas)
                    }
                } finally {
                    holder.unlockCanvasAndPost(canvas)
                }
            }
            handler.postDelayed(tick, if (current?.animate == false) 60_000L else 50L)
        }
    }
}
