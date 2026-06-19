//
//  CelebrationView.swift
//  BoxOfDice
//
//  The end-of-game celebration overlay. Self-contained: it reads a
//  CelebrationOutcome, plays for a short fixed duration, then calls onComplete
//  so ContentView can reveal the result card. It does not touch GameViewModel
//  or game state.
//

import SwiftUI

// Shared warm-gold palette for every celebration.
private enum Cel {
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.37)
    static let deepGold = Color(red: 0.92, green: 0.55, blue: 0.16)
    static let lightGold = Color(red: 1.0, green: 0.94, blue: 0.72)

    static var titleGradient: LinearGradient {
        LinearGradient(colors: [lightGold, gold, deepGold], startPoint: .top, endPoint: .bottom)
    }
}

struct CelebrationView: View {
    let outcome: CelebrationOutcome
    let theme: GameTheme
    let level: CelebrationLevel
    let reduceMotion: Bool
    let onComplete: () -> Void

    @State private var didFinish = false

    // Reduced visuals when the user picked "Reduced" or the system asks to
    // minimise motion.
    private var isReduced: Bool { level == .reduced || reduceMotion }

    private var duration: Double {
        switch outcome.type {
        case .perfectClear: return isReduced ? 1.6 : 2.6
        case .boardCleared: return isReduced ? 1.3 : 2.1
        case .newBest:      return isReduced ? 1.1 : 1.7
        case .none:         return 0.1
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            content

            // The "New Best!" badge rides along on top of a Board Cleared or
            // Perfect Clear celebration. When New Best is the whole event it is
            // shown by NewBestCelebration instead.
            if outcome.isNewBest && outcome.type != .newBest && outcome.type != .none {
                VStack {
                    NewBestBadge(outcome: outcome)
                        .padding(.top, 64)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }       // tap anywhere to skip ahead
        .task { await runTimer() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var content: some View {
        switch outcome.type {
        case .perfectClear:
            PerfectClearCelebration(outcome: outcome, isReduced: isReduced)
        case .boardCleared:
            // Board Cleared no longer animates; the result card carries the news.
            EmptyView()
        case .newBest:
            NewBestCelebration(outcome: outcome, isReduced: isReduced)
        case .none:
            EmptyView()
        }
    }

    private var accessibilityText: String {
        switch outcome.type {
        case .perfectClear: return L10n.string("Perfect Clear!")
        case .boardCleared: return L10n.string("Board Cleared!")
        case .newBest:      return L10n.string(outcome.isFirstScore ? "First Score!" : "New Best!")
        case .none:         return ""
        }
    }

    private func runTimer() async {
        // The full Perfect Clear runs continuously until the player taps to skip.
        // Everything else (and the reduced Perfect Clear) auto-dismisses.
        if outcome.type == .perfectClear && !isReduced { return }
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        finish()
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onComplete()
    }
}

// MARK: - Shared title

private struct CelebrationTitle: View {
    let text: String
    let size: CGFloat
    let animate: Bool

    @State private var shown = false

    var body: some View {
        Text(L10n.string(text))
            .font(GameTypography.title(size: size))
            .foregroundStyle(Cel.titleGradient)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .shadow(color: Cel.gold.opacity(0.55), radius: 18)
            .scaleEffect(shown ? 1 : (animate ? 0.7 : 0.95))
            .opacity(shown ? 1 : 0)
            .onAppear {
                let animation: Animation = animate
                    ? .spring(response: 0.5, dampingFraction: 0.6)
                    : .easeOut(duration: 0.4)
                withAnimation(animation) { shown = true }
            }
    }
}

// MARK: - New Best (standalone)

private struct NewBestCelebration: View {
    let outcome: CelebrationOutcome
    let isReduced: Bool

    @State private var shown = false

    private var title: String { outcome.isFirstScore ? "First Score!" : "New Best!" }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.system(size: 38))
                .foregroundStyle(Cel.titleGradient)
                .shadow(color: Cel.gold.opacity(0.6), radius: 14)

            Text(L10n.string(title))
                .font(GameTypography.title(size: 32))
                .foregroundStyle(Cel.titleGradient)

            VStack(spacing: 4) {
                Text(L10n.format("Score %lld", outcome.finalScore))
                    .font(GameTypography.value(size: 20))
                    .foregroundStyle(Cel.lightGold)

                if let previous = outcome.previousBest {
                    Text(L10n.format("Previous best %lld", previous))
                        .font(GameTypography.caption(size: 14))
                        .foregroundStyle(Cel.lightGold.opacity(0.68))
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Cel.gold.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: Cel.gold.opacity(0.35), radius: 22)
        )
        .scaleEffect(shown ? 1 : (isReduced ? 0.96 : 0.7))
        .opacity(shown ? 1 : 0)
        .onAppear {
            let animation: Animation = isReduced
                ? .easeOut(duration: 0.4)
                : .spring(response: 0.5, dampingFraction: 0.62)
            withAnimation(animation) { shown = true }
        }
    }
}

/// Compact badge overlaid on a bigger celebration.
private struct NewBestBadge: View {
    let outcome: CelebrationOutcome

    @State private var shown = false

    private var title: String { outcome.isFirstScore ? "First Score!" : "New Best!" }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Cel.gold)
            Text(L10n.string(title))
                .font(GameTypography.button(size: 16))
                .foregroundStyle(Cel.lightGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(Cel.gold.opacity(0.7), lineWidth: 1.5))
        )
        .shadow(color: Cel.gold.opacity(0.5), radius: 10)
        .scaleEffect(shown ? 1 : 0.6)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.45)) {
                shown = true
            }
        }
    }
}

