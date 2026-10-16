//
//  PuzzleLevels.swift
//  Orbito
//
//  Created by Jordan Westlund on 7/1/26.
//

struct PuzzleLevels {
    static let all: [PuzzleLevel] = [

        PuzzleLevel(
            id: 1,
            chamberName: "Water Beats Fire",
            grid: [
                [.ember, .ember, nil,   .ember, .ember, nil,   .ember, .ember],
                [nil,   .ember, nil,   nil,   .ember, nil,   nil,   .ember],
                [.ember, .ember, nil,   .ember, .ember, nil,   .ember, .ember],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 2,
            chamberName: "Fire Beats Plant",
            grid: [
                [.sprout, .sprout, nil,   .sprout, .sprout, nil,   .sprout, .sprout],
                [nil,   .sprout, nil,   nil,   .sprout, nil,   nil,   .sprout],
                [.sprout, .sprout, nil,   .sprout, .sprout, nil,   .sprout, .sprout],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.ember,.ember,.ember,.ember,.ember,.ember,.ember,.ember,.ember,.ember],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 3,
            chamberName: "Plant Beats Water",
            grid: [
                [.tide, .tide, nil,   .tide, .tide, nil,   .tide, .tide],
                [nil,   .tide, nil,   nil,   .tide, nil,   nil,   .tide],
                [.tide, .tide, nil,   .tide, .tide, nil,   .tide, .tide],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.sprout,.sprout,.sprout,.sprout,.sprout,.sprout,.sprout,.sprout,.sprout,.sprout],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 4,
            chamberName: "Electric Beats Water",
            grid: [
                [.tide, .tide, nil,   .tide, .tide, nil,   .tide, .tide],
                [nil,   .tide, nil,   nil,   .tide, nil,   nil,   .tide],
                [.tide, .tide, nil,   .tide, .tide, nil,   .tide, .tide],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.electric,.electric,.electric,.electric,.electric,.electric,.electric,.electric,.electric,.electric],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 5,
            chamberName: "Rock Beats Electric",
            grid: [
                [.electric, .electric, nil,   .electric, .electric, nil,   .electric, .electric],
                [nil,   .electric, nil,   nil,   .electric, nil,   nil,   .electric],
                [.electric, .electric, nil,   .electric, .electric, nil,   .electric, .electric],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.boulder,.boulder,.boulder,.boulder,.boulder,.boulder,.boulder,.boulder,.boulder,.boulder],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 6,
            chamberName: "Water Beats Rock",
            grid: [
                [.boulder, .boulder, nil,   .boulder, .boulder, nil,   .boulder, .boulder],
                [nil,   .boulder, nil,   nil,   .boulder, nil,   nil,   .boulder],
                [.boulder, .boulder, nil,   .boulder, .boulder, nil,   .boulder, .boulder],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil],
                [nil,   nil,   nil,   nil,   nil,   nil,   nil],
            ],
            shotQueue: [.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 8,
            threeStarShots: 2
        ),

        // Chamber: The Element Wave (full 10-wide board) — Jordan's layout.
        // Five diagonal ribbons, one per element, hanging from the ceiling.
        PuzzleLevel(
            id: 7,
            chamberName: "The Element Wave",
            grid: [
                [.tide,      nil,        .ember,     nil,        .sprout,    nil,        .electric,  nil,        .boulder,   nil],
                [.tide,      nil,        .ember,     nil,        .sprout,    nil,        .electric,  nil,        .boulder],
                [nil,        .tide,      nil,        .ember,     nil,        .sprout,    nil,        .electric,  nil,        .boulder],
                [nil,        .tide,      nil,        .ember,     nil,        .sprout,    nil,        .electric,  nil],
                [nil,        nil,        .tide,      nil,        .ember,     nil,        .sprout,    nil,        .electric,  nil]
            ],
            shotQueue: [.sprout, .tide, .ember, .boulder, .tide, .sprout, .tide, .ember, .boulder, .tide],
            parShots: 6,
            twoStarShots: 6,
            oneStarShots: 10,
            threeStarShots: 5,
            columns: 10
        ),

        PuzzleLevel(
            id: 8,
            chamberName: "The Ember Vault",
            grid: [
                [.ember, .ember, nil, .ember, nil, nil, nil, nil],
                [.sprout, .ember, .ember, nil, .sprout, nil, nil],
                [.ember, .sprout, .sprout, .ember, .sprout, nil, nil, nil],
                [nil, .ember, .sprout, .sprout, .sprout, nil, nil],
                [nil, nil, .ember, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil]
            ],
            shotQueue: [.tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide],
            parShots: 2,
            twoStarShots: 2,
            oneStarShots: 10,
            threeStarShots: 1
        ),

        PuzzleLevel(
            id: 9,
            chamberName: "The Sunken Quarry",
            grid: [
                [.boulder, .ember,   .boulder, nil,     nil,   nil,   nil,   nil],
                [nil,      .boulder, .ember,   .boulder, nil,   nil,   nil,   nil],
                [.ember,   nil,      .boulder, nil,     .ember, nil,   nil,   nil],
                [.boulder, .ember,   nil,      .boulder, nil,   nil,   nil,   nil],
                [nil,      nil,      .ember,   nil,     .boulder, nil, nil,   nil],
                [nil,      nil,      nil,      nil,     nil,   nil,   nil,   nil]
            ],
            shotQueue: [.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide,.tide],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 12,
            threeStarShots: 2
        ),

        PuzzleLevel(
            id: 10,
            chamberName: "The Tangled Grove",
            grid: [
                [.tide,   .sprout, .tide,   .sprout, nil,    nil,   nil,   nil],
                [.sprout, nil,     .sprout, .tide,   .sprout, nil,  nil,   nil],
                [nil,     .tide,   nil,     .sprout, .sprout, nil,  nil,   nil],
                [.sprout, .sprout, .tide,   nil,     nil,    nil,   nil,   nil],
                [nil,     nil,     .sprout, .tide,   nil,    nil,   nil,   nil],
                [nil,     nil,     nil,     nil,     nil,    nil,   nil,   nil]
            ],
            shotQueue: [.ember,.sprout,.ember,.sprout,.ember,.sprout,.ember,.sprout,.ember,.sprout,.ember],
            parShots: 4,
            twoStarShots: 4,
            oneStarShots: 11,
            threeStarShots: 3
        ),

        // Narrow "shaft" board (6 wide). Normal orbs can't be countered; they only clear by dropping.
        // The Normal stalactite sticks out almost to the walls, leaving thin side lanes,
        // and ends in a single-orb zigzag tail that hangs low into the shaft.
        // Straight shots stick to the Normals — thread a Water shot up a side lane
        // to touch the Rock group and drop everything.
        // Simulated winning aim window ≈ 4° (both sides). Any longer and a side lane closes.
        PuzzleLevel(
            id: 11,
            chamberName: "The Needle",
            grid: [
                [nil, .boulder, .boulder, .boulder, .boulder, nil],
                [nil, .normal,  .normal,  .normal,  nil],
                [nil, nil,      .normal,  .normal,  nil,      nil],
                [nil, .normal,  .normal,  .normal,  nil],
                [nil, nil,      .normal,  .normal,  nil,      nil],
                [nil, .normal,  .normal,  .normal,  nil],
                [nil, nil,      .normal,  .normal,  nil,      nil],
                [nil, nil,      .normal,  nil,      nil],
                [nil, nil,      .normal,  nil,      nil,      nil],
                [nil, nil,      .normal,  nil,      nil],
                [nil, nil,      nil,      .normal,  nil,      nil],
                [nil, nil,      .normal,  nil,      nil]
            ],
            shotQueue: [.tide, .tide, .tide, .tide],
            parShots: 2,
            twoStarShots: 2,
            oneStarShots: 4,
            threeStarShots: 1,
            columns: 6
        ),

        PuzzleLevel(
            id: 12,
            chamberName: "The Storm Basin",
            grid: [
                [.tide,     .tide,     .electric, .tide,     nil,   nil,   nil,   nil],
                [.electric, .tide,     nil,       .electric, .tide, nil,   nil,   nil],
                [nil,       .electric, .tide,     nil,       .tide, nil,   nil,   nil],
                [.tide,     nil,       .electric, .tide,     nil,   nil,   nil,   nil],
                [.electric, .tide,     nil,       nil,       .electric, nil, nil, nil],
                [nil,       nil,       nil,       nil,       nil,   nil,   nil,   nil]
            ],
            shotQueue: [.electric,.boulder,.electric,.boulder,.electric,.boulder,.electric,.boulder,.electric,.boulder,.electric,.boulder],
            parShots: 5,
            twoStarShots: 5,
            oneStarShots: 12,
            threeStarShots: 4
        ),

        // Chamber: The Shell (full 10-wide board, edge to edge) — Jordan's layout.
        // Fire shell on the left ceiling holds a Normal shell around two Water orbs;
        // a Plant column hangs from the top-right corner against the wall.
        // Simulated: best = 4 shots.
        PuzzleLevel(
            id: 13,
            chamberName: "The Shell",
            grid: [
                [.ember,   .ember,   .ember,   nil,      nil,      nil,      nil,      nil,      nil,      .sprout],
                [.normal,  .ember,   .normal,  nil,      nil,      nil,      nil,      nil,      .sprout],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      nil,      .sprout],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      .sprout],
                [.normal,  .tide,    .tide,    nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .tide,    nil,      nil,      nil,      nil,      nil,      nil,      nil],
                [.normal,  .normal,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil],
                [.sprout,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil],
                [nil,      nil,      .normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil]
            ],
            shotQueue: [.ember, .sprout, .ember, .tide, .sprout, .tide, .sprout, .tide, .sprout, .tide],
            parShots: 5,
            twoStarShots: 5,
            oneStarShots: 10,
            threeStarShots: 4,
            columns: 10
        ),

