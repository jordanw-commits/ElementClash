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
            twoStarShots: 5,
            oneStarShots: 8
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
            twoStarShots: 5,
            oneStarShots: 8
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
            twoStarShots: 5,
            oneStarShots: 8
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
            twoStarShots: 5,
            oneStarShots: 8
        ),

        PuzzleLevel(
            id: 5,
            chamberName: "Boulder Beats Electric",
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
            twoStarShots: 5,
            oneStarShots: 8
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
            twoStarShots: 5,
            oneStarShots: 8
        ),

        PuzzleLevel(
            id: 7,
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
            twoStarShots: 3,
            oneStarShots: 4
        ),

        PuzzleLevel(
            id: 8,
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
            twoStarShots: 4,
            oneStarShots: 5
        ),

        PuzzleLevel(
            id: 9,
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
            parShots: 5,
            twoStarShots: 6,
            oneStarShots: 7
        ),

        PuzzleLevel(
            id: 10,
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
            twoStarShots: 6,
            oneStarShots: 7
        ),

        PuzzleLevel(
            id: 11,
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
            parShots: 6,
            twoStarShots: 7,
            oneStarShots: 8
        )
    ]
}
