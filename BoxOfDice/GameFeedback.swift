//
//  GameFeedback.swift
//  BoxOfDice
//

import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
protocol GameFeedbackProviding: AnyObject {
    func tileSelected()
    func validMoveConfirmed()
    func invalidAction()
    func boardCleared()
    func playDiceRoll()
    func playTileFlip()
}

@MainActor
final class NoOpGameFeedback: GameFeedbackProviding {
    static let shared = NoOpGameFeedback()

    private init() {}

    func tileSelected() {}
    func validMoveConfirmed() {}
    func invalidAction() {}
    func boardCleared() {}
    func playDiceRoll() {}
    func playTileFlip() {}
}

@MainActor
final class GameFeedback: GameFeedbackProviding {
    static let shared = GameFeedback()

    private var players: [Sound: AVAudioPlayer] = [:]

    #if canImport(UIKit)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif

    private init() {
        // Configure session once so sounds play consistently regardless of device state.
        // .ambient mixes with background audio and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func tileSelected() {
        #if canImport(UIKit)
        lightImpact.prepare()
        lightImpact.impactOccurred()
        #endif
    }

    func validMoveConfirmed() {
        #if canImport(UIKit)
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
        #endif
    }

    func invalidAction() {
        #if canImport(UIKit)
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
        #endif
    }

    func boardCleared() {
        #if canImport(UIKit)
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }

    func playDiceRoll() {
        play(.diceRoll)
    }

    func playTileFlip() {
        play(.tileFlip)
    }

    private func play(_ sound: Sound) {
        do {
            let player: AVAudioPlayer
            if let url = Bundle.main.url(forResource: sound.resourceName, withExtension: sound.fileExtension) {
                player = try AVAudioPlayer(contentsOf: url)
            } else {
                player = try AVAudioPlayer(data: sound.generatedWAVData())
            }

            player.volume = sound.volume
            player.prepareToPlay()
            player.play()
            players[sound] = player
        } catch {
            assertionFailure("Unable to play sound: \(sound.fileName)")
        }
    }
}

private enum Sound: Hashable {
    case diceRoll
    case tileFlip

    var resourceName: String {
        switch self {
        case .diceRoll:
            return "dicesound1"
        case .tileFlip:
            return "tile-flip"
        }
    }

    var fileExtension: String {
        switch self {
        case .diceRoll: return "aiff"
        case .tileFlip: return "wav"
        }
    }

    var fileName: String { "\(resourceName).\(fileExtension)" }

    var volume: Float {
        switch self {
        case .diceRoll:
            return 0.35
        case .tileFlip:
            return 0.28
        }
    }

    func generatedWAVData() -> Data {
        let sampleRate = 44_100
        let samples: [Int16]

        switch self {
        case .diceRoll:
            samples = Self.diceRollSamples(sampleRate: sampleRate)
        case .tileFlip:
            samples = Self.tileFlipSamples(sampleRate: sampleRate)
        }

        return Self.wavData(samples: samples, sampleRate: sampleRate)
    }

    private static func diceRollSamples(sampleRate: Int) -> [Int16] {
        let duration = 0.42
        let count = Int(Double(sampleRate) * duration)
        var samples: [Int16] = []
        samples.reserveCapacity(count)

        var randomState: UInt64 = 0xB0D1CE
        let clickSpacing = Int(Double(sampleRate) * 0.055)

        for index in 0..<count {
            randomState = randomState &* 6364136223846793005 &+ 1442695040888963407
            let noise = Double(Int(randomState >> 56) - 128) / 128.0
            let progress = Double(index) / Double(count)
            let envelope = pow(1.0 - progress, 1.7) * 0.34
            let click = index % clickSpacing < 900 ? sin(Double(index) * 0.42) * 0.25 : 0
            let value = (noise * envelope) + (click * envelope)
            samples.append(Self.clampedSample(value))
        }

        return samples
    }

    private static func tileFlipSamples(sampleRate: Int) -> [Int16] {
        let duration = 0.22
        let count = Int(Double(sampleRate) * duration)
        var samples: [Int16] = []
        samples.reserveCapacity(count)

        for index in 0..<count {
            let time = Double(index) / Double(sampleRate)
            let progress = Double(index) / Double(count)
            let clickEnvelope = exp(-progress * 18.0)
            let thudEnvelope = exp(-progress * 8.0)
            let click = sin(2.0 * .pi * 1_450.0 * time) * clickEnvelope * 0.30
            let thud = sin(2.0 * .pi * 145.0 * time) * thudEnvelope * 0.22
            let value = click + thud
            samples.append(Self.clampedSample(value))
        }

        return samples
    }

    private static func clampedSample(_ value: Double) -> Int16 {
        let clamped = max(-1.0, min(1.0, value))
        return Int16(clamped * Double(Int16.max))
    }

    private static func wavData(samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        let bytesPerSample = 2
        let channelCount = 1
        let byteRate = sampleRate * channelCount * bytesPerSample
        let blockAlign = channelCount * bytesPerSample
        let subchunk2Size = samples.count * bytesPerSample
        let chunkSize = 36 + subchunk2Size

        data.appendASCII("RIFF")
        data.appendUInt32LE(UInt32(chunkSize))
        data.appendASCII("WAVE")
        data.appendASCII("fmt ")
        data.appendUInt32LE(16)
        data.appendUInt16LE(1)
        data.appendUInt16LE(UInt16(channelCount))
        data.appendUInt32LE(UInt32(sampleRate))
        data.appendUInt32LE(UInt32(byteRate))
        data.appendUInt16LE(UInt16(blockAlign))
        data.appendUInt16LE(16)
        data.appendASCII("data")
        data.appendUInt32LE(UInt32(subchunk2Size))

        for sample in samples {
            data.appendInt16LE(sample)
        }

        return data
    }
}

private extension Data {
    mutating func appendASCII(_ string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func appendUInt16LE(_ value: UInt16) {
        append(contentsOf: [UInt8(value & 0x00FF), UInt8((value >> 8) & 0x00FF)])
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(contentsOf: [
            UInt8(value & 0x000000FF),
            UInt8((value >> 8) & 0x000000FF),
            UInt8((value >> 16) & 0x000000FF),
            UInt8((value >> 24) & 0x000000FF)
        ])
    }

    mutating func appendInt16LE(_ value: Int16) {
        appendUInt16LE(UInt16(bitPattern: value))
    }
}

// Optional production assets:
// Add subtle, short audio files to the app target to replace generated placeholders:
// - dice-roll.wav for the dice roll loop/click sound
// - tile-flip.wav for the wooden tile flip sound
// If those files are absent, GameFeedback generates simple WAV sounds in memory.
// A future watchOS target can provide a WatchKit-backed GameFeedbackProviding adapter,
// or use NoOpGameFeedback.shared while still reusing GameEngine and GameViewModel.
