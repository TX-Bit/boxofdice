import StoreKit
import SwiftUI

struct FullGamePurchaseView: View {
    @ObservedObject var store: FullGameStore
    let theme: GameTheme
    var reachedDailyLimit = false

    @Environment(\.dismiss) private var dismiss
    @State private var message: FullGameStore.Message?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(theme.text)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 18)

            GeometryReader { proxy in
                let isCompact = proxy.size.height < 370
                ScrollView(showsIndicators: false) {
                    offerCard(isCompact: isCompact)
                        .padding(.horizontal, 18)
                        .padding(.vertical, isCompact ? 8 : 24)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .compatibleBounceBasedOnSize()
            }
        }
        .foregroundStyle(theme.text)
        .background(ThemedSheetBackground(theme: theme))
        .tint(theme.accent)
        .task { await store.loadProduct() }
    }

    private func offerCard(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 18) {
            offerHeading(isCompact: isCompact)

            if !store.isUnlocked {
                VStack(spacing: isCompact ? 4 : 8) {
                    if reachedDailyLimit {
                        Text("You've played your rounds for today.")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Play unlimited rounds. Pay once.")
                        .font(.subheadline)
                        .foregroundStyle(theme.text.opacity(0.82))

                    if store.product?.isFamilyShareable == true {
                        Label("Supports Family Sharing", systemImage: "person.2.fill")
                            .font(.footnote)
                            .foregroundStyle(theme.text.opacity(0.82))
                    }
                }

                purchaseActions(isCompact: isCompact)

                if let message {
                    Text(message.text)
                        .font(.footnote)
                        .foregroundStyle(theme.text.opacity(0.82))
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, isCompact ? 12 : 26)
        .frame(maxWidth: isCompact ? 410 : 360)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [theme.text.opacity(0.12), theme.accent.opacity(0.06)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(theme.text.opacity(0.20), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func purchaseActions(isCompact: Bool) -> some View {
        let buy = VStack(spacing: 4) { purchaseButton }
        let restore = Button {
            Task { message = await store.restore() }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .frame(minHeight: 44)
        }
        .disabled(store.isProcessing)

        if isCompact {
            HStack(spacing: 14) {
                buy
                restore
            }
        } else {
            VStack(spacing: 2) {
                buy
                restore
            }
        }
    }

    @ViewBuilder
    private func offerHeading(isCompact: Bool) -> some View {
        let titleKey: LocalizedStringKey = store.isUnlocked ? "Full Version Unlocked" : "Full Version"
        let title = Text(titleKey)
            .font(GameTypography.title(size: isCompact ? 22 : 30))
            .accessibilityAddTraits(.isHeader)
        let icon = Image(systemName: store.isUnlocked ? "checkmark" : "dice.fill")
            .font(.system(size: isCompact ? 18 : 27, weight: .semibold))
            .foregroundStyle(theme.text)
            .frame(width: isCompact ? 34 : 56, height: isCompact ? 34 : 56)
            .background(theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: isCompact ? 10 : 16))
            .accessibilityHidden(true)

        if isCompact {
            HStack(spacing: 9) {
                icon
                title
            }
        } else {
            VStack(spacing: 12) {
                icon
                title
            }
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if store.isProcessing || store.isLoadingProduct {
            ProgressView()
                .frame(minHeight: 44)
        } else if let product = store.product {
            Button {
                Task { message = await store.purchase() }
            } label: {
                Text(L10n.format("Unlock for %@", product.displayPrice))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 13))
            .foregroundStyle(Color.black)
        } else {
            Text("The App Store price is currently unavailable.")
                .font(.footnote)
            Button("Try Again") {
                Task { await store.loadProduct() }
            }
        }
    }
}
