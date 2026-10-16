//
//  PuzzleLevel.swift
//  Orbito
//
//  Created by Jordan Westlund on 7/1/26.
//

import SwiftUI

struct PuzzleLevel {
    let id: Int
    let chamberName: String
    let grid: [[OrbType?]]
    let shotQueue: [OrbType]
    let parShots: Int
    let twoStarShots: Int
    let oneStarShots: Int

    // 3★ limit. When nil, 3★ = at or under par (tutorial behavior).
    // Chambers set this one under par, so par itself earns 2★.
    var threeStarShots: Int? = nil

    // Narrow "shaft" boards: playable width in orb slots (e.g. 4 or 5).
    // Even rows hold `columns` orbs, odd rows hold `columns - 1`.
    // Leave nil for a standard board — existing levels don't need to set it.
    var columns: Int? = nil
}
