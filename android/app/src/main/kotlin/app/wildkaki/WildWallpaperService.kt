package app.wildkaki

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import java.io.File
import java.util.Calendar

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
            if (!file.exists()) return
            if (scene?.stamp == file.lastModified()) return
            try {
                val next = WallpaperScene(assets, dir)
                scene?.release()
                scene = next
            } catch (e: Exception) {
                return
            }
        }

        private fun hour(): Double {
            val c = Calendar.getInstance()
            return c.get(Calendar.HOUR_OF_DAY) + c.get(Calendar.MINUTE) / 60.0 + c.get(Calendar.SECOND) / 3600.0
        }

        private fun frame() {
            handler.removeCallbacks(tick)
            if (!visible) return
            reload(force = false)
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
                    current?.draw(canvas, canvas.width, canvas.height, hour())
                        ?: canvas.drawColor(0xFF0F2119.toInt())
                } finally {
                    holder.unlockCanvasAndPost(canvas)
                }
            }
            handler.postDelayed(tick, if (current?.animate == false) 60_000L else 50L)
        }
    }
}
