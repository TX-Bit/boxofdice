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
                tileDropShadow

                tileFace
                    .rotation3DEffect(
                        .degrees(visualIsOpen ? 0 : -18),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.28
                    )
                    .scaleEffect(x: visualIsOpen ? 1 : 0.98, y: visualIsOpen ? 1 : 0.42, anchor: .bottom)
                    .offset(y: verticalOffset)
            }
            .scaleEffect(isSelected ? 1.09 : 1.0)
            .offset(y: isSelected ? -8 : 0)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isOpen && isEnabled)
        .onAppear {
            visualIsOpen = isOpen
            showsNumber = isOpen
        }
        .onChange(of: isOpen, perform: { newValue in
            animateOpenState(newValue)
        })
        .animation(.spring(response: 0.24, dampingFraction: 0.62), value: isSelected)
        .accessibilityLabel(isOpen ? "Tile \(number)" : "Closed tile \(number)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Drop shadow

    private var tileDropShadow: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(Color.black.opacity(0.30))
            .scaleEffect(
                x: isSelected ? 1.05 : (visualIsOpen ? 0.88 : 0.96),
                y: isSelected ? 0.68 : (visualIsOpen ? 0.76 : 0.24),
                anchor: .bottom
            )
            .blur(radius: isSelected ? 11 : (visualIsOpen ? 5 : 2.5))
            .offset(y: isSelected ? 17 : (visualIsOpen ? 9 : 15))
    }

    // MARK: - Tile face

    private var tileFace: some View {
        ZStack {
            if visualIsOpen {
                openTileFace
            } else {
                closedTileFace
            }
        }
    }

    // Open tile: ivory/golden with bevel, specular highlight, and engraved number
    private var openTileFace: some View {
        ZStack {
            // Base warm ivory-to-amber gradient
            RoundedRectangle(cornerRadius: 11)
                .fill(openBaseGradient)

            // Lower darkening band — simulates thickness/3D edge
            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.22)],
                    startPoint: UnitPoint(x: 0.5, y: 0.55),
                    endPoint: .bottom
                ))

            // Top specular highlight — light catching the face
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.68), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.30)
                ))
                .padding(.horizontal, 5)
                .padding(.top, 2)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            // Bevel stroke: bright top edge grades to dark bottom edge
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            Color.white.opacity(0.20),
                            Color(red: 0.40, green: 0.20, blue: 0.06).opacity(0.80),
                            Color(red: 0.18, green: 0.06, blue: 0.01).opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )

            // Number — dark ink with engraving shadow pair
            Text("\(number)")
                .font(GameTypography.tileNumber(size: number > 9 ? 24 : 28))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.15, green: 0.06, blue: 0.01), Color(red: 0.30, green: 0.13, blue: 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color.white.opacity(0.58), radius: 0, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.30), radius: 1, x: 0, y: -1)
                .minimumScaleFactor(0.7)
                .opacity(showsNumber ? 1 : 0)
                .scaleEffect(showsNumber ? 1 : 0.86)

            // Selection ring + outer glow
            if isSelected {
                RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(red: 0.30, green: 0.95, blue: 1.0), Color(red: 0.08, green: 0.68, blue: 0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .shadow(color: Color(red: 0.18, green: 0.88, blue: 1.0).opacity(0.72), radius: 9, x: 0, y: 0)
            }
        }
    }

    // Closed tile: low dark wooden slab resting against the tray surface
    private var closedTileFace: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 11)
                .fill(closedBaseGradient)

            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.30, blue: 0.12).opacity(0.18),
                        Color.clear,
                        Color.black.opacity(0.28),
                        Color.clear,
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.14), Color.clear],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.46, y: 0.46)
                ))

            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.46)],
                    startPoint: UnitPoint(x: 0.5, y: 0.44),
                    endPoint: .bottom
                ))

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.30, green: 0.13, blue: 0.045),
                        Color(red: 0.08, green: 0.03, blue: 0.01)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 14)
                .padding(.horizontal, 2)
                .offset(y: 4)

            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.62, blue: 0.32).opacity(0.28),
                            Color.black.opacity(0.22),
                            Color.black.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
    }

    // MARK: - Gradients

    private var openBaseGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.97, blue: 0.62), Color(red: 0.98, green: 0.74, blue: 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(red: 1.0, green: 0.95, blue: 0.78), Color(red: 0.84, green: 0.57, blue: 0.22)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var closedBaseGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.24, green: 0.105, blue: 0.035),
                Color(red: 0.15, green: 0.060, blue: 0.018),
                Color(red: 0.075, green: 0.028, blue: 0.008)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animation

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

    // MARK: - Helpers

    private var verticalOffset: CGFloat {
        if isSelected && isOpen { return -4 }
        return visualIsOpen ? -3 : 4
    }
}
