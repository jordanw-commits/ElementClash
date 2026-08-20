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
}
