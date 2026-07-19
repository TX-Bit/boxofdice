package com.example.boxofdice.ui.components

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color as AndroidColor
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.Shader
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.GLUtils
import android.opengl.Matrix
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.ShortBuffer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.sqrt
import kotlin.random.Random

/**
 * Real 3D dice rendered with OpenGL ES 2.0 (genuine perspective-projected rotating
 * cubes), as a translucent [GLSurfaceView] hosted in Compose. Each cube's six faces
 * carry runtime-drawn pip textures (1–6) packed into a single atlas, so no binary
 * model or texture asset is required.
 *
 * Public surface mirrors [DiceView] so it is a drop-in replacement:
 *  - while [dice] are rolling the cubes tumble continuously,
 *  - when rolling stops each cube settles, bringing the rolled value's face to camera.
 *
 * On-device verification notes: the per-value settle orientation signs ([faceTargets])
 * and the surface z-order ([GLSurfaceView.setZOrderOnTop]) are the two things to eyeball.
 */
@Composable
fun Dice3DView(
    dice:      List<Int>,
    isRolling: Boolean,
    modifier:  Modifier = Modifier,
    @Suppress("UNUSED_PARAMETER") dieSize: Dp = 108.dp
) {
    // dieSize is accepted only for signature parity with DiceView; the GL scene scales
    // the cubes to the surface, so the row fills whatever space it is given.
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            GLSurfaceView(ctx).apply {
                setEGLContextClientVersion(2)
                setEGLConfigChooser(8, 8, 8, 8, 16, 0)
                holder.setFormat(PixelFormat.TRANSLUCENT)
                setZOrderOnTop(true)
                val r = DiceGLRenderer()
                setRenderer(r)
                renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
                tag = r
            }
        },
        update = { view ->
            (view.tag as? DiceGLRenderer)?.update(dice, isRolling)
        }
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Renderer
// ─────────────────────────────────────────────────────────────────────────────

private class DiceGLRenderer : GLSurfaceView.Renderer {

    @Volatile private var values: IntArray = intArrayOf(1, 1)
    @Volatile private var rolling = false

    private var program = 0
    private var aPos = 0
    private var aUv = 0
    private var aNormal = 0
    private var uMvp = 0
    private var uModel = 0
    private var uLight = 0
    private var uTex = 0
    private var texId = 0

    private lateinit var posBuf: FloatBuffer
    private lateinit var uvBuf: FloatBuffer
    private lateinit var normBuf: FloatBuffer
    private lateinit var idxBuf: ShortBuffer
    private var indexCount = 0

    private val proj = FloatArray(16)
    private val view = FloatArray(16)
    private val model = FloatArray(16)
    private val mvp = FloatArray(16)
    private val tmp = FloatArray(16)

    // Per-die animation state (rotation in degrees about X and Y).
    private var rotX = FloatArray(2)
    private var rotY = FloatArray(2)
    private var velX = FloatArray(2)
    private var velY = FloatArray(2)
    private var startX = FloatArray(2)
    private var startY = FloatArray(2)
    private var targX = FloatArray(2)
    private var targY = FloatArray(2)
    private var settleT = FloatArray(2)   // 0..1 progress; <0 means "not settling"
    private var lastNanos = 0L
    private var wasRolling = false

    private val settleDuration = 0.55f

    fun update(newValues: List<Int>, isRolling: Boolean) {
        if (newValues.isNotEmpty()) {
            val v = IntArray(newValues.size) { newValues[it].coerceIn(1, 6) }
            ensureCapacity(v.size)
            values = v
        }
        rolling = isRolling
    }

