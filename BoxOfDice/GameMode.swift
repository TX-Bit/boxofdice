//
//  GameMode.swift
//  BoxOfDice
//

import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case speedRun
    case bigBox
    case bigBoxSpeed
    case passAndPlay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:     return "Classic"
        case .speedRun:    return "Speed Run"
        case .bigBox:      return "Big Box"
        case .bigBoxSpeed: return "Big Box Speed"
        case .passAndPlay: return "Pass & Play"
        }
    }

    var subtitle: String {
        switch self {
        case .classic:     return "12 tiles · 2 dice · lowest score wins"
        case .speedRun:    return "12 tiles · 2 dice · score + elapsed seconds"
        case .bigBox:      return "18 tiles · 3 dice · lowest score wins"
        case .bigBoxSpeed: return "18 tiles · 3 dice · score + elapsed seconds"
        case .passAndPlay: return "2–4 players · each plays one Classic round"
        }
    }

    var tileCount: Int {
        switch self {
        case .classic, .speedRun, .passAndPlay: return 12
        case .bigBox, .bigBoxSpeed:             return 18
        }
    }

    var baseDiceCount: Int {
        switch self {
        case .classic, .speedRun, .passAndPlay: return 2
        case .bigBox, .bigBoxSpeed:             return 3
        }
    }

    var isTimed: Bool {
        self == .speedRun || self == .bigBoxSpeed
    }

    var isMultiplayer: Bool {
        self == .passAndPlay
    }

    var group: Group {
        switch self {
        case .classic, .speedRun:   return .classic
        case .bigBox, .bigBoxSpeed: return .bigBox
        case .passAndPlay:          return .multiplayer
        }
    }

    func finalScore(baseScore: Int, elapsedSeconds: Int) -> Int {
        baseScore + (isTimed ? elapsedSeconds : 0)
    }

    enum Group: String {
        case classic     = "Classic"
        case bigBox      = "Big Box"
        case multiplayer = "Multiplayer"
    }
}
