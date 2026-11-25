import Foundation

struct DailyRoundAllowance {
    static let freeRoundsPerDay = 10
    static let roundsPerReviewRequest = 8

    private static let dayKey = "roundAllowance.day"
    private static let reviewKey = "roundAllowance.review"

    var defaults: UserDefaults = .standard
    var calendar: Calendar = .autoupdatingCurrent

    func canStartRound(isUnlocked: Bool, at date: Date = .now) -> Bool {
        isUnlocked || roundsStarted(on: date) < Self.freeRoundsPerDay
    }

    func startRound(isUnlocked: Bool, at date: Date = .now) -> Bool {
        if isUnlocked { return true }
        let started = roundsStarted(on: date)
        guard started < Self.freeRoundsPerDay else { return false }
        defaults.set(["date": date, "count": started + 1], forKey: Self.dayKey)
        return true
    }

    func recordCompletedRound(isUnlocked: Bool) {
        guard !isUnlocked else { return }
        let count = completedFreeRounds + 1
        defaults.set(["completed": count, "lastRequested": lastRequestedRound], forKey: Self.reviewKey)
    }

    func takeReviewRequest(isUnlocked: Bool) -> Bool {
        guard !isUnlocked else { return false }
        let completed = completedFreeRounds
        let milestone = completed - completed % Self.roundsPerReviewRequest
        guard milestone > lastRequestedRound else { return false }
        defaults.set(["completed": completed, "lastRequested": milestone], forKey: Self.reviewKey)
        return true
    }

    private func roundsStarted(on date: Date) -> Int {
        guard let data = defaults.dictionary(forKey: Self.dayKey),
              let savedDate = data["date"] as? Date,
              calendar.isDate(savedDate, inSameDayAs: date) else { return 0 }
        return data["count"] as? Int ?? 0
    }

    private var completedFreeRounds: Int {
        defaults.dictionary(forKey: Self.reviewKey)?["completed"] as? Int ?? 0
    }

    private var lastRequestedRound: Int {
        defaults.dictionary(forKey: Self.reviewKey)?["lastRequested"] as? Int ?? 0
    }
}