        // The Ricochet (6 wide) — Jordan's layout.
        // A Rock in each top corner. The top-right Rock holds a diagonal of 8 Normals
        // running down-left that shields it. Corner Rock: straight or banked (easy).
        // Top-right Rock: the "perfect bounce" — left-right-left (≈1.9°) or
        // right-then-left (≈1.1°). Breaking it drops all the Normals.
        // Simulated: best = 2 shots (either order).
        PuzzleLevel(
            id: 14,
            chamberName: "The Ricochet",
            grid: [
                [.boulder, nil, nil,     nil,     .boulder, .boulder],
                [.normal,  nil, nil,     nil,     .normal],
                [nil,      nil, nil,     nil,     .normal, nil],
                [nil,      nil, nil,     .normal, nil],
                [nil,      nil, nil,     .normal, .normal, .normal],
                [nil,      nil, .normal, .normal, nil]
            ],
            shotQueue: [.tide, .tide, .tide, .tide, .tide],
            parShots: 3,
            twoStarShots: 3,
            oneStarShots: 5,
            threeStarShots: 2,
            columns: 6
        ),

        PuzzleLevel(
            id: 15,
            chamberName: "The Elemental Nexus",
            grid: [
                [.boulder,  .electric, .tide,    .boulder,  .electric, nil,   nil,   nil],
                [.electric, .tide,     .boulder, .electric, .tide,     nil,   nil,   nil],
                [.tide,     .boulder,  .electric, .tide,    .boulder,  nil,   nil,   nil],
                [.boulder,  .electric, .tide,    .boulder,  nil,       nil,   nil,   nil],
                [.electric, .tide,     .boulder, nil,       nil,       nil,   nil,   nil],
                [nil,       nil,       nil,      nil,       nil,       nil,   nil,   nil]
            ],
            shotQueue: [.tide,.electric,.boulder,.tide,.electric,.boulder,.tide,.electric,.boulder,.tide,.electric,.boulder,.tide,.electric,.boulder],
            parShots: 8,
            twoStarShots: 8,
            oneStarShots: 9,
            threeStarShots: 7
        ),

