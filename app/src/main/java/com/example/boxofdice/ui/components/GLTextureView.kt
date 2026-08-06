package com.example.boxofdice.ui.components

import android.content.Context
import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLSurface
import android.opengl.GLSurfaceView
import android.view.TextureView

/**
 * A renderer that knows when it has nothing left to animate, so the host can stop
 * feeding it frames instead of spinning the GPU — and the window's compositor — forever.
 */
internal interface OnDemandRenderer : GLSurfaceView.Renderer {
    /** True while the scene is still moving and needs another frame after this one. */
    val isAnimating: Boolean

    /** Clock for the frame about to be drawn, in the `System.nanoTime()` timebase. */
    fun onFrameTime(nanos: Long)
}

/**
 * A [TextureView] that drives a [GLSurfaceView.Renderer] on its own EGL thread.
 *
 * [GLSurfaceView] cannot be used for the dice. A SurfaceView owns a separate window
 * layer, which leaves only two bad options: leave it behind the app window, where the
 * opaque felt hides it completely, or `setZOrderOnTop(true)` and have it paint over
 * *everything* — overlays, sheets, and whatever screen replaces the board. The latter
 * is what the app did, and it showed: the dice punched through the menu, and after an
 * Activity recreation the stale layer covered the whole window black until the next
 * relaunch.
 *
 * A TextureView is an ordinary view drawn into the window, so it composites in normal
 * z-order with the Compose content around it and disappears with it. The cost is one
 * extra copy per frame, which is immaterial for a row of dice.
 *
 * The loop draws only while an [OnDemandRenderer] reports something left to animate,
 * and blocks on [lock] otherwise. That matters more here than for a normal GL view:
 * a TextureView frame invalidates the Compose owner, which damages the *whole window*,
 * so every dice frame costs a full redraw of the felt, the tray and every tile. Left
 * free-running, still dice were buying that redraw sixty times a second forever.
 *
 * The [GLSurfaceView.Renderer] contract is reused as-is so [DiceGLRenderer] needs no
 * changes; the `GL10`/`EGLConfig` arguments of that interface belong to the old EGL 1.0
 * Java bindings and are passed as null, exactly as they are ignored by the renderer.
 */
internal class GLTextureView(context: Context) : TextureView(context), TextureView.SurfaceTextureListener {

    /** Set once, before the view is attached. */
    var renderer: GLSurfaceView.Renderer? = null

    private var thread: RenderThread? = null

    init {
        // The renderer clears to a fully transparent colour; without this the view
        // would be composited as opaque black.
        isOpaque = false
        surfaceTextureListener = this
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        val r = renderer ?: return
        thread = RenderThread(surface, r, width, height).also { it.start() }
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        thread?.resize(width, height)
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        // Returning true means we take responsibility for releasing the texture, which
        // the render thread does once it has torn its EGL surface down.
        stop()
        return true
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) = Unit

    /**
     * Wakes the render thread for at least one more frame. Required after anything that
     * changes what the renderer would draw, because an idle renderer is not being
     * polled.
     */
    fun requestRender() {
        thread?.requestRender()
    }

    /** Stops the render thread and blocks until it has released its EGL resources. */
    fun stop() {
        thread?.quitAndJoin()
        thread = null
    }
}

private class RenderThread(
    private val surfaceTexture: SurfaceTexture,
    private val renderer:       GLSurfaceView.Renderer,
    width:  Int,
    height: Int
) : Thread("DiceGL") {

    @Volatile private var running = true
    @Volatile private var width = width
    @Volatile private var height = height
    @Volatile private var sizeDirty = true

    /** Guards the idle wait; every wake-up condition is published under it. */
    private val lock = Object()

    /** Forces at least one more frame regardless of what the renderer reports. */
    private var wakeUp = true

    fun resize(width: Int, height: Int) {
        this.width = width
        this.height = height
        sizeDirty = true
        requestRender()
    }

    fun requestRender() {
        synchronized(lock) {
            wakeUp = true
            lock.notifyAll()
        }
    }

    fun quitAndJoin() {
        running = false
        // Wake an idle thread so it can notice `running` and unwind, instead of waiting
        // out the two seconds below. The join matters: the SurfaceTexture must not be
        // released before EGL lets go of it.
        requestRender()
        join(2_000)
    }

    /** Blocks until there is something to draw. Returns false when the thread is done. */
    private fun awaitFrame(): Boolean {
        val onDemand = renderer as? OnDemandRenderer ?: return running
        synchronized(lock) {
            while (running && !wakeUp && !onDemand.isAnimating) {
                // No timeout: every state change that affects the scene goes through
                // requestRender(), so a missed wake-up would be a bug, not a stall to
                // paper over with polling.
                lock.wait()
            }
            wakeUp = false
        }
        return running
    }

    override fun run() {
        val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        if (display == EGL14.EGL_NO_DISPLAY) return
        val version = IntArray(2)
        if (!EGL14.eglInitialize(display, version, 0, version, 1)) return

        var context: EGLContext = EGL14.EGL_NO_CONTEXT
        var surface: EGLSurface = EGL14.EGL_NO_SURFACE
        try {
            // 8-bit alpha is what lets the felt show through the transparent pixels
            // around the cubes; 16-bit depth is what the renderer's GL_DEPTH_TEST needs.
            val configAttribs = intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE,   8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE,  8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_DEPTH_SIZE, 16,
                EGL14.EGL_NONE
            )
            val configs = arrayOfNulls<EGLConfig>(1)
            val configCount = IntArray(1)
            if (!EGL14.eglChooseConfig(display, configAttribs, 0, configs, 0, 1, configCount, 0) ||
                configCount[0] == 0
            ) return
            val config = configs[0] ?: return

            context = EGL14.eglCreateContext(
                display, config, EGL14.EGL_NO_CONTEXT,
                intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE), 0
            )
            if (context == EGL14.EGL_NO_CONTEXT) return

            surface = EGL14.eglCreateWindowSurface(
                display, config, surfaceTexture, intArrayOf(EGL14.EGL_NONE), 0
            )
            if (surface == EGL14.EGL_NO_SURFACE) return
            if (!EGL14.eglMakeCurrent(display, surface, surface, context)) return

            renderer.onSurfaceCreated(null, null)
            val onDemand = renderer as? OnDemandRenderer
            while (awaitFrame()) {
                if (sizeDirty) {
                    renderer.onSurfaceChanged(null, width, height)
                    sizeDirty = false
                }
                onDemand?.onFrameTime(System.nanoTime())
                renderer.onDrawFrame(null)
                // Paces the loop to the consumer, and fails once the surface goes away.
                if (!EGL14.eglSwapBuffers(display, surface)) break
            }
        } finally {
            EGL14.eglMakeCurrent(
                display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT
            )
            if (surface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, surface)
            if (context != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, context)
            EGL14.eglTerminate(display)
            surfaceTexture.release()
        }
    }
}