// MARK: - Perfect Clear

private struct PerfectClearCelebration: View {
    let outcome: CelebrationOutcome
    let isReduced: Bool

    @State private var showHint = false

    var body: some View {
        ZStack {
            if isReduced {
                ReducedGlow(diameter: 420)
            } else {
                switch outcome.perfectClearStyle {
                case .goldenFireworks: GoldenFireworks()
                case .diceRain:        DiceRain()
                }
            }

            VStack(spacing: 8) {
                CelebrationTitle(text: "Perfect Clear!", size: 44, animate: !isReduced)
                Text(L10n.string("Flawless — every tile closed."))
                    .font(GameTypography.label(size: 15))
                    .foregroundStyle(Cel.lightGold.opacity(0.9))
            }
            .padding(.horizontal, 30)

            // The full Perfect Clear keeps running, so nudge the player to tap once
            // they've enjoyed it.
            if !isReduced {
                VStack {
                    Spacer()
                    Text(L10n.string("Tap to continue"))
                        .font(GameTypography.caption(size: 13))
                        .tracking(1)
                        .foregroundStyle(Cel.lightGold.opacity(0.65))
                        .padding(.bottom, 70)
                        .opacity(showHint ? 1 : 0)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).delay(2.6)) { showHint = true }
                }
            }
        }
    }
}

/// A real fireworks show, drawn frame-by-frame in a Canvas with additive
/// blending: rockets streak up, burst into a sphere of sparks that arc under
/// gravity, glow white-hot then cool to colour, twinkle, and fade. Runs
/// continuously until the celebration is dismissed.
private struct GoldenFireworks: View {
    @State private var shells: [Shell] = []
    @State private var start = Date()

    private struct Shell: Identifiable {
        let id = UUID()
        let birth: TimeInterval     // seconds since `start` when launched
        let launchX: CGFloat        // 0…1, where the rocket leaves the ground
        let burstX: CGFloat         // 0…1, explosion point
        let burstY: CGFloat         // 0…1
        let rise: TimeInterval      // time to climb to the burst
        let life: TimeInterval      // spark lifetime after the burst
        let count: Int              // sparks
        let speed: CGFloat          // initial spark speed (pt/s)
        let color: Color
        let seed: UInt64
    }

    // Warm, on-theme palette with a couple of accents for variety.
    private static let palette: [Color] = [
        Color(red: 1.0, green: 0.84, blue: 0.40),   // gold
        Color(red: 1.0, green: 0.66, blue: 0.20),   // amber
        Color(red: 1.0, green: 0.52, blue: 0.30),   // warm coral
        Color(red: 1.0, green: 0.93, blue: 0.74),   // warm white
        Color(red: 1.0, green: 0.45, blue: 0.55),   // rosé
        Color(red: 0.62, green: 0.84, blue: 1.0),   // cool sparkle
    ]