        // Chamber: The Elemental Path (full 10-wide board) — Jordan's layout.
        // Layered bands all hanging from two Electric orbs in the top-right corner.
        // The Rock (shot 5) is the only thing that breaks the Electric, so every clear uses all 5 shots.
        PuzzleLevel(
            id: 16,
            chamberName: "The Elemental Path",
            grid: [
                [nil,        nil,        nil,        nil,        nil,        nil,        nil,        nil,        .electric,  .electric],
                [.tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .normal,    .normal],
                [.normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .tide,      .normal,    .normal],
                [.boulder,   .boulder,   .boulder,   .boulder,   .boulder,   .boulder,   .boulder,   .boulder,   .boulder],
                [.normal,    .normal,    .normal,    .boulder,   .normal,    .normal,    .normal,    .normal,    .normal,    .normal],
                [.ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember],
                [.normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .ember,     .normal,    .normal],
                [.sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout],
                [.normal,    .normal,    .sprout,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal]
            ],
            shotQueue: [.ember, .tide, .tide, .sprout, .boulder, .boulder, .boulder, .boulder, .boulder],
            parShots: 6,
            twoStarShots: 6,
            oneStarShots: 7,
            threeStarShots: 5,
            columns: 10
        ),

        // Chamber: The Channel (full 10-wide board) — Jordan's layout.
        // Everything hangs from one Water orb on the ceiling: a Fire column, a Normal crossbar,
        // then a Plant column and a Normal base. Simulated: best = 3 shots.
        PuzzleLevel(
            id: 17,
            chamberName: "The Channel",
            grid: [
                [nil,      nil,      nil,      nil,      nil,      .tide,    nil,      nil,      nil,      nil],
                [nil,      nil,      nil,      .normal,  .ember,   .ember,   .normal,  nil,      nil],
                [nil,      nil,      nil,      nil,      nil,      .ember,   nil,      nil,      nil,      nil],
                [nil,      nil,      nil,      nil,      .ember,   .ember,   nil,      nil,      nil],
                [nil,      nil,      .normal,  .normal,  .normal,  .ember,   .normal,  .normal,  .normal,  nil],
                [nil,      nil,      nil,      nil,      .sprout,  .sprout,  nil,      nil,      nil],
                [nil,      nil,      nil,      nil,      nil,      .sprout,  nil,      nil,      nil,      nil],
                [nil,      nil,      nil,      .normal,  .normal,  .normal,  .normal,  nil,      nil]
            ],
            shotQueue: [.ember, .tide, .sprout, .ember, .tide, .sprout, .ember, .tide, .sprout],
            parShots: 4,
            twoStarShots: 4,
            oneStarShots: 9,
            threeStarShots: 3,
            columns: 10
        ),