    private fun ensureCapacity(n: Int) {
        if (rotX.size >= n) return
        rotX = rotX.copyOf(n); rotY = rotY.copyOf(n)
        velX = velX.copyOf(n); velY = velY.copyOf(n)
        startX = startX.copyOf(n); startY = startY.copyOf(n)
        targX = targX.copyOf(n); targY = targY.copyOf(n)
        settleT = settleT.copyOf(n)
    }

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 0f)
        GLES20.glEnable(GLES20.GL_DEPTH_TEST)
        GLES20.glEnable(GLES20.GL_BLEND)
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

        buildGeometry()
        program = buildProgram()
        aPos = GLES20.glGetAttribLocation(program, "aPos")
        aUv = GLES20.glGetAttribLocation(program, "aUv")
        aNormal = GLES20.glGetAttribLocation(program, "aNormal")
        uMvp = GLES20.glGetUniformLocation(program, "uMvp")
        uModel = GLES20.glGetUniformLocation(program, "uModel")
        uLight = GLES20.glGetUniformLocation(program, "uLight")
        uTex = GLES20.glGetUniformLocation(program, "uTex")
        texId = uploadTexture(buildPipAtlas())
        lastNanos = System.nanoTime()
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        GLES20.glViewport(0, 0, width, height)
        val aspect = width.toFloat() / height.coerceAtLeast(1)
        Matrix.perspectiveM(proj, 0, 30f, aspect, 1f, 20f)
        // View from slightly up and to the right so a settled die shows its value face
        // PLUS a sliver of the top and right faces — the 3D depth the iOS dice have at
        // rest, instead of a flat dead-on face. lookAt stays at the row centre so the
        // dice remain horizontally centred.
        Matrix.setLookAtM(view, 0, 0.85f, 1.0f, 3.9f, 0f, 0f, 0f, 0f, 1f, 0f)
    }

    override fun onDrawFrame(gl: GL10?) {
        val now = System.nanoTime()
        val dt = ((now - lastNanos) / 1_000_000_000.0).toFloat().coerceIn(0f, 0.05f)
        lastNanos = now
        step(dt)

        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        GLES20.glUseProgram(program)

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texId)
        GLES20.glUniform1i(uTex, 0)
        GLES20.glUniform3f(uLight, -0.35f, 0.55f, 0.75f)

        GLES20.glEnableVertexAttribArray(aPos)
        GLES20.glVertexAttribPointer(aPos, 3, GLES20.GL_FLOAT, false, 0, posBuf)
        GLES20.glEnableVertexAttribArray(aUv)
        GLES20.glVertexAttribPointer(aUv, 2, GLES20.GL_FLOAT, false, 0, uvBuf)
        GLES20.glEnableVertexAttribArray(aNormal)
        GLES20.glVertexAttribPointer(aNormal, 3, GLES20.GL_FLOAT, false, 0, normBuf)

        val n = values.size
        // Lay the dice out along X, centered, matching the iOS tight grouping.
        val spacing = 1.55f
        val x0 = -(n - 1) * spacing / 2f
        for (i in 0 until n) {
            Matrix.setIdentityM(model, 0)
            Matrix.translateM(model, 0, x0 + i * spacing, 0f, 0f)
            Matrix.rotateM(model, 0, rotX[i], 1f, 0f, 0f)
            Matrix.rotateM(model, 0, rotY[i], 0f, 1f, 0f)

            Matrix.multiplyMM(tmp, 0, view, 0, model, 0)
            Matrix.multiplyMM(mvp, 0, proj, 0, tmp, 0)
            GLES20.glUniformMatrix4fv(uMvp, 1, false, mvp, 0)
            GLES20.glUniformMatrix4fv(uModel, 1, false, model, 0)
            GLES20.glDrawElements(GLES20.GL_TRIANGLES, indexCount, GLES20.GL_UNSIGNED_SHORT, idxBuf)
        }

        GLES20.glDisableVertexAttribArray(aPos)
        GLES20.glDisableVertexAttribArray(aUv)
        GLES20.glDisableVertexAttribArray(aNormal)
    }

    private fun step(dt: Float) {
        val n = values.size
        ensureCapacity(n)
        if (rolling) {
            if (!wasRolling) {
                // Calm, coherent tumble: moderate speeds, both dice spin the same
                // general way so the group reads as a single throw rather than chaos.
                for (i in 0 until n) {
                    velX[i] = 210f + Random.nextFloat() * 60f
                    velY[i] = 240f + Random.nextFloat() * 60f
                    settleT[i] = -1f
                }
            }
            for (i in 0 until n) {
                rotX[i] += velX[i] * dt
                rotY[i] += velY[i] * dt
            }
        } else {
            if (wasRolling) {
                // Roll just ended — start a fixed-duration ease-out to the value face,
                // adding one full turn so it spins down smoothly instead of snapping.
                for (i in 0 until n) {
                    val (tx, ty) = faceTargets(values[i])
                    startX[i] = rotX[i]
                    startY[i] = rotY[i]
                    targX[i] = nearestEquivalent(rotX[i], tx) + 360f
                    targY[i] = nearestEquivalent(rotY[i], ty)
                    settleT[i] = 0f
                }
            }
            for (i in 0 until n) {
                if (settleT[i] in 0f..1f) {
                    settleT[i] = (settleT[i] + dt / settleDuration)
                    if (settleT[i] >= 1f) {
                        // Land exactly on the value face and stop animating.
                        settleT[i] = -1f
                        val (tx, ty) = faceTargets(values[i])
                        rotX[i] = tx
                        rotY[i] = ty
                    } else {
                        val e = easeOutCubic(settleT[i])
                        rotX[i] = startX[i] + (targX[i] - startX[i]) * e
                        rotY[i] = startY[i] + (targY[i] - startY[i]) * e
                    }
                } else {
                    // Idle / decorative dice sit statically on their value's face.
                    val (tx, ty) = faceTargets(values[i])
                    rotX[i] = tx
                    rotY[i] = ty
                }
            }
        }
        wasRolling = rolling
    }

    private fun easeOutCubic(t: Float): Float {
        val u = 1f - t
        return 1f - u * u * u
    }

    /** Degrees (rotX, rotY) that bring the given value's face toward the camera. */
    private fun faceTargets(value: Int): Pair<Float, Float> = when (value) {
        1 -> 0f to 0f       // +Z front
        2 -> 0f to -90f     // +X right
        3 -> -90f to 0f     // +Y top
        4 -> 90f to 0f      // -Y bottom
        5 -> 0f to 90f      // -X left
        else -> 0f to 180f  // 6 → -Z back
    }

    /** Returns target +k*360 closest to current, so the spring doesn't unwind turns. */
    private fun nearestEquivalent(current: Float, target: Float): Float {
        var t = target
        while (t - current > 180f) t -= 360f
        while (current - t > 180f) t += 360f
        return t
    }

    // ── Geometry ───────────────────────────────────────────────────────────────

    // A rounded die: each of the 6 faces is a subdivided grid whose vertices are
    // pushed onto a rounded-box surface (flat in the middle, smoothly rounded over
    // the edges/corners) with smooth outward normals — so the dice read as the
    // friendly rounded cubes the iOS app uses rather than sharp blocks.
    private fun buildGeometry() {
        val s = 0.60f            // half-size
        val r = 0.16f            // corner radius
        val inner = s - r
        val seg = 8              // subdivisions per face edge (smoothness)
        val cellW = 1f / 6f
        val inset = 0.012f

        // Each face: plane origin (at ±s) + in-plane axes (du, dv) + atlas cell.
        data class FaceDef(val o: FloatArray, val du: FloatArray, val dv: FloatArray, val cell: Int)
        val faces = listOf(
            FaceDef(floatArrayOf(0f, 0f, s), floatArrayOf(1f, 0f, 0f), floatArrayOf(0f, 1f, 0f), 0),  // +Z =1
            FaceDef(floatArrayOf(s, 0f, 0f), floatArrayOf(0f, 0f, -1f), floatArrayOf(0f, 1f, 0f), 1),  // +X =2
            FaceDef(floatArrayOf(0f, s, 0f), floatArrayOf(1f, 0f, 0f), floatArrayOf(0f, 0f, -1f), 2),  // +Y =3
            FaceDef(floatArrayOf(0f, -s, 0f), floatArrayOf(1f, 0f, 0f), floatArrayOf(0f, 0f, 1f), 3),  // -Y =4
            FaceDef(floatArrayOf(-s, 0f, 0f), floatArrayOf(0f, 0f, 1f), floatArrayOf(0f, 1f, 0f), 4),  // -X =5
            FaceDef(floatArrayOf(0f, 0f, -s), floatArrayOf(-1f, 0f, 0f), floatArrayOf(0f, 1f, 0f), 5)   // -Z =6
        )

        val pos = ArrayList<Float>()
        val uv = ArrayList<Float>()
        val nrm = ArrayList<Float>()
        val idx = ArrayList<Short>()
        var base = 0

        for (face in faces) {
            val u0 = face.cell * cellW + inset
            val u1 = (face.cell + 1) * cellW - inset
            for (j in 0..seg) {
                for (i in 0..seg) {
                    val fu = -s + 2f * s * i / seg
                    val fv = -s + 2f * s * j / seg
                    val px = face.o[0] + face.du[0] * fu + face.dv[0] * fv
                    val py = face.o[1] + face.du[1] * fu + face.dv[1] * fv
                    val pz = face.o[2] + face.du[2] * fu + face.dv[2] * fv
                    // Rounded-box mapping: clamp to the inner box, then push out by r.
                    val qx = px.coerceIn(-inner, inner)
                    val qy = py.coerceIn(-inner, inner)
                    val qz = pz.coerceIn(-inner, inner)
                    var nx = px - qx; var ny = py - qy; var nz = pz - qz
                    val len = sqrt(nx * nx + ny * ny + nz * nz)
                    if (len > 1e-5f) { nx /= len; ny /= len; nz /= len }
                    pos.add(qx + r * nx); pos.add(qy + r * ny); pos.add(qz + r * nz)
                    nrm.add(nx); nrm.add(ny); nrm.add(nz)
                    uv.add(u0 + (u1 - u0) * (i.toFloat() / seg))
                    uv.add((1f - inset) - (1f - 2f * inset) * (j.toFloat() / seg))
                }
            }
            val row = seg + 1
            for (j in 0 until seg) {
                for (i in 0 until seg) {
                    val a = base + j * row + i
                    val b = a + 1
                    val c = a + row
                    val d = c + 1
                    idx.add(a.toShort()); idx.add(c.toShort()); idx.add(b.toShort())
                    idx.add(b.toShort()); idx.add(c.toShort()); idx.add(d.toShort())
                }
            }
            base += row * row
        }

        posBuf = floatBuf(pos.toFloatArray())
        uvBuf = floatBuf(uv.toFloatArray())
        normBuf = floatBuf(nrm.toFloatArray())
        idxBuf = shortBuf(idx.toShortArray())
        indexCount = idx.size
    }

    // ── Pip atlas (white rounded faces with black pips, drawn at runtime) ─────────

    private fun buildPipAtlas(): Bitmap {
        val cell = 128
        val bmp = Bitmap.createBitmap(cell * 6, cell, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val face = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = AndroidColor.rgb(247, 244, 234) }
        val pip = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = AndroidColor.rgb(26, 26, 34) }
        for (v in 1..6) {
            val ox = (v - 1) * cell
            // Fill the whole cell so cube faces are fully opaque (no see-through corners).
            canvas.drawRect(ox.toFloat(), 0f, (ox + cell).toFloat(), cell.toFloat(), face)
            // Soft top-left sheen + faint bottom-right shading for a non-flat face.
            val sheen = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    ox.toFloat(), 0f, ox + cell * 0.75f, cell * 0.75f,
                    AndroidColor.argb(60, 255, 255, 255), AndroidColor.argb(0, 255, 255, 255),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawRect(ox.toFloat(), 0f, (ox + cell).toFloat(), cell.toFloat(), sheen)
            val shade = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    ox + cell * 0.4f, cell * 0.4f, (ox + cell).toFloat(), cell.toFloat(),
                    AndroidColor.argb(0, 0, 0, 0), AndroidColor.argb(38, 0, 0, 0),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawRect(ox.toFloat(), 0f, (ox + cell).toFloat(), cell.toFloat(), shade)
            val r = cell * 0.08f
            val a = ox + cell * 0.30f
            val b = ox + cell * 0.50f
            val c = ox + cell * 0.70f
            val y1 = cell * 0.30f; val y2 = cell * 0.50f; val y3 = cell * 0.70f
            val pts = when (v) {
                1 -> listOf(b to y2)
                2 -> listOf(c to y1, a to y3)
                3 -> listOf(c to y1, b to y2, a to y3)
                4 -> listOf(a to y1, c to y1, a to y3, c to y3)
                5 -> listOf(a to y1, c to y1, b to y2, a to y3, c to y3)
                else -> listOf(a to y1, c to y1, a to y2, c to y2, a to y3, c to y3)
            }
            pts.forEach { (px, py) -> canvas.drawCircle(px, py, r, pip) }
        }
        return bmp
    }

    private fun uploadTexture(bmp: Bitmap): Int {
        val ids = IntArray(1)
        GLES20.glGenTextures(1, ids, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, ids[0])
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE)
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE)
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bmp, 0)
        bmp.recycle()
        return ids[0]
    }

    // ── Shaders ─────────────────────────────────────────────────────────────────

    private fun buildProgram(): Int {
        val vs = """
            uniform mat4 uMvp;
            uniform mat4 uModel;
            attribute vec4 aPos;
            attribute vec2 aUv;
            attribute vec3 aNormal;
            varying vec2 vUv;
            varying vec3 vNormal;
            void main() {
                vUv = aUv;
                vNormal = normalize((uModel * vec4(aNormal, 0.0)).xyz);
                gl_Position = uMvp * aPos;
            }
        """.trimIndent()
        val fs = """
            precision mediump float;
            uniform sampler2D uTex;
            uniform vec3 uLight;
            varying vec2 vUv;
            varying vec3 vNormal;
            void main() {
                float diff = max(dot(normalize(vNormal), normalize(uLight)), 0.0) * 0.45 + 0.55;
                vec4 c = texture2D(uTex, vUv);
                gl_FragColor = vec4(c.rgb * diff, c.a);
            }
        """.trimIndent()
        val v = compile(GLES20.GL_VERTEX_SHADER, vs)
        val f = compile(GLES20.GL_FRAGMENT_SHADER, fs)
        val p = GLES20.glCreateProgram()
        GLES20.glAttachShader(p, v)
        GLES20.glAttachShader(p, f)
        GLES20.glLinkProgram(p)
        return p
    }

    private fun compile(type: Int, src: String): Int {
        val s = GLES20.glCreateShader(type)
        GLES20.glShaderSource(s, src)
        GLES20.glCompileShader(s)
        return s
    }

    private fun floatBuf(a: FloatArray): FloatBuffer =
        ByteBuffer.allocateDirect(a.size * 4).order(ByteOrder.nativeOrder()).asFloatBuffer().apply {
            put(a); position(0)
        }

    private fun shortBuf(a: ShortArray): ShortBuffer =
        ByteBuffer.allocateDirect(a.size * 2).order(ByteOrder.nativeOrder()).asShortBuffer().apply {
            put(a); position(0)
        }
}
