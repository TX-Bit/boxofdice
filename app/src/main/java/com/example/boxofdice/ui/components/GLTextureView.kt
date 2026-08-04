package com.example.boxofdice.ui.components

import android.content.Context
import android.graphics.SurfaceTexture
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLSurfaceView
import android.view.TextureView

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

    fun resize(width: Int, height: Int) {
        this.width = width
        this.height = height
        sizeDirty = true
    }

    fun quitAndJoin() {
        running = false
        // The loop is vsync-paced, so this returns within a frame or two. The join
        // matters: the SurfaceTexture must not be released before EGL lets go of it.
        join(2_000)
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
            while (running) {
                if (sizeDirty) {
                    renderer.onSurfaceChanged(null, width, height)
                    sizeDirty = false
                }
                renderer.onDrawFrame(null)
                // Paces the loop to vsync, and fails once the surface goes away.
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