        // Chamber: The Rock Wall (full 10-wide board) — Jordan's layout.
        // Rock anchors at the corners and center, Normal and Plant hanging below, Water-only queue.
        PuzzleLevel(
            id: 18,
            chamberName: "The Rock Wall",
            grid: [
                [.boulder,  nil,       nil,       nil,       .boulder,  .boulder,  nil,       nil,       nil,       .boulder],
                [.boulder,  nil,       nil,       nil,       .normal,   .normal,   nil,       nil,       .boulder],
                [.normal,   nil,       nil,       nil,       .boulder,  .boulder,  nil,       nil,       nil,       .normal],
                [.sprout,   nil,       nil,       nil,       .normal,   .normal,   nil,       nil,       .sprout]
            ],
            shotQueue: [.tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide],
            parShots: 4,
            twoStarShots: 4,
            oneStarShots: 10,
            threeStarShots: 3,
            columns: 10
        ),

        // Chamber: The Water Fort (full 10-wide board) — Jordan's layout.
        // A pyramid of Fire, Electric and Normal layers hanging from one Water orb.
        PuzzleLevel(
            id: 19,
            chamberName: "The Water Fort",
            grid: [
                [nil,        nil,        nil,        .tide,      nil,        nil,        nil,        nil,        nil,        nil],
                [nil,        nil,        .normal,    .normal,    nil,        nil,        nil,        nil,        nil],
                [nil,        nil,        .ember,     .ember,     .ember,     nil,        nil,        nil,        nil,        nil],
                [nil,        .normal,    .normal,    .normal,    nil,        nil,        nil,        nil,        nil],
                [nil,        .electric,  .electric,  .electric,  .electric,  .electric,  nil,        nil,        nil,        nil],
                [.normal,    .normal,    .normal,    .normal,    .normal,    .boulder,   nil,        nil,        nil]
            ],
            shotQueue: [.tide, .boulder, .tide, .sprout, .sprout, .sprout, .sprout],
            parShots: 5,
            twoStarShots: 5,
            oneStarShots: 6,
            threeStarShots: 4,
            columns: 10
        ),

