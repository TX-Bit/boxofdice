//
//  DiceView.swift
//  BoxOfDice
//

import SwiftUI

struct DiceView: View {
    let value: Int
    let isRolling: Bool

    @State private var rotX: Double = 0
    @State private var rotY: Double = 0
    @State private var spin: Double = Double.random(in: -8...8)
    @State private var lift: Double = 0
    @State private var drift: Double = 0
    @State private var dieScaleX: Double = 1.0
    @State private var dieScaleY: Double = 1.0
    @State private var dotsOpacity: Double = 1.0

    var body: some View {
        ZStack {
            groundShadow

            ZStack {
                diceBody

                if value > 0 {
                    DotsView(value: value)
                        .frame(width: 66, height: 66)
                        .opacity(dotsOpacity)
                }
            }
            .frame(width: 96, height: 96)
            .rotation3DEffect(.degrees(rotX), axis: (x: 1, y: 0.3, z: 0), perspective: 0.42)
            .rotation3DEffect(.degrees(rotY), axis: (x: 0.2, y: 1, z: 0), perspective: 0.42)
            .rotationEffect(.degrees(spin))
            .scaleEffect(x: dieScaleX, y: dieScaleY)
            .offset(x: drift, y: lift)
        }
        .frame(width: 112, height: 112)
        .onChange(of: isRolling) { rolling in
            if rolling { beginRolling() } else { settle() }
        }
        .onChange(of: value) { _ in
            guard isRolling else { return }
            tumbleFrame()
        }
        .onAppear {
            if isRolling { beginRolling() }
        }
        .accessibilityLabel(value > 0 ? "Die showing \(value)" : "Die not rolled")
    }

    // MARK: - Animation phases

    private func beginRolling() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.66)) {
            dieScaleX = 1.04
            dieScaleY = 1.08
            lift = -16
            drift = Double.random(in: -7...7)
            dotsOpacity = 0.58
        }
        tumbleFrame()
    }

    private func tumbleFrame() {
        withAnimation(.timingCurve(0.22, 0.74, 0.34, 1.0, duration: 0.10)) {
            rotX = Double.random(in: -72...72)
            rotY = Double.random(in: -72...72)
            spin += Double.random(in: -105...105)
            lift = Double.random(in: -22 ... -8)
            drift = Double.random(in: -10...10)
            dieScaleX = Double.random(in: 0.98...1.08)
            dieScaleY = Double.random(in: 0.98...1.08)
        }
    }

    private func settle() {
        // Normalize accumulated spin to [-180, 180] so spring doesn't unwind multiple turns.
        var normalized = spin.truncatingRemainder(dividingBy: 360)
        if normalized > 180 { normalized -= 360 }
        if normalized < -180 { normalized += 360 }
        spin = normalized

        withAnimation(.easeOut(duration: 0.10)) {
            lift = 3
            drift *= 0.25
            dieScaleX = 1.08
            dieScaleY = 0.92
            dotsOpacity = 0.82
        }

        withAnimation(.interpolatingSpring(stiffness: 280, damping: 18).delay(0.08)) {
            rotX = Double.random(in: -7...7)
            rotY = Double.random(in: -7...7)
            spin = Double.random(in: -10...10)
            dieScaleX = 1.0
            dieScaleY = 1.0
            lift = 0
            drift = 0
        }
        withAnimation(.easeIn(duration: 0.16).delay(0.12)) {
            dotsOpacity = 1.0
        }
    }

    // MARK: - Die body

    private var diceBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.99, green: 0.98, blue: 0.955))

            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(0.66),
                        Color(red: 0.97, green: 0.94, blue: 0.88).opacity(0.20),
                        Color.black.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 5)
                .blur(radius: 3)
                .offset(x: -2, y: -2)
                .mask(RoundedRectangle(cornerRadius: 20))

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.30),
                            Color(white: 0.50).opacity(0.68),
                            Color(white: 0.34).opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.2
                )

            Ellipse()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.86), Color.white.opacity(0.18), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 24
                ))
                .frame(width: 48, height: 30)
                .blur(radius: 5)
                .offset(x: -18, y: -25)

            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                .offset(x: 1.2, y: 1.5)
                .blur(radius: 0.6)
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.14), radius: 3, x: 0, y: 2)
    }

    private var groundShadow: some View {
        let airborne = max(0, -lift)
        return Ellipse()
            .fill(RadialGradient(
                colors: [Color.black.opacity(0.28), Color.black.opacity(0.06), Color.clear],
                center: .center,
                startRadius: 2,
                endRadius: 42
            ))
            .frame(width: 82 + airborne * 0.9, height: 22 + airborne * 0.18)
            .scaleEffect(x: 1.0 + airborne * 0.010, y: max(0.62, 1.0 - airborne * 0.020))
            .opacity(max(0.28, 0.72 - airborne * 0.020))
            .offset(x: drift * 0.25, y: 40)
            .blur(radius: 2 + airborne * 0.08)
    }
}

// MARK: - Dots layout

private struct DotsView: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(dotPositions(for: value).indices, id: \.self) { i in
                    let pos = dotPositions(for: value)[i]
                    PipView()
                        .frame(width: 12, height: 12)
                        .position(x: pos.x * geo.size.width, y: pos.y * geo.size.height)
                }
            }
        }
    }

    private func dotPositions(for value: Int) -> [CGPoint] {
        switch value {
        case 1:
            return [CGPoint(x: 0.5, y: 0.5)]
        case 2:
            return [CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.25, y: 0.75)]
        case 3:
            return [CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.5, y: 0.5),
                    CGPoint(x: 0.25, y: 0.75)]
        case 4:
            return [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                    CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)]
        case 5:
            return [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                    CGPoint(x: 0.5, y: 0.5),
                    CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)]
        case 6:
            return [CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.75, y: 0.25),
                    CGPoint(x: 0.25, y: 0.5),  CGPoint(x: 0.75, y: 0.5),
                    CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.75, y: 0.75)]
        default:
            return []
        }
    }
}

// MARK: - Pip (single dot)

private struct PipView: View {
    var body: some View {
        ZStack {
            // Shadow cast on die face — gives the impression of a recessed pit
            Circle()
                .fill(Color.black.opacity(0.20))
                .scaleEffect(1.30)
                .blur(radius: 1.8)

            // Pit base: dark gradient
            Circle()
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.04, blue: 0.01),
                        Color(red: 0.18, green: 0.10, blue: 0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))

            // Inner shadow: upper rim of recess blocks light from above
            Circle()
                .fill(LinearGradient(
                    colors: [Color.black.opacity(0.45), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.60)
                ))

            // Inner highlight: lower rim of recess catches light
            Circle()
                .fill(LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.18)],
                    startPoint: UnitPoint(x: 0.5, y: 0.44),
                    endPoint: .bottom
                ))

            // Rim stroke: dark top edge, faint light on bottom edge
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.black.opacity(0.48), Color.white.opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        }
    }
}
