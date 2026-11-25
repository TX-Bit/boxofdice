import StoreKit
import StoreKitTest
import XCTest
@testable import BoxOfDice

@MainActor
final class PlayAccessTests: XCTestCase {
    func testTenStartsPersistAndResetAtLocalMidnight() throws {
        let (allowance, suite) = try makeAllowance()
        defer { allowance.defaults.removePersistentDomain(forName: suite) }
        let beforeMidnight = try XCTUnwrap(allowance.calendar.date(from: DateComponents(
            year: 2026, month: 11, day: 25, hour: 23, minute: 59
        )))
        for _ in 0..<10 {
            XCTAssertTrue(allowance.startRound(isUnlocked: false, at: beforeMidnight))
        }
        let reopened = DailyRoundAllowance(defaults: allowance.defaults, calendar: allowance.calendar)
        XCTAssertFalse(reopened.canStartRound(isUnlocked: false, at: beforeMidnight))
        XCTAssertFalse(reopened.startRound(isUnlocked: false, at: beforeMidnight))
        XCTAssertTrue(reopened.startRound(isUnlocked: false, at: beforeMidnight.addingTimeInterval(60)))
    }

    func testPaidRoundsDoNotConsumeAllowanceOrRequestReviews() throws {
        let (allowance, suite) = try makeAllowance()
        defer { allowance.defaults.removePersistentDomain(forName: suite) }
        let now = Date()
        for _ in 0..<20 {
            XCTAssertTrue(allowance.startRound(isUnlocked: true, at: now))
            allowance.recordCompletedRound(isUnlocked: true)
        }
        XCTAssertFalse(allowance.takeReviewRequest(isUnlocked: false))
        for _ in 0..<10 {
            XCTAssertTrue(allowance.startRound(isUnlocked: false, at: now))
        }
        XCTAssertFalse(allowance.startRound(isUnlocked: false, at: now))
        XCTAssertTrue(allowance.startRound(isUnlocked: true, at: now))
    }

    func testReviewRequestIsTakenOncePerEightFreeCompletions() throws {
        let (allowance, suite) = try makeAllowance()
        defer { allowance.defaults.removePersistentDomain(forName: suite) }
        for count in 1...16 {
            allowance.recordCompletedRound(isUnlocked: false)
            XCTAssertFalse(allowance.takeReviewRequest(isUnlocked: true))
            XCTAssertEqual(allowance.takeReviewRequest(isUnlocked: false), count.isMultiple(of: 8))
            XCTAssertFalse(allowance.takeReviewRequest(isUnlocked: false))
        }
    }

    func testStoreKitProductUnlocksAndNewStoreReadsPurchase() async throws {
        let configuration = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "FullVersion", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: configuration)
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }

        let store = FullGameStore()
        await store.prepare()
        XCTAssertFalse(store.isUnlocked)
        let available = try await Product.products(for: [FullGameStore.productID])
        XCTAssertEqual(available.map(\.id), [FullGameStore.productID])
        await store.loadProduct()
        let product = try XCTUnwrap(store.product)
        XCTAssertEqual(product.id, FullGameStore.productID)
        XCTAssertEqual(product.price, Decimal(string: "1.99"))
        XCTAssertTrue(product.displayPrice.contains("€"), product.displayPrice)
        XCTAssertTrue(product.isFamilyShareable)

        let message = await store.purchase()
        XCTAssertNil(message)
        XCTAssertTrue(store.isUnlocked)

        let reopened = FullGameStore()
        await reopened.prepare()
        XCTAssertTrue(reopened.isUnlocked)
    }

    private func makeAllowance() throws -> (DailyRoundAllowance, String) {
        let suite = "PlayAccessTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Helsinki"))
        return (DailyRoundAllowance(defaults: defaults, calendar: calendar), suite)
    }
}