        // Chamber: The Combo Shaft (6-wide shaft) — Jordan's layout.
        // Electric column on the left, Plant column on the right, Water/Rock bridge across the middle.
        PuzzleLevel(
            id: 20,
            chamberName: "The Combo Shaft",
            grid: [
                [.electric,  nil,        nil,        nil,        nil,        .sprout],
                [.electric,  nil,        nil,        nil,        .sprout],
                [.normal,    .normal,    .tide,      .boulder,   .normal,    .normal],
                [.tide,      .tide,      nil,        .boulder,   .boulder],
                [.tide,      nil,        nil,        nil,        nil,        .boulder],
                [.normal,    nil,        nil,        nil,        .normal],
                [.electric,  nil,        nil,        nil,        nil,        .sprout]
            ],
            shotQueue: [.electric, .tide, .ember, .boulder, .ember, .boulder, .ember, .boulder, .ember, .boulder],
            parShots: 5,
            twoStarShots: 5,
            oneStarShots: 10,
            threeStarShots: 4,
            columns: 6
        ),

        // Chamber: The Inferno (full 10-wide board) — Jordan's layout.
        // A Fire/Electric checkerboard in a Normal frame, hanging from an Electric, Fire and Plant ceiling.
        PuzzleLevel(
            id: 21,
            chamberName: "The Inferno",
            grid: [
                [nil,        nil,        nil,        .electric,  .ember,     .sprout,    .sprout,    .sprout,    .sprout,    .sprout],
                [nil,        nil,        nil,        .electric,  .ember,     .normal,    .normal,    .normal,    .sprout],
                [nil,        nil,        nil,        nil,        .electric,  .ember,     .electric,  .ember,     .sprout,    .normal],
                [nil,        nil,        nil,        nil,        .electric,  .ember,     .electric,  .ember,     .normal],
                [nil,        nil,        nil,        nil,        nil,        .electric,  .ember,     .electric,  .electric,  .normal],
                [nil,        nil,        nil,        nil,        nil,        .electric,  .ember,     .electric,  .normal],
                [nil,        nil,        nil,        nil,        .ember,     .electric,  .ember,     .electric,  .electric,  .normal],
                [nil,        nil,        nil,        nil,        .ember,     .electric,  .ember,     .electric,  .normal],
                [nil,        nil,        nil,        nil,        .ember,     .ember,     .electric,  .normal,    .normal,    .normal],
                [nil,        nil,        .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal]
            ],
            shotQueue: [.tide, .boulder, .tide, .boulder, .ember, .boulder, .tide, .ember, .ember, .ember],
            parShots: 6,
            twoStarShots: 6,
            oneStarShots: 7,
            threeStarShots: 5,
            columns: 10
        ),