    private let warmWhite = Color(red: 1.0, green: 0.97, blue: 0.90)
    private let gravity: CGFloat = 230
    private let drag: CGFloat = 1.7

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                context.blendMode = .plusLighter
                for shell in shells {
                    draw(shell, elapsed: elapsed, in: &context, size: size)
                }
            }
        }
        .onAppear { start = Date() }
        .task {
            var launched = 0
            while !Task.isCancelled {
                let now = Date().timeIntervalSince(start)
                launched += 1
                // Occasionally fire a quick double for a busier sky.
                let salvo = Int.random(in: 1...2)
                for _ in 0..<salvo {
                    shells.append(makeShell(at: now, index: launched))
                    launched += 1
                }
                shells.removeAll { now - $0.birth > $0.rise + $0.life + 0.5 }
                try? await Task.sleep(nanoseconds: UInt64.random(in: 380_000_000...720_000_000))
            }
        }
    }

    private func makeShell(at now: TimeInterval, index: Int) -> Shell {
        let bx = CGFloat.random(in: 0.18...0.82)
        return Shell(
            birth: now,
            launchX: bx + CGFloat.random(in: -0.06...0.06),
            burstX: bx,
            burstY: CGFloat.random(in: 0.20...0.48),
            rise: Double.random(in: 0.55...0.85),
            life: Double.random(in: 1.5...2.1),
            count: Int.random(in: 30...44),
            speed: CGFloat.random(in: 190...320),
            color: Self.palette.randomElement() ?? Cel.gold,
            seed: UInt64(bitPattern: Int64(index)) &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03
        )
    }

    private func draw(_ shell: Shell, elapsed: TimeInterval, in context: inout GraphicsContext, size: CGSize) {
        let age = elapsed - shell.birth
        guard age >= 0 else { return }
        let w = size.width, h = size.height

        if age < shell.rise {
            // Rocket climbing — bright head with a fading tail.
            let p = age / shell.rise
            for k in 0..<7 {
                let tp = p - Double(k) * 0.05
                guard tp >= 0 else { break }
                let e = 1 - pow(1 - tp, 2)                  // decelerate toward the top
                let x = lerp(shell.launchX, shell.burstX, CGFloat(e)) * w
                let y = (1.0 - (1.0 - shell.burstY) * CGFloat(e)) * h
                let a = (1 - Double(k) / 7) * 0.7
                let r = max(0.6, 3.0 - CGFloat(k) * 0.34)
                fillCircle(&context, x: x, y: y, r: r, color: warmWhite.opacity(a))
            }
            return
        }

        let tp = age - shell.rise
        guard tp <= shell.life else { return }
        let bx = shell.burstX * w
        let by = shell.burstY * h
        let f = (1 - exp(-Double(drag) * tp)) / Double(drag)   // dragged travel factor

        // Opening flash.
        if tp < 0.16 {
            let fa = (1 - tp / 0.16)
            let fr: CGFloat = 46
            context.fill(
                Path(ellipseIn: CGRect(x: bx - fr, y: by - fr, width: fr * 2, height: fr * 2)),
                with: .radialGradient(
                    Gradient(colors: [warmWhite.opacity(fa * 0.9), .clear]),
                    center: CGPoint(x: bx, y: by), startRadius: 0, endRadius: fr
                )
            )
        }

        for i in 0..<shell.count {
            let h1 = hash(shell.seed, i, 1)
            let h2 = hash(shell.seed, i, 2)
            let h3 = hash(shell.seed, i, 3)
            let angle = Double(i) / Double(shell.count) * 2 * .pi + (h1 - 0.5) * 0.32
            let sp = Double(shell.speed) * (0.6 + 0.7 * h2)
            let ca = cos(angle), sa = sin(angle)

            // Head plus two short trail samples → a streak of light.
            for t in 0..<3 {
                let ttp = tp - Double(t) * 0.05
                guard ttp >= 0 else { continue }
                let ff = (1 - exp(-Double(drag) * ttp)) / Double(drag)
                let px = bx + CGFloat(ca * sp * ff)
                let py = by + CGFloat(sa * sp * ff) + 0.5 * gravity * CGFloat(ttp * ttp)
                let fade = max(0, 1 - ttp / shell.life)
                let twinkle = 0.72 + 0.28 * sin(ttp * 26 + h3 * 6.28)
                let baseAlpha = fade * twinkle
                guard baseAlpha > 0.02 else { continue }
                let trailScale = t == 0 ? 1.0 : (t == 1 ? 0.42 : 0.2)
                let r = (t == 0 ? 2.6 : 1.5) * CGFloat(0.7 + 0.5 * h2)

                if t == 0 {
                    // Coloured glow halo.
                    fillCircle(&context, x: px, y: py, r: r * 2.6,
                               color: shell.color.opacity(baseAlpha * 0.3))
                }
                // White-hot core that cools to the shell colour as it fades.
                let coreColor = fade > 0.55 ? warmWhite : shell.color
                fillCircle(&context, x: px, y: py, r: r,
                           color: coreColor.opacity(baseAlpha * trailScale))
            }
        }
    }

    private func fillCircle(_ context: inout GraphicsContext, x: CGFloat, y: CGFloat, r: CGFloat, color: Color) {
        context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(color))
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    private func hash(_ seed: UInt64, _ i: Int, _ d: Int) -> Double {
        var x = seed &+ UInt64(bitPattern: Int64(i)) &* 0x9E3779B97F4A7C15 &+ UInt64(d) &* 0x632BE59BD9B4E019
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        x ^= (x >> 31)
        return Double(x >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

/// A continuous rain of gold dice falling from the top until dismissed.
private struct DiceRain: View {
    @State private var drops: [Drop] = []

    private struct Drop: Identifiable {
        let id = UUID()
        let x: Double
        let size: CGFloat
        let spin: Double
        let pip: Int
        let duration: Double
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(drops) { drop in
                    FallingDie(
                        x: drop.x,
                        size: drop.size,
                        spin: drop.spin,
                        pip: drop.pip,
                        duration: drop.duration,
                        screenSize: proxy.size
                    )
                }
            }
            .task {
                while !Task.isCancelled {
                    // A couple of dice per tick → a steady, dense shower.
                    for _ in 0..<Int.random(in: 1...2) {
                        drops.append(Drop(
                            x: Double.random(in: 0.05...0.95),
                            size: CGFloat.random(in: 34...64),
                            spin: Double.random(in: -360...360),
                            pip: Int.random(in: 1...6),
                            duration: Double.random(in: 1.6...2.7)
                        ))
                    }
                    if drops.count > 48 { drops.removeFirst(drops.count - 48) }
                    try? await Task.sleep(nanoseconds: 130_000_000)
                }
            }
        }
    }
}

