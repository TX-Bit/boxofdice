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
                        .degrees(visualIsOpen ? 0 : -8),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.20
                    )
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
                x: isSelected ? 1.05 : (visualIsOpen ? 0.88 : 0.94),
                y: isSelected ? 0.68 : (visualIsOpen ? 0.76 : 0.15),
                anchor: .bottom
            )
            .blur(radius: isSelected ? 11 : (visualIsOpen ? 5 : 1.5))
            .offset(y: isSelected ? 17 : (visualIsOpen ? 9 : 12))
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

    // Open tile: physical ivory flip tile with engraved number
    private var openTileFace: some View {
        ZStack {
            // Base warm ivory gradient
            RoundedRectangle(cornerRadius: 11)
                .fill(openBaseGradient)

            // Directional shading — upper-left light casts subtle shadow toward bottom-right
            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.11)],
                    startPoint: UnitPoint(x: 0.25, y: 0.25),
                    endPoint: .bottomTrailing
                ))

            // Lower darkening band — visible edge thickness
            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.20)],
                    startPoint: UnitPoint(x: 0.5, y: 0.58),
                    endPoint: .bottom
                ))

            // Bottom thickness strip — dark brown edge shows physical depth
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.10, blue: 0.03),
                            Color(red: 0.10, green: 0.04, blue: 0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 5)
                    .padding(.horizontal, 4)
                    .offset(y: 1)
            }

            // Hinge pins at top corners — two small circles suggest the pivot axis
            VStack(spacing: 0) {
                HStack {
                    Circle()
                        .fill(Color(white: 0.50).opacity(0.55))
                        .frame(width: 4, height: 4)
                        .shadow(color: Color.black.opacity(0.35), radius: 0.8, x: 0, y: 1)
                    Spacer()
                    Circle()
                        .fill(Color(white: 0.50).opacity(0.55))
                        .frame(width: 4, height: 4)
                        .shadow(color: Color.black.opacity(0.35), radius: 0.8, x: 0, y: 1)
                }
                .padding(.horizontal, 5)
                .padding(.top, 4)
                Spacer()
            }

            // Top specular highlight — reduced
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.26), Color.clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.26)
                ))
                .padding(.horizontal, 5)
                .padding(.top, 2)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            // Sharper bevel — 2px, crisp upper-left bright / lower-right dark
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color.white.opacity(0.16),
                            Color(red: 0.35, green: 0.18, blue: 0.06).opacity(0.68),
                            Color(red: 0.14, green: 0.05, blue: 0.01).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            // Number — dark brown, engraved; lineLimit(1) prevents two-digit wrap to "1\n1"
            Text("\(number)")
                .font(GameTypography.tileNumber(size: number > 9 ? 22 : 28))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .allowsTightening(true)
                .foregroundStyle(Color(red: 0.14, green: 0.05, blue: 0.01))
                .shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.36), radius: 1.5, x: 0, y: -1)
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

    // Closed tile: flatter dark walnut backside, still aligned in the original slot.
    private var closedTileFace: some View {
        GeometryReader { proxy in
            let height = proxy.size.height * 0.58

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(closedBaseGradient)

                    RoundedRectangle(cornerRadius: 7)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.58, green: 0.31, blue: 0.12).opacity(0.12),
                                Color.clear,
                                Color(red: 0.12, green: 0.04, blue: 0.01).opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.08, green: 0.03, blue: 0.008).opacity(0.92))
                            .frame(height: 4)
                            .overlay(
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color(red: 0.46, green: 0.30, blue: 0.18).opacity(0.70))
                                        .frame(width: 3.5, height: 3.5)
                                    Spacer()
                                    Circle()
                                        .fill(Color(red: 0.46, green: 0.30, blue: 0.18).opacity(0.70))
                                        .frame(width: 3.5, height: 3.5)
                                }
                                .padding(.horizontal, 6)
                            )
                        Spacer()
                    }

                    Text("\(number)")
                        .font(GameTypography.tileNumber(size: number > 9 ? 17 : 21))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .allowsTightening(true)
                        .foregroundStyle(Color(red: 0.82, green: 0.64, blue: 0.42).opacity(0.18))
                        .shadow(color: Color.black.opacity(0.35), radius: 0.5, x: 0, y: 1)

                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 0.24, green: 0.11, blue: 0.035),
                                    Color(red: 0.07, green: 0.025, blue: 0.006)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(height: 5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.44, blue: 0.22).opacity(0.34),
                                    Color.black.opacity(0.24),
                                    Color.black.opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                }
                .frame(width: proxy.size.width, height: height)
            }
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
        // Dark walnut — matches tray frame, integrates naturally with the tray recess
        LinearGradient(
            colors: [
                Color(red: 0.28, green: 0.13, blue: 0.045),
                Color(red: 0.18, green: 0.08, blue: 0.025),
                Color(red: 0.10, green: 0.04, blue: 0.012)
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
            // Physical flap: number fades fast, tile pivots forward with a spring bounce
            withAnimation(.easeOut(duration: 0.07)) {
                showsNumber = false
            }

            flipTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.22, dampingFraction: 0.70)) {
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