        // Chamber: The Plant Factory (full 10-wide board) — Jordan's layout.
        // Plant ceiling holding a Normal frame with Plant links, Fire-only queue.
        PuzzleLevel(
            id: 22,
            chamberName: "The Plant Factory",
            grid: [
                [.sprout,  .sprout,  .sprout,  .sprout,  .sprout,  .sprout,  .sprout,  .sprout,  .sprout,  .sprout],
                [.sprout,  nil,      .normal,  .normal,  .normal,  .normal,  .normal,  .normal,  .normal],
                [nil,      .sprout,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.sprout,      .normal,  nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [nil,      .normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.sprout,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      .sprout],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.normal,  .normal,  .normal,  .normal,  nil,      nil,      nil,      nil,      .normal]
            ],
            shotQueue: [.ember, .ember, .ember, .ember, .ember, .ember, .ember, .ember, .ember, .ember],
            parShots: 4,
            twoStarShots: 4,
            oneStarShots: 10,
            threeStarShots: 3,
            columns: 10
        ),

        // Chamber: The Rock Fort (full 10-wide board) — Jordan's layout.
        // Normal walls on Rock corners (with Rock links), Rock and Electric core.
        PuzzleLevel(
            id: 23,
            chamberName: "The Rock Fort",
            grid: [
                [.boulder,   .boulder,   nil,        nil,        .boulder,   .boulder,   nil,        nil,        .boulder,   .boulder],
                [.normal,    nil,        nil,        .boulder,   .normal,    .boulder,   nil,        nil,        .normal],
                [.normal,    nil,        nil,        nil,        .boulder,   .boulder,   nil,        nil,        nil,        .normal],
                [.normal,    nil,        nil,        nil,        .normal,    nil,        nil,        nil,        .normal],
                [.normal,    nil,        nil,        .electric,  .electric,  .electric,  .electric,  nil,        nil,        .normal],
                [.boulder,   nil,        nil,        nil,        .normal,    nil,        nil,        nil,        .boulder],
                [.normal,    nil,        nil,        nil,        .electric,  .electric,  nil,        nil,        nil,        .normal],
                [.normal,    nil,        nil,        nil,        .electric,  nil,        nil,        nil,        .normal],
                [.normal,    nil,        .normal,    nil,        nil,        nil,        nil,        .normal,    nil,        .normal],
                [.normal,    .normal,    .normal,    nil,        nil,        nil,        .normal,    .normal,    .normal]
            ],
            shotQueue: [.boulder, .boulder, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide],
            parShots: 8,
            twoStarShots: 8,
            oneStarShots: 10,
            threeStarShots: 7,
            columns: 10
        ),

        // Chamber: The Flame Agenda (full 10-wide board) — Jordan's layout.
        // Fire flame in the middle, Normal pillars hanging from the corner Fires, Water-only queue.
        PuzzleLevel(
            id: 24,
            chamberName: "The Flame Agenda",
            grid: [
                [.ember,   nil,      nil,      nil,      .ember,   .ember,   nil,      nil,      nil,      .ember],
                [.normal,  nil,      nil,      .ember,   .normal,  .ember,   nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      .ember,   .ember,   nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      .normal,  nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      .ember,   .ember,   .ember,   .ember,   nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      .normal,  nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      .ember,   .ember,   nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      .ember,   nil,      nil,      nil,      .normal],
                [.normal,  nil,      nil,      nil,      nil,      nil,      nil,      nil,      nil,      .normal],
                [.ember,   .normal,  .normal,  nil,      nil,      nil,      .normal,  .normal,  .ember]
            ],
            shotQueue: [.tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide, .tide],
            parShots: 7,
            twoStarShots: 7,
            oneStarShots: 8,
            threeStarShots: 6,
            columns: 10
        ),

