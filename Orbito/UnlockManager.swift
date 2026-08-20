//
//  UnlockManager.swift
//  Orbito
//
//  Created by Jordan Westlund on 8/12/26.
//

import Foundation

final class UnlockManager {
    static let shared = UnlockManager()
    private let defaults = UserDefaults.standard
    private init() {}

    var classicEasyWins: Int {
        get { defaults.integer(forKey: "classicEasyWins") }
        set { defaults.set(newValue, forKey: "classicEasyWins") }
    }
    var classicMediumWins: Int {
        get { defaults.integer(forKey: "classicMediumWins") }
        set { defaults.set(newValue, forKey: "classicMediumWins") }
    }
    var classicHardWins: Int {
        get { defaults.integer(forKey: "classicHardWins") }
        set { defaults.set(newValue, forKey: "classicHardWins") }
    }
    var counterEasyWins: Int {
        get { defaults.integer(forKey: "counterEasyWins") }
        set { defaults.set(newValue, forKey: "counterEasyWins") }
    }
    var counterMediumWins: Int {
        get { defaults.integer(forKey: "counterMediumWins") }
        set { defaults.set(newValue, forKey: "counterMediumWins") }
    }

    var classicMediumUnlocked: Bool { classicEasyWins >= 1 }
    var classicHardUnlocked: Bool { classicMediumWins >= 1 }
    var counterEasyUnlocked: Bool { classicHardWins >= 1 }
    var counterMediumUnlocked: Bool { counterEasyWins >= 1 }
    var counterHardUnlocked: Bool { counterMediumWins >= 1 }

    func isUnlocked(mode: GameMode, difficulty: Difficulty) -> Bool {
        switch (mode, difficulty) {
        case (.classic, .easy):   return true
        case (.classic, .medium): return classicMediumUnlocked
        case (.classic, .hard):   return classicHardUnlocked
        case (.counter, .easy):   return counterEasyUnlocked
        case (.counter, .medium): return counterMediumUnlocked
        case (.counter, .hard):   return counterHardUnlocked
        }
    }

    func recordWin(mode: GameMode, difficulty: Difficulty) {
        switch (mode, difficulty) {
        case (.classic, .easy):   classicEasyWins += 1
        case (.classic, .medium): classicMediumWins += 1
        case (.classic, .hard):   classicHardWins += 1
        case (.counter, .easy):   counterEasyWins += 1
        case (.counter, .medium): counterMediumWins += 1
        case (.counter, .hard):   counterMediumWins += 1
        }
    }

    func winsNeeded(mode: GameMode, difficulty: Difficulty) -> String {
        switch (mode, difficulty) {
        case (.classic, .medium): return "Win \(classicEasyWins)/1 Classic Easy game"
        case (.classic, .hard):   return "Win \(classicMediumWins)/1 Classic Medium game"
        case (.counter, .easy):   return "Win \(classicHardWins)/1 Classic Hard game"
        case (.counter, .medium): return "Win \(counterEasyWins)/1 Counter Easy game"
        case (.counter, .hard):   return "Win \(counterMediumWins)/1 Counter Medium game"
        default: return ""
        }
    }
}