/// One gold die tumbling from above the screen to below it.
private struct FallingDie: View {
    let x: Double
    let size: CGFloat
    let spin: Double
    let pip: Int
    let duration: Double
    let screenSize: CGSize

    @State private var falling = false

    var body: some View {
        GoldDie(pip: pip, size: size)
            .rotationEffect(.degrees(falling ? spin : 0))
            .position(
                x: x * screenSize.width,
                y: falling ? screenSize.height + size : -size
            )
            .onAppear {
                withAnimation(.easeIn(duration: duration)) { falling = true }
            }
    }
}

private struct GoldDie: View {
    let pip: Int
    let size: CGFloat

    var body: some View {
        Image(systemName: "die.face.\(pip).fill")
            .font(.system(size: size))
            .foregroundStyle(Cel.titleGradient)
            .shadow(color: Cel.deepGold.opacity(0.5), radius: 8)
    }
}

/// A soft gold radial glow that simply fades in — the Reduced / Reduce Motion
/// fallback for both Perfect Clear and Board Cleared.
private struct ReducedGlow: View {
    let diameter: CGFloat

    @State private var shown = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Cel.gold.opacity(0.5), Cel.gold.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 8,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { shown = true }
            }
    }
}

#Preview("Perfect Clear") {
    CelebrationView(
        outcome: CelebrationOutcome(
            type: .perfectClear, resultKind: .perfectClear,
            isNewBest: true, isFirstScore: false, finalScore: 0, previousBest: 8,
            tileCount: 12, modeName: "Classic", perfectClearStyle: .goldenFireworks
        ),
        theme: .palette(for: .classicWood), level: .on, reduceMotion: false, onComplete: {}
    )
}

#Preview("New Best") {
    CelebrationView(
        outcome: CelebrationOutcome(
            type: .newBest, resultKind: .newBest,
            isNewBest: true, isFirstScore: false, finalScore: 24, previousBest: 31,
            tileCount: 12, modeName: "Classic", perfectClearStyle: .goldenFireworks
        ),
        theme: .palette(for: .classicWood), level: .on, reduceMotion: false, onComplete: {}
    )
}