        // Chamber: The Orb Center (full 10-wide board) — Jordan's layout.
        // A Normal ring hanging from two Water orbs at the ceiling, with a Fire and a Water inside the frame.
        PuzzleLevel(
            id: 25,
            chamberName: "The Orb Center",
            grid: [
                [nil,      nil,      nil,      nil,      nil,      .tide,    .tide,    nil,      nil,      nil],
                [nil,      nil,      nil,      nil,      .normal,  .normal,  .normal,  nil,      nil],
                [nil,      nil,      nil,      .normal,  .normal,  nil,      nil,      .normal,  nil,      nil],
                [.normal,  .normal,  .normal,  nil,      nil,      nil,      nil,      .tide,    nil],
                [nil,      nil,      nil,      .normal,  .normal,  .normal,  .normal,  .normal,  .tide  ,  nil],
                [nil,      nil,      .ember,   nil,      nil,      nil,      nil,      nil,      nil],
                [nil,      nil,      nil,      .normal,  nil,      nil,      nil,      nil,      .normal,  nil],
                [nil,      nil,      .normal,  nil,      nil,      nil,      nil,      .normal,  nil],
                [nil,      nil,      nil,      .normal,  .normal,  .normal,  .normal,  .normal,  nil,      nil]
            ],
            shotQueue: [.tide, .sprout, .sprout, .tide, .sprout, .sprout, .sprout, .sprout, .sprout, .sprout],
            parShots: 4,
            twoStarShots: 4,
            oneStarShots: 10,
            threeStarShots: 3,
            columns: 10
        ),

        // Chamber: The Crossing (full 10-wide board) — Jordan's layout.
        // Two Normal towers hang from Water at the ceiling corners, joined by Normal crossbars.
        PuzzleLevel(
            id: 26,
            chamberName: "The Crossing",
            grid: [
                [.tide,    .tide,    .tide,    nil,      nil,      nil,      nil,      .tide,    .tide,    .tide],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .normal,  .tide,    .normal,  .normal,  .normal,  .normal,  .tide,    .normal,  .normal],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      .normal,  .normal],
                [.normal,  .normal,  .normal,  .ember,   .ember,   .ember,   .normal,  .normal,  .normal],
                [.normal,  .normal,  nil,      nil,      nil,      nil,      nil,      nil,      .normal,  .normal]
            ],
            shotQueue: [.tide, .sprout, .sprout, .sprout, .sprout, .sprout, .sprout, .sprout, .sprout, .sprout],
            parShots: 6,
            twoStarShots: 6,
            oneStarShots: 10,
            threeStarShots: 5,
            columns: 10
        ),

        // Chamber: The Bridge (full 10-wide board) — Jordan's layout.
        // Full-width bands linked by Normal walls.
        PuzzleLevel(
            id: 27,
            chamberName: "The Bridge",
            grid: [
                [.ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember,     .ember],
                [.normal,    .normal,    .normal,    nil,        nil,        nil,        nil,        .normal,    .normal],
                [.normal,    nil,        nil,        nil,        nil,        nil,        nil,        nil,        nil,        .normal],
                [.normal,    .normal,    .normal,    .normal,    .normal,    .normal,    nil,        nil,        .normal],
                [.tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .tide,      .tide],
                [nil,        .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal],
                [nil,        nil,        nil,        nil,        nil,        nil,        nil,        nil,        nil,        .normal],
                [.electric,  .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout,    .sprout],
                [nil,        .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal,    .normal]
            ],
            shotQueue: [.boulder, .ember, .sprout, .tide, .sprout, .tide, .tide, .tide, .tide, .tide],
            parShots: 5,
            twoStarShots: 5,
            oneStarShots: 10,
            threeStarShots: 4,
            columns: 10
        )
    ]
}
