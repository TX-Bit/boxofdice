//
//  DiceView.swift
//  BoxOfDice
//

import SwiftUI

struct DiceView: View {
    let value: Int
    let isRolling: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.93, green: 0.89, blue: 0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color(red: 0.36, green: 0.18, blue: 0.08).opacity(0.28), lineWidth: 1.5)
                )
                .frame(width: 92, height: 92)
                .shadow(color: .black.opacity(isRolling ? 0.46 : 0.36), radius: isRolling ? 13 : 10, x: 0, y: isRolling ? 9 : 7)

            if value > 0 {
                DotsView(value: value)
                    .frame(width: 68, height: 68)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 96, height: 96)
        .rotationEffect(.degrees(isRolling ? rollAngle : 0))
        .rotation3DEffect(.degrees(isRolling ? 14 : 0), axis: (x: 0.6, y: 0.8, z: 0), perspective: 0.45)
        .scaleEffect(isRolling ? 1.06 : 1.0)
        .offset(y: isRolling ? -3 : 0)
        .animation(.spring(response: 0.16, dampingFraction: 0.58), value: value)
        .animation(.easeInOut(duration: 0.12), value: isRolling)
        .accessibilityLabel(value > 0 ? "Die showing \(value)" : "Die not rolled")
    }

    private var rollAngle: Double {
        Double((value * 37) % 22 - 11)
    }
}

private struct DotsView: View {
    let value: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(dotPositions(for: value).indices, id: \.self) { i in
                    let pos = dotPositions(for: value)[i]
                    Circle()
                        .fill(Color(red: 0.12, green: 0.06, blue: 0.03))
                        .frame(width: 13, height: 13)
                        .shadow(color: .white.opacity(0.3), radius: 0, x: 0, y: 1)
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
