//
//  TileView.swift
//  BoxOfDice
//

import SwiftUI

struct TileView: View {
    let number: Int
    let isOpen: Bool
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    @State private var visualIsOpen = true
    @State private var showsNumber = true
    @State private var flipTask: Task<Void, Never>?

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                tileShadow

                tileFace
                    .rotation3DEffect(
                        .degrees(visualIsOpen ? 0 : -68),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.55
                    )
                    .scaleEffect(x: visualIsOpen ? 1 : 0.96, y: visualIsOpen ? 1 : 0.78, anchor: .bottom)
                    .offset(y: verticalOffset)
                    .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .offset(y: isSelected ? -7 : 0)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isOpen && isEnabled)
        .onAppear {
            visualIsOpen = isOpen
            showsNumber = isOpen
        }
        .onChange(of: isOpen) { _, newValue in
            animateOpenState(newValue)
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.62), value: isSelected)
        .accessibilityLabel(isOpen ? "Tile \(number)" : "Closed tile \(number)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var tileFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(tileGradient)
                .overlay(edgeHighlight)
                .overlay(selectionRing)
                .overlay(closedNotch)

            Text("\(number)")
                .font(.system(size: number > 9 ? 23 : 26, weight: .heavy, design: .rounded))
                .foregroundStyle(textColor)
                .shadow(color: .white.opacity(isSelected || !visualIsOpen ? 0 : 0.5), radius: 0, x: 0, y: 1)
                .minimumScaleFactor(0.7)
                .opacity(numberOpacity)
                .scaleEffect(showsNumber ? 1 : 0.86)
        }
    }

    private var tileShadow: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(Color.black.opacity(visualIsOpen ? 0.20 : 0.30))
            .scaleEffect(x: visualIsOpen ? 0.92 : 1.0, y: visualIsOpen ? 0.84 : 0.70, anchor: .bottom)
            .blur(radius: visualIsOpen ? 5 : 3)
            .offset(y: visualIsOpen ? 9 : 4)
            .opacity(isSelected ? 0.55 : 1)
    }

    private func animateOpenState(_ newValue: Bool) {
        flipTask?.cancel()

        if newValue {
            showsNumber = false
            withAnimation(.interpolatingSpring(stiffness: 270, damping: 20)) {
                visualIsOpen = true
            }

            flipTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 130_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.14)) {
                    showsNumber = true
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                showsNumber = false
            }

            flipTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 85_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.interpolatingSpring(stiffness: 260, damping: 23)) {
                    visualIsOpen = false
                }
            }
        }
    }

    private var tileGradient: LinearGradient {
        if isSelected && isOpen && isEnabled {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.94, blue: 0.48), Color(red: 0.94, green: 0.61, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if visualIsOpen {
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.87, blue: 0.58), Color(red: 0.77, green: 0.50, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color(red: 0.20, green: 0.10, blue: 0.05), Color(red: 0.39, green: 0.22, blue: 0.12)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var edgeHighlight: some View {
        RoundedRectangle(cornerRadius: 11)
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(visualIsOpen ? 0.55 : 0.10), Color.black.opacity(0.38)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: visualIsOpen ? 1.5 : 1
            )
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected && isOpen {
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(Color(red: 0.18, green: 0.88, blue: 0.92), lineWidth: 3)
                .padding(-4)
                .shadow(color: Color(red: 0.18, green: 0.88, blue: 0.92).opacity(0.65), radius: 7, x: 0, y: 0)
        }
    }

    @ViewBuilder
    private var closedNotch: some View {
        if !visualIsOpen {
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.14))
                    .frame(height: 2)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.18))
                    .frame(height: 2)
            }
            .padding(.horizontal, 10)
        }
    }

    private var numberOpacity: Double {
        if visualIsOpen { return showsNumber ? 1 : 0 }
        return 0.16
    }

    private var textColor: Color {
        if !visualIsOpen { return Color(red: 0.86, green: 0.64, blue: 0.38) }
        return Color(red: 0.14, green: 0.07, blue: 0.02)
    }

    private var verticalOffset: CGFloat {
        if isSelected && isOpen { return -4 }
        return visualIsOpen ? -3 : 4
    }

    private var shadowOpacity: Double {
        visualIsOpen ? 0.34 : 0.10
    }

    private var shadowRadius: CGFloat {
        visualIsOpen ? 5 : 2
    }

    private var shadowY: CGFloat {
        visualIsOpen ? 7 : 1
    }
}
