import Combine
import StoreKit
import SwiftUI

@MainActor
final class FullGameStore: ObservableObject {
    static let shared = FullGameStore()
    static let productID = "com.mm.BoxOfDice.fullversion"

    @Published private(set) var isUnlocked = false
    @Published private(set) var hasCheckedEntitlements = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var isProcessing = false

    private var updates: Task<Void, Never>?
    private var entitlementCheck = 0

    deinit { updates?.cancel() }

    enum Message {
        case pending, failed, nothingToRestore

        var text: LocalizedStringKey {
            switch self {
            case .pending: return "Your purchase is awaiting approval."
            case .failed: return "The App Store could not complete the request. Try again."
            case .nothingToRestore: return "No full version purchase was found for this Apple Account."
            }
        }
    }

    func prepare() async {
        if updates == nil {
            updates = Task { [weak self] in
                for await result in Transaction.updates {
                    guard case .verified(let transaction) = result,
                          transaction.productID == Self.productID else { continue }
                    await self?.refreshEntitlement()
                    await transaction.finish()
                }
            }
        }
        await refreshEntitlement()
    }

    func loadProduct() async {
        guard !isLoadingProduct else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        product = try? await Product.products(for: [Self.productID]).first { $0.type == .nonConsumable }
    }

    func purchase() async -> Message? {
        guard let product, !isProcessing, !isUnlocked else { return nil }
        isProcessing = true
        defer { isProcessing = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await refreshEntitlement()
                await transaction.finish()
                return isUnlocked ? nil : .failed
            case .pending: return .pending
            case .userCancelled: return nil
            case .success(.unverified): return .failed
            @unknown default: return .failed
            }
        } catch {
            return .failed
        }
    }

    func restore() async -> Message? {
        guard !isProcessing else { return nil }
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            return isUnlocked ? nil : .nothingToRestore
        } catch {
            return .failed
        }
    }

    private func refreshEntitlement() async {
        entitlementCheck += 1
        let check = entitlementCheck
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.productType == .nonConsumable,
               transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }
        guard !Task.isCancelled, check == entitlementCheck else { return }
        isUnlocked = unlocked
        hasCheckedEntitlements = true
    }
}
