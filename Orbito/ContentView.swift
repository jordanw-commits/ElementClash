import SwiftUI
import Combine
import AVFoundation

struct ContentView: View {
    @State private var selectedGame: SelectedGame?
    @State private var selectedPuzzle: PuzzleLevel?

    var body: some View {
        ZStack {
            ForEach(OrbType.allCases) { type in
                OrbView(type: type, size: 1)
                    .opacity(0.001)
                    .allowsHitTesting(false)
            }

            if let selectedPuzzle {
                ShooterPrototypeView(
                    initialGameMode: .counter,
                    initialDifficulty: .medium,
                    isAimerEnabled: true,
                    onBackToMenu: {
                        self.selectedPuzzle = nil
                    },
                    puzzleLevel: selectedPuzzle,
                    onNextPuzzle: { nextPuzzle in
                        self.selectedPuzzle = nextPuzzle
                    }
                )
                .id(selectedPuzzle.id)
                } else if let selectedGame {
                ShooterPrototypeView(
                    initialGameMode: selectedGame.mode,
                    initialDifficulty: selectedGame.difficulty,
                    isAimerEnabled: selectedGame.isAimerEnabled,
                    onBackToMenu: {
                        self.selectedGame = nil
                    },
                    puzzleLevel: nil,
                    onNextPuzzle: nil
                )
            } else {
                MainMenuView(
                    onSelectMode: { mode, difficulty, isAimerEnabled in
                        selectedGame = SelectedGame(
                            mode: mode,
                            difficulty: difficulty,
                            isAimerEnabled: isAimerEnabled
                        )
                    },
                    onSelectPuzzle: { _ in
                        // Every time Puzzle Mode is entered from the menu, a new run starts at 0
                        // from the beginning — players don't pick a level.
                        PuzzleRun.shared.score = 0
                        selectedPuzzle = PuzzleRun.startingLevel()
                    }
                )
            }
        }
    }
}

// Puzzle Mode run: the score carries across levels until the player loses or leaves.
final class PuzzleRun {
    static let shared = PuzzleRun()
    private init() { }

    var score: Int = 0
    var aimerEnabled: Bool = true   // chosen when the run starts; locked until the run ends

    static let noAimerBonus = 100

    static func starPoints(for stars: Int) -> Int {
        switch stars {
        case 3: return 500
        case 2: return 300
        case 1: return 200
        default: return 0
        }
    }

    // Called whenever a run ends (lose, quit, or finish the last level).
    // Only no-aimer runs go to the Puzzle leaderboard, matching the regular-play rule.
    // To also accept aimer runs, remove "!aimerEnabled".
    func submitToLeaderboard() {
        guard score > 0, !aimerEnabled else { return }
        GameCenterManager.shared.submitScore(score, toLeaderboard: GameCenterManager.shared.puzzleLeaderboardID)
    }

    // Where a run begins: the first chamber once the tutorials are done, otherwise Tutorial 1.
    static func startingLevel() -> PuzzleLevel? {
        let tutorialsComplete = UserDefaults.standard.bool(forKey: "tutorialsComplete")
        let startID = tutorialsComplete ? 7 : 1
        return PuzzleLevels.all.first { $0.id == startID }
    }
}

final class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]
    private let volumeKey = "soundEffectsVolume"

    private init() { }

    private var soundEffectsVolume: Float {
        let savedVolume = UserDefaults.standard.object(forKey: volumeKey) as? Double
        return Float(savedVolume ?? 0.85)
    }

    func play(_ name: String, delay: TimeInterval = 0) {
        let playBlock = {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("Missing sound: \(name).wav")
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = self.soundEffectsVolume
                player.prepareToPlay()
                player.play()
                self.players[name] = player
            } catch {
                print("Sound error for \(name): \(error)")
            }
        }

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playBlock()
            }
        } else {
            playBlock()
        }
    }
}


final class AchievementManager {
    static let shared = AchievementManager()

    private let defaults = UserDefaults.standard

    private init() { }

    private func unlockIfNeeded(title: String, key: String, condition: Bool) -> String? {
        guard condition else { return nil }
        guard defaults.bool(forKey: key) == false else { return nil }

        defaults.set(true, forKey: key)
        return title
    }

    func recordDrop(count: Int, mode: GameMode) -> [String] {
        var unlocked: [String] = []

        switch mode {
        case .classic:
            let currentBest = defaults.integer(forKey: "largestDropClassic")
            let newBest = max(currentBest, count)
            defaults.set(newBest, forKey: "largestDropClassic")

            if let title = unlockIfNeeded(
                title: "Classic Dropper I",
                key: "achievementClassicDrop5",
                condition: newBest >= 5
            ) {
                unlocked.append(title)
            }

            if let title = unlockIfNeeded(
                title: "Classic Dropper II",
                key: "achievementClassicDrop10",
                condition: newBest >= 10
            ) {
                unlocked.append(title)
            }

        case .counter:
            let currentBest = defaults.integer(forKey: "largestDropCounter")
            let newBest = max(currentBest, count)
            defaults.set(newBest, forKey: "largestDropCounter")

            if let title = unlockIfNeeded(
                title: "Counter Dropper I",
                key: "achievementCounterDrop5",
                condition: newBest >= 5
            ) {
                unlocked.append(title)
            }

            if let title = unlockIfNeeded(
                title: "Counter Dropper II",
                key: "achievementCounterDrop10",
                condition: newBest >= 10
            ) {
                unlocked.append(title)
            }
        }

        return unlocked
    }

    func recordNormalMatch(count: Int) -> [String] {
        let current = defaults.integer(forKey: "normalOrbsMatched")
        let newTotal = current + count
        defaults.set(newTotal, forKey: "normalOrbsMatched")

        return [
            unlockIfNeeded(
                title: "Normal Master",
                key: "achievementNormalMaster",
                condition: newTotal >= 300
            )
        ].compactMap { $0 }
    }

    func recordScore(totalPoints: Int) -> [String] {
        [
            unlockIfNeeded(
                title: "Rising Score",
                key: "achievementScore25000",
                condition: totalPoints >= 25000
            ),
            unlockIfNeeded(
                title: "Energy Collector",
                key: "achievementScore50000",
                condition: totalPoints >= 50000
            ),
            unlockIfNeeded(
                title: "Titan Legend",
                key: "achievementScore100000",
                condition: totalPoints >= 100000
            )
        ].compactMap { $0 }
    }

    func recordLevelComplete(difficulty: Difficulty, isAimerEnabled: Bool) -> [String] {
        var unlocked: [String] = []

        let currentCompletedLevels = defaults.integer(forKey: "totalLevelsCompleted")
        let newCompletedLevels = currentCompletedLevels + 1
        defaults.set(newCompletedLevels, forKey: "totalLevelsCompleted")

        if let title = unlockIfNeeded(
            title: "End Scene",
            key: "achievementEndScene",
            condition: newCompletedLevels >= 2
        ) {
            unlocked.append(title)
        }

        if difficulty == .hard {
            let current = defaults.integer(forKey: "hardLevelsCompleted")
            let newTotal = current + 1
            defaults.set(newTotal, forKey: "hardLevelsCompleted")

            if let title = unlockIfNeeded(
                title: "Hard Survivor",
                key: "achievementHard10",
                condition: newTotal >= 10
            ) {
                unlocked.append(title)
            }

            if let title = unlockIfNeeded(
                title: "Hard Champion",
                key: "achievementHard100",
                condition: newTotal >= 100
            ) {
                unlocked.append(title)
            }
        }

        if !isAimerEnabled {
            let current = defaults.integer(forKey: "noAimerWins")
            let newTotal = current + 1
            defaults.set(newTotal, forKey: "noAimerWins")

            if let title = unlockIfNeeded(
                title: "No Aimer Win",
                key: "achievementNoAimerWin",
                condition: newTotal >= 1
            ) {
                unlocked.append(title)
            }

            if difficulty == .hard {
                let hardCurrent = defaults.integer(forKey: "hardNoAimerWins")
                let hardNewTotal = hardCurrent + 1
                defaults.set(hardNewTotal, forKey: "hardNoAimerWins")

                if let title = unlockIfNeeded(
                    title: "Hard No Aimer",
                    key: "achievementHardNoAimer",
                    condition: hardNewTotal >= 1
                ) {
                    unlocked.append(title)
                }
            }
        }

        return unlocked
    }

    // MARK: - Puzzle Mode

    /// Best stars per puzzle level, saved by level name (so reordering levels keeps progress).
    static let puzzleBestStarsKey = "puzzleBestStars"

    static func puzzleBestStars() -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: puzzleBestStarsKey) as? [String: Int] ?? [:]
    }

    /// How many puzzle levels have at least `minStars` as their best.
    static func puzzleLevelsWith(atLeast minStars: Int) -> Int {
        let best = puzzleBestStars()
        return PuzzleLevels.all.filter { (best[$0.chamberName] ?? 0) >= minStars }.count
    }

    func recordPuzzleLevelComplete(
        level: PuzzleLevel,
        stars: Int,
        aimerEnabled: Bool,
        runScore: Int
    ) -> [String] {
        var unlocked: [String] = []

        // Save the best stars for this level.
        var best = AchievementManager.puzzleBestStars()
        best[level.chamberName] = max(best[level.chamberName] ?? 0, stars)
        defaults.set(best, forKey: AchievementManager.puzzleBestStarsKey)

        let total = PuzzleLevels.all.count
        let isLastLevel = PuzzleLevels.all.last?.id == level.id

        let checks: [(String, String, Bool)] = [
            ("Tutorial Graduate", "achievementPuzzleTutorials", level.id == 6),
            ("Puzzle Solver", "achievementPuzzleSolver", isLastLevel),
            ("Steady Hand", "achievementPuzzleNoAimer", isLastLevel && !aimerEnabled),
            ("Star Collector I", "achievementPuzzleStars1", AchievementManager.puzzleLevelsWith(atLeast: 1) >= total),
            ("Star Collector II", "achievementPuzzleStars2", AchievementManager.puzzleLevelsWith(atLeast: 2) >= total),
            ("Perfectionist", "achievementPuzzleStars3", AchievementManager.puzzleLevelsWith(atLeast: 3) >= total),
            ("Puzzle Pro", "achievementPuzzleScore10000", runScore >= 10000)
        ]

        for (title, key, condition) in checks {
            if let title = unlockIfNeeded(title: title, key: key, condition: condition) {
                unlocked.append(title)
            }
        }

        return unlocked
    }

    func recordPurchase(_ powerUp: ActivePowerUp) -> [String] {
        switch powerUp {
        case .bomb:
            defaults.set(true, forKey: "bombPurchased")
            return [
                unlockIfNeeded(
                    title: "Bomb Buyer",
                    key: "achievementBombBuyer",
                    condition: true
                )
            ].compactMap { $0 }

        case .typeFreeze:
            defaults.set(true, forKey: "freezePurchased")
            return [
                unlockIfNeeded(
                    title: "Freeze Buyer",
                    key: "achievementFreezeBuyer",
                    condition: true
                )
            ].compactMap { $0 }

        case .typeErase:
            defaults.set(true, forKey: "erasePurchased")
            return [
                unlockIfNeeded(
                    title: "Erase Buyer",
                    key: "achievementEraseBuyer",
                    condition: true
                )
            ].compactMap { $0 }
        }
    }
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case counter = "Counter Mode"

    var id: String { rawValue }
}

// MARK: - Orb Types

enum OrbType: String, CaseIterable, Identifiable {
    case ember
    case tide
    case sprout
    case electric
    case boulder
    case normal
    
    

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ember: return "Fire"
        case .tide: return "Water"
        case .sprout: return "Plant"
        case .electric: return "Electric"
        case .boulder: return "Rock"
        case .normal: return "Normal"
        }
    }
    
    var assetName: String {
        switch self {
        case .ember: return "orb_fire"
        case .tide: return "orb_water"
        case .sprout: return "orb_plant"
        case .electric: return "orb_electric"
        case .boulder: return "orb_rock"
        case .normal: return "orb_normal"
        }
    }

    var symbol: String {
        switch self {
        case .ember: return "🔥"
        case .tide: return "💧"
        case .sprout: return "🌱"
        case .electric: return "⚡️"
        case .boulder: return "🪨"
        case .normal: return "⚪️"
        }
    }

    var color: Color {
        switch self {
        case .ember: return .red
        case .tide: return .blue
        case .sprout: return .green
        case .electric: return .yellow
        case .boulder: return .brown
        case .normal: return .gray
        }
    }

    func beats(_ other: OrbType, in gameMode: GameMode) -> Bool {
        switch gameMode {
        case .classic:
            // Classic keeps the type rule very simple.
            return self == .tide && other == .ember

        case .counter:
            // Counter Mode uses the full type chart, but Normal is not used in this mode.
            switch (self, other) {
            case (.ember, .sprout): return true       // fire > plant
            case (.sprout, .tide): return true        // plant > water
            case (.tide, .ember): return true         // water > fire
            case (.electric, .tide): return true      // electric > water
            case (.boulder, .electric): return true   // boulder > electric
            case (.tide, .boulder): return true       // water > boulder
            default: return false
            }
        }
    }
}

struct MovingOrb {
    var type: OrbType
    var position: CGPoint
    var velocity: CGVector
    var powerUp: ActivePowerUp?
}

struct StuckOrb: Identifiable, Equatable {
    let id = UUID()
    let type: OrbType
    let position: CGPoint
}

struct FallingOrb: Identifiable {
    let id = UUID()
    let type: OrbType
    let startPosition: CGPoint
}

struct ClearEffect: Identifiable {
    enum Style {
        case typePower
        case breakApart
    }

    let id = UUID()
    let type: OrbType
    let position: CGPoint
    let style: Style
}

enum ActivePowerUp: String, Identifiable {
    case bomb
    case typeFreeze
    case typeErase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bomb: return "Bomb Orb"
        case .typeFreeze: return "Type Freeze"
        case .typeErase: return "Type Erase"
        }
    }
    var assetName: String {
            switch self {
            case .bomb: return "orb_bomb"
            case .typeFreeze: return "orb_freeze"
            case .typeErase: return "orb_erase"
            }
        }
}


enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var isSelectableNow: Bool {
        self == .easy || self == .medium
    }

    var displayName: String { rawValue }

    var missesBeforeDrop: Int {
        switch self {
        case .easy: return 10
        case .medium: return 10
        case .hard: return 7
        }
    }

    var rowCount: Int {
        switch self {
        case .easy: return 5
        case .medium: return 5
        case .hard: return 6
        }
    }

    var columnCount: Int {
        switch self {
        case .easy: return 8
        case .medium: return 10
        case .hard: return 12
        }
    }

    func generateStartingRows(gameMode: GameMode) -> [[OrbType?]] {
        switch self {
        case .easy:
            return generateEasyRows(gameMode: gameMode)
        case .medium:
            return generateMediumRows(gameMode: gameMode)
        case .hard:
            return generateHardRows(gameMode: gameMode)
        }
    }

    private func availableTypes(for gameMode: GameMode) -> [OrbType] {
        switch gameMode {
        case .classic:
            return OrbType.allCases
        case .counter:
            return OrbType.allCases.filter { $0 != .normal }
        }
    }

    private func generateEasyRows(gameMode: GameMode) -> [[OrbType?]] {
        let types = availableTypes(for: gameMode)
        var grid = Array(
            repeating: Array<OrbType?>(repeating: nil, count: columnCount),
            count: rowCount
        )

        let primary = types.randomElement()!
        let secondary = differentRandomType(from: primary, in: types)
        let tertiary = differentRandomType(from: primary, secondary, in: types)

        let mainGroupSize = Bool.random() && Bool.random() ? 3 : 4
        placeHorizontalGroup(size: mainGroupSize, type: primary, in: &grid)
        placeHorizontalGroup(size: 2, type: secondary, in: &grid)
        placeHorizontalGroup(size: 2, type: tertiary, in: &grid)

        for row in 0..<rowCount {
            for col in 0..<columnCount {
                if grid[row][col] == nil {
                    grid[row][col] = randomTypeThatAvoidsNeighbors(row: row, col: col, grid: grid, types: types)
                }
            }
        }

        return grid
    }

    private func generateMediumRows(gameMode: GameMode) -> [[OrbType?]] {
        let types = availableTypes(for: gameMode)
        var grid = Array(
            repeating: Array<OrbType?>(repeating: nil, count: columnCount),
            count: rowCount
        )

        // Medium: wider board, mostly pairs, no intentional 3/4 groups.
        let pairCount = 9
        for _ in 0..<pairCount {
            placePair(in: &grid, types: types)
        }

        for row in 0..<rowCount {
            for col in 0..<columnCount {
                if grid[row][col] == nil {
                    grid[row][col] = randomTypeAvoidingLargeGroups(row: row, col: col, grid: grid, types: types)
                }
            }
        }

        return grid
    }

    private func placeHorizontalGroup(size: Int, type: OrbType, in grid: inout [[OrbType?]]) {
        guard let colsCount = grid.first?.count else { return }
        let rowsCount = grid.count

        for row in Array(0..<rowsCount).shuffled() {
            for startCol in Array(0...(colsCount - size)).shuffled() {
                let positions = (startCol..<(startCol + size)).map { (row, $0) }
                if positions.allSatisfy({ grid[$0.0][$0.1] == nil }) {
                    for position in positions {
                        grid[position.0][position.1] = type
                    }
                    return
                }
            }
        }
    }

    private func placePair(in grid: inout [[OrbType?]], types: [OrbType]) {
        guard let colsCount = grid.first?.count else { return }
        let rowsCount = grid.count
        let type = types.randomElement()!
        let directions = [(0, 1), (1, 0)]

        for _ in 0..<80 {
            let row = Int.random(in: 0..<rowsCount)
            let col = Int.random(in: 0..<colsCount)
            let direction = directions.randomElement()!
            let secondRow = row + direction.0
            let secondCol = col + direction.1

            guard secondRow >= 0,
                  secondRow < rowsCount,
                  secondCol >= 0,
                  secondCol < colsCount else { continue }

            guard grid[row][col] == nil,
                  grid[secondRow][secondCol] == nil else { continue }

            grid[row][col] = type
            grid[secondRow][secondCol] = type
            return
        }
    }

    private func randomTypeThatAvoidsNeighbors(row: Int, col: Int, grid: [[OrbType?]], types: [OrbType]) -> OrbType {
        let neighborTypes = adjacentTypes(row: row, col: col, grid: grid)
        let preferredTypes = types.filter { !neighborTypes.contains($0) }
        return (preferredTypes.randomElement() ?? types.randomElement())!
    }

    private func randomTypeAvoidingLargeGroups(row: Int, col: Int, grid: [[OrbType?]], types: [OrbType]) -> OrbType {
        let safeTypes = types.filter { type in
            var testGrid = grid
            testGrid[row][col] = type
            return largestConnectedGroup(in: testGrid) <= 2
        }

        return (safeTypes.randomElement() ?? types.randomElement())!
    }

    private func adjacentTypes(row: Int, col: Int, grid: [[OrbType?]]) -> Set<OrbType> {
        let positions = [
            (row - 1, col),
            (row + 1, col),
            (row, col - 1),
            (row, col + 1)
        ]

        var result = Set<OrbType>()
        for position in positions {
            guard position.0 >= 0,
                  position.0 < grid.count,
                  position.1 >= 0,
                  position.1 < grid[position.0].count,
                  let type = grid[position.0][position.1] else { continue }
            result.insert(type)
        }
        return result
    }

    private func largestConnectedGroup(in rows: [[OrbType?]]) -> Int {
        var visited = Set<String>()
        var largest = 0

        for row in 0..<rows.count {
            for col in 0..<rows[row].count {
                guard let type = rows[row][col] else { continue }
                let key = "\(row)-\(col)"
                if visited.contains(key) { continue }

                var stack = [(row, col)]
                var count = 0

                while let current = stack.popLast() {
                    let currentKey = "\(current.0)-\(current.1)"
                    if visited.contains(currentKey) { continue }
                    visited.insert(currentKey)

                    guard rows[current.0][current.1] == type else { continue }
                    count += 1

                    let neighbors = [
                        (current.0 - 1, current.1),
                        (current.0 + 1, current.1),
                        (current.0, current.1 - 1),
                        (current.0, current.1 + 1)
                    ]

                    for neighbor in neighbors {
                        guard neighbor.0 >= 0,
                              neighbor.0 < rows.count,
                              neighbor.1 >= 0,
                              neighbor.1 < rows[neighbor.0].count,
                              rows[neighbor.0][neighbor.1] == type else { continue }
                        stack.append(neighbor)
                    }
                }

                largest = max(largest, count)
            }
        }

        return largest
    }

    private func generateHardRows(gameMode: GameMode) -> [[OrbType?]] {
        let types = availableTypes(for: gameMode)
        var grid = Array(
            repeating: Array<OrbType?>(repeating: nil, count: columnCount),
            count: rowCount
        )

        if gameMode == .counter {
            // Counter Hard is different because single type-advantage clears are powerful.
            // Keep visual touching groups capped at 2 so the board does not start with large chains.
            let pairCount = 3
            for _ in 0..<pairCount {
                placeCounterSafePair(in: &grid, types: types)
            }

            for row in 0..<rowCount {
                for col in 0..<columnCount {
                    if grid[row][col] == nil {
                        grid[row][col] = randomTypeAvoidingCounterTouchGroups(
                            row: row,
                            col: col,
                            grid: grid,
                            types: types
                        )
                    }
                }
            }
        } else {
            // Classic Hard: mostly singles, very few pairs.
            let pairCount = 3
            for _ in 0..<pairCount {
                placePair(in: &grid, types: types)
            }

            for row in 0..<rowCount {
                for col in 0..<columnCount {
                    if grid[row][col] == nil {
                        grid[row][col] = randomTypeAvoidingLargeGroups(row: row, col: col, grid: grid, types: types)
                    }
                }
            }
        }

        return grid
    }

    private func placeCounterSafePair(in grid: inout [[OrbType?]], types: [OrbType]) {
        guard let colsCount = grid.first?.count else { return }
        let rowsCount = grid.count
        let directions = [(0, 1), (1, 0)]

        for _ in 0..<120 {
            let type = types.randomElement()!
            let row = Int.random(in: 0..<rowsCount)
            let col = Int.random(in: 0..<colsCount)
            let direction = directions.randomElement()!
            let secondRow = row + direction.0
            let secondCol = col + direction.1

            guard secondRow >= 0,
                  secondRow < rowsCount,
                  secondCol >= 0,
                  secondCol < colsCount else { continue }

            guard grid[row][col] == nil,
                  grid[secondRow][secondCol] == nil else { continue }

            var testGrid = grid
            testGrid[row][col] = type
            testGrid[secondRow][secondCol] = type

            if largestVisualTouchingGroup(in: testGrid) <= 2 {
                grid = testGrid
                return
            }
        }
    }

    private func randomTypeAvoidingCounterTouchGroups(row: Int, col: Int, grid: [[OrbType?]], types: [OrbType]) -> OrbType {
        let shuffledTypes = types.shuffled()

        for type in shuffledTypes {
            var testGrid = grid
            testGrid[row][col] = type

            if largestVisualTouchingGroup(in: testGrid) <= 2 {
                return type
            }
        }

        return shuffledTypes.first ?? types.randomElement()!
    }

    private func largestVisualTouchingGroup(in rows: [[OrbType?]]) -> Int {
        let rowSpacing: CGFloat = 0.82
        let colSpacing: CGFloat = 0.92
        let touchDistance: CGFloat = 1.15

        func position(row: Int, col: Int) -> CGPoint {
            let rowOffset: CGFloat = row.isMultiple(of: 2) ? 0 : colSpacing / 2
            return CGPoint(
                x: rowOffset + CGFloat(col) * colSpacing,
                y: CGFloat(row) * rowSpacing
            )
        }

        var visited = Set<String>()
        var largest = 0

        for row in 0..<rows.count {
            for col in 0..<rows[row].count {
                guard let type = rows[row][col] else { continue }

                let startKey = "\(row)-\(col)"
                if visited.contains(startKey) { continue }

                var stack = [(row, col)]
                var count = 0

                while let current = stack.popLast() {
                    let currentKey = "\(current.0)-\(current.1)"
                    if visited.contains(currentKey) { continue }
                    visited.insert(currentKey)

                    guard rows[current.0][current.1] == type else { continue }
                    count += 1

                    let currentPosition = position(row: current.0, col: current.1)

                    for neighborRow in max(0, current.0 - 1)...min(rows.count - 1, current.0 + 1) {
                        for neighborCol in max(0, current.1 - 1)...min(rows[neighborRow].count - 1, current.1 + 1) {
                            if neighborRow == current.0 && neighborCol == current.1 { continue }
                            guard rows[neighborRow][neighborCol] == type else { continue }

                            let neighborKey = "\(neighborRow)-\(neighborCol)"
                            if visited.contains(neighborKey) { continue }

                            let neighborPosition = position(row: neighborRow, col: neighborCol)
                            let dx = currentPosition.x - neighborPosition.x
                            let dy = currentPosition.y - neighborPosition.y
                            let distance = sqrt(dx * dx + dy * dy)

                            if distance <= touchDistance {
                                stack.append((neighborRow, neighborCol))
                            }
                        }
                    }
                }

                largest = max(largest, count)
            }
        }

        return largest
    }

    private func differentRandomType(from first: OrbType, _ second: OrbType? = nil, in types: [OrbType]) -> OrbType {
        let filtered = types.filter { type in
            type != first && type != second
        }
        return filtered.randomElement() ?? types.randomElement()!
    }
}

// MARK: - Shooter Prototype

struct ShooterPrototypeView: View {
    let initialGameMode: GameMode
    let initialDifficulty: Difficulty
    let isAimerEnabled: Bool
    let onBackToMenu: () -> Void
    let puzzleLevel: PuzzleLevel?
    let onNextPuzzle: ((PuzzleLevel) -> Void)?
    @State private var difficulty: Difficulty = .easy
    // Scale all dimensions based on available screen size
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }

    // Base design was 390pt wide, 844pt tall iPhone
    private var scaleH: CGFloat { screenHeight / 844.0 }
    private var scaleW: CGFloat { min(screenWidth / 390.0, 1.6) }
    private var scale: CGFloat { min(scaleH, scaleW) }

    private var orbSize: CGFloat { 34 * scale }
    private var playHeight: CGFloat { screenHeight - 200 * scaleH }
    private var launcherY: CGFloat { 560 * scaleH }
    private var shotSpeed: CGFloat { 8 * scale }
    private var shotCollisionDistance: CGFloat { 29 * scale }
    private var boardDropAmount: CGFloat { 28 * scale }
    private var startingCeilingY: CGFloat { 30 * scale }
    private var dangerLineY: CGFloat { 505 * scaleH }

    private var playWidth: CGFloat {
        let colSpacing = orbSize * 0.92
        return orbSize + CGFloat(difficulty.columnCount - 1) * colSpacing
    }

    // Narrow puzzle boards: the playable channel sits centered inside the board,
    // with walls on either side. Standard boards use the full width (no walls).
    private var channelColumnCount: Int? { puzzleLevel?.columns }

    private var channelWidth: CGFloat {
        guard let columns = channelColumnCount else { return playWidth }
        let colSpacing = orbSize * 0.92
        return min(playWidth, orbSize + CGFloat(columns - 1) * colSpacing)
    }

    private var leftWallX: CGFloat { (playWidth - channelWidth) / 2 }
    private var rightWallX: CGFloat { leftWallX + channelWidth }

    @State private var gameMode: GameMode = .classic
    @State private var aimAngle: Double = -90
    @State private var lastStableAimAngle: Double = -90
    @State private var currentType: OrbType = .tide
    @State private var nextType: OrbType = .ember
    @AppStorage("totalPoints") private var totalPoints: Int = 0
    @AppStorage("bombOrbCount") private var bombOrbCount: Int = 0
    @AppStorage("typeFreezeCount") private var typeFreezeCount: Int = 0
    @AppStorage("typeEraseCount") private var typeEraseCount: Int = 0
    @State private var activePowerUp: ActivePowerUp?
    @State private var frozenType: OrbType?
    @State private var frozenShotsRemaining: Int = 0
    @State private var showFreezeTypePicker: Bool = false
    @State private var showPowerUpPicker: Bool = false
    @State private var levelPoints: Int = 0
    @State private var shotsFiredThisLevel: Int = 0
    @State private var lastCompletedLevelPoints: Int = 0
    @State private var movingOrb: MovingOrb?
    @State private var stuckOrbs: [StuckOrb] = []
    @State private var fallingOrbs: [FallingOrb] = []
    @State private var clearEffects: [ClearEffect] = []
    @State private var ceilingY: CGFloat = 30
    @State private var missCount: Int = 0
    @State private var isLevelClear: Bool = false
    @State private var isGameOver: Bool = false
    @State private var puzzleShotsUsed: Int = 0
    @State private var isPuzzleMode: Bool = false
    @State private var isPuzzleFailed: Bool = false
    @State private var puzzleAimerEnabled: Bool = true
    @State private var puzzleUsedAimer: Bool = false      // aimer on for any shot this level
    @State private var puzzleLevelStars: Int = 0
    @State private var puzzleLevelStarPoints: Int = 0
    @State private var puzzleLevelAimerBonus: Int = 0
    @State private var showCounterTutorial: Bool = false
    @State private var usedAimer: Bool = false
    @State private var sessionPoints: Int = 0
    @State private var showRules: Bool = false
    @State private var levelNumber: Int = 1
    @State private var unlockedAchievementTitle: String?

    private let gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            GameTopHUDView(
                modeTitle: gameMode.rawValue,
                levelNumber: levelNumber,
                difficulty: difficulty,
                score: levelPoints,
                nextType: nextType,
                activePowerUp: activePowerUp,
                frozenType: frozenType,
                frozenShotsRemaining: frozenShotsRemaining,
                currentMisses: missCount,
                maxMisses: difficulty.missesBeforeDrop,
                usedAimer: usedAimer,
                onBack: {
                    if isPuzzleMode { PuzzleRun.shared.submitToLeaderboard() }
                    if sessionPoints > 0 && !usedAimer {
                        GameCenterManager.shared.onScoreSubmitted = { score in
                            self.showUnlockToast("🏆 Score \(score) pts submitted!")
                        }
                        GameCenterManager.shared.submitScore(sessionPoints)
                    }
                    onBackToMenu()
                },
                onRules: {
                    showRules = true
                },
                onPowerUp: {
                    showPowerUpPicker = true
                },
                onCounterHelp: gameMode == .counter ? {
                    showCounterTutorial = true
                } : nil,
                chamberName: isPuzzleMode ? puzzleLevel?.chamberName : nil,
                puzzleLevelNumber: isPuzzleMode ? puzzleLevel?.id : nil
            )
            .padding(.horizontal, 18)

            ZStack {
                ZStack {
                    Image("titan_board_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: playWidth, height: playHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 28))

                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.10),
                                    .clear,
                                    .black.opacity(0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.38),
                                    .cyan.opacity(0.20),
                                    .orange.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .frame(width: playWidth, height: playHeight)
                .shadow(color: .black.opacity(0.32), radius: 20, x: 0, y: 12)

                if channelColumnCount != nil {
                    PuzzleWallsView(
                        leftWallX: leftWallX,
                        rightWallX: rightWallX,
                        playWidth: playWidth,
                        playHeight: playHeight
                    )
                }

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.45), .cyan.opacity(0.30)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(channelWidth - 28, 20), height: 5)
                    .shadow(color: .cyan.opacity(0.25), radius: 5, x: 0, y: 0)
                    .position(x: playWidth / 2, y: ceilingY)
                

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.55), .pink.opacity(0.75), .red.opacity(0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: playWidth - 42, height: 3)
                    .shadow(color: .red.opacity(0.65), radius: 7, x: 0, y: 0)
                    .position(x: playWidth / 2, y: dangerLineY)

                if isPuzzleMode ? puzzleAimerEnabled : isAimerEnabled {
                    Path { path in
                        let points = predictedTrajectoryPoints()
                        guard let firstPoint = points.first else { return }

                        path.move(to: firstPoint)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.88), .blue.opacity(0.55)],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [10, 10])
                )
                .shadow(color: .cyan.opacity(0.35), radius: 5, x: 0, y: 0)
                }

                ForEach(stuckOrbs) { orb in
                    OrbView(type: orb.type, size: orbSize)
                        .position(orb.position)
                }

                ForEach(fallingOrbs) { orb in
                    FallingOrbView(
                        type: orb.type,
                        size: orbSize,
                        startPosition: orb.startPosition,
                        dangerLineY: dangerLineY
                    )
                }

                ForEach(clearEffects) { effect in
                    ClearEffectView(
                        type: effect.type,
                        position: effect.position,
                        style: effect.style
                    )
                }

                NextOrbBoardPreviewView(
                    nextType: nextType,
                    orbSize: orbSize,
                    shotsRemaining: isPuzzleMode ? (puzzleLevel.map { $0.shotQueue.count - puzzleShotsUsed } ?? nil) : nil
                )
                .position(x: launcherPosition.x - 58, y: launcherY + 2)

                CharacterBacksView(
                    launcherPosition: launcherPosition,
                    launcherY: launcherY
                )

                Image("cannon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 110)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 6)
                    .rotationEffect(.degrees(aimAngle + 90))
                    .position(launcherPosition)
                
                // Puzzle aimer is chosen once at the start of the run and locked (no in-game toggle).

                // Puzzle mode: live shots / par / stars bar in the empty strip at the bottom of the board.
                if isPuzzleMode, let puzzle = puzzleLevel {
                    PuzzleParBarView(
                        shotsUsed: puzzleShotsUsed,
                        parShots: puzzle.parShots,
                        threeStarShots: puzzle.threeStarShots ?? puzzle.parShots,
                        twoStarShots: puzzle.twoStarShots,
                        isFinished: isLevelClear
                    )
                    .position(x: playWidth / 2, y: playHeight - 20 * scale)
                }

                if movingOrb == nil && !isGameOver && !isLevelClear {
                    CurrentShotView(type: currentType, activePowerUp: activePowerUp, size: orbSize)
                    .position(launcherPosition)
                }

                if let movingOrb {
                    CurrentShotView(type: movingOrb.type, activePowerUp: movingOrb.powerUp, size: orbSize)
                        .position(movingOrb.position)
                }
            }
            .frame(width: playWidth, height: playHeight)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        handleAimDrag(value)
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        shoot()
                    }
            )
            .onReceive(gameTimer) { _ in
                            updateMovingOrb()
                        }

            // Puzzle chamber name now lives in the top HUD (danger bar), so the
            // puzzle screen uses the exact same layout as regular mode.

                        Spacer()
        }
        .padding(.top)
        .overlay {
            if isPuzzleFailed, let puzzle = puzzleLevel {
                PuzzleFailedOverlayView(
                    chamberName: puzzle.chamberName,
                    runScore: PuzzleRun.shared.score,
                    onStartOver: {
                        // Losing a level ends the run: submit it, then reset and restart from the beginning.
                        PuzzleRun.shared.submitToLeaderboard()
                        PuzzleRun.shared.score = 0
                        let start = PuzzleRun.startingLevel()
                        if let start, start.id != puzzle.id {
                            onNextPuzzle?(start)
                        } else {
                            isPuzzleFailed = false
                            resetGame()
                        }
                    },
                    onBackToMenu: {
                        PuzzleRun.shared.submitToLeaderboard()
                        onBackToMenu()
                    }
                )
            } else if isLevelClear {
                if isPuzzleMode, let puzzle = puzzleLevel {
                    PuzzleCompleteOverlayView(
                        chamberName: puzzle.chamberName,
                        shotsUsed: puzzleShotsUsed,
                        parShots: puzzle.parShots,
                        threeStarShots: puzzle.threeStarShots ?? puzzle.parShots,
                        twoStarShots: puzzle.twoStarShots,
                        oneStarShots: puzzle.oneStarShots,
                        stars: puzzleLevelStars,
                        starPoints: puzzleLevelStarPoints,
                        aimerBonus: puzzleLevelAimerBonus,
                        usedAimer: puzzleUsedAimer,
                        runScore: PuzzleRun.shared.score,
                        hasNextLevel: PuzzleLevels.all.first { $0.id == puzzle.id + 1 } != nil,
                        onNextLevel: {
                            if puzzle.id == 6 {
                                UserDefaults.standard.set(true, forKey: "tutorialsComplete")
                            }
                            if let nextPuzzle = PuzzleLevels.all.first(where: { $0.id == puzzle.id + 1 }) {
                                onNextPuzzle?(nextPuzzle)
                            }
                        },
                        onBackToMenu: {
                            PuzzleRun.shared.submitToLeaderboard()
                            onBackToMenu()
                        }
                    )
                } else {
                    LevelCompleteOverlayView(
                        levelPoints: lastCompletedLevelPoints,
                        bonusPoints: 100,
                        roundTotal: sessionPoints,
                        shotsFired: shotsFiredThisLevel,
                        onNextLevel: nextLevel,
                        onBackToMenu: {
                            if sessionPoints > 0 && !usedAimer {
                                GameCenterManager.shared.onScoreSubmitted = { score in
                                    self.showUnlockToast("🏆 Score \(score) pts submitted!")
                                }
                                GameCenterManager.shared.submitScore(sessionPoints)
                            }
                            onBackToMenu()
                        }
                    )
                }
            }
        }
        .overlay(alignment: .top) {
            if let unlockedAchievementTitle {
                AchievementToastView(title: unlockedAchievementTitle)
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .onAppear {
                    gameMode = initialGameMode
                    difficulty = initialDifficulty
                    sessionPoints = 0
                    resetGame()
            if gameMode == .counter && difficulty == .easy && !UserDefaults.standard.bool(forKey: "counterTutorialShown") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCounterTutorial = true
                    UserDefaults.standard.set(true, forKey: "counterTutorialShown")
                }
            }
        }
        .sheet(isPresented: $showRules) {
            RulesSheetView(gameMode: gameMode)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPowerUpPicker) {
            PowerUpPickerSheetView(
                bombCount: bombOrbCount,
                freezeCount: typeFreezeCount,
                eraseCount: typeEraseCount,
                activePowerUp: activePowerUp,
                frozenType: frozenType,
                frozenShotsRemaining: frozenShotsRemaining,
                onSelectBomb: {
                    showPowerUpPicker = false
                    activatePowerUp(.bomb)
                },
                onSelectFreeze: {
                    showPowerUpPicker = false
                    if typeFreezeCount > 0 {
                        showFreezeTypePicker = true
                    }
                },
                onSelectErase: {
                    showPowerUpPicker = false
                    activatePowerUp(.typeErase)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showFreezeTypePicker) {
            FreezeTypePickerSheetView(
                orbTypes: freezableTypes,
                onSelectType: { type in
                    showFreezeTypePicker = false
                    activateTypeFreeze(type)
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showCounterTutorial) {
            CounterTutorialView()
                .presentationDetents([.large])
        }
    }

    private func resetGame() {
        isPuzzleMode = puzzleLevel != nil
            puzzleShotsUsed = 0
        puzzleUsedAimer = false
        isPuzzleFailed = false
        puzzleAimerEnabled = PuzzleRun.shared.aimerEnabled   // locked for the whole run
        movingOrb = nil
        stuckOrbs = []
        fallingOrbs = []
        clearEffects = []
        ceilingY = startingCeilingY
        missCount = 0
        isGameOver = false
        isLevelClear = false
        aimAngle = -90
        lastStableAimAngle = -90
        levelPoints = 0
        shotsFiredThisLevel = 0
        lastCompletedLevelPoints = 0
        activePowerUp = nil
        frozenType = nil
        frozenShotsRemaining = 0
        currentType = randomOrbForCurrentMode()
        nextType = randomOrbForCurrentMode()
        if let puzzle = puzzleLevel {
                loadPuzzleLevel(puzzle)
            } else {
                loadFreePlayLevel(difficulty)
            }
        }

    private func nextLevel() {
        levelNumber += 1
        movingOrb = nil
        stuckOrbs = []
        fallingOrbs = []
        clearEffects = []
        ceilingY = startingCeilingY
        missCount = 0
        isGameOver = false
        isLevelClear = false
        aimAngle = -90
        lastStableAimAngle = -90
        levelPoints = 0
        currentType = randomOrbForCurrentMode()
        nextType = randomOrbForCurrentMode()
        if let puzzle = puzzleLevel {
                loadPuzzleLevel(puzzle)
            } else {
                loadFreePlayLevel(difficulty)
            }
        }

    private var availableSpawnTypes: [OrbType] {
        let baseTypes: [OrbType]

        switch gameMode {
        case .classic:
            baseTypes = OrbType.allCases
        case .counter:
            baseTypes = OrbType.allCases.filter { $0 != .normal }
        }

        if let frozenType, frozenShotsRemaining > 0 {
            let filtered = baseTypes.filter { $0 != frozenType }
            return filtered.isEmpty ? baseTypes : filtered
        }

        return baseTypes
    }

    private var freezableTypes: [OrbType] {
        switch gameMode {
        case .classic:
            return OrbType.allCases
        case .counter:
            return OrbType.allCases.filter { $0 != .normal }
        }
    }

    private func randomOrbForCurrentMode() -> OrbType {
        availableSpawnTypes.randomElement()!
    }

    private func orbForLevel(_ type: OrbType) -> OrbType {
        if gameMode == .counter && type == .normal {
            return randomOrbForCurrentMode()
        }
        return type
    }

    private func loadFreePlayLevel(_ difficulty: Difficulty) {
        let rowSpacing = orbSize * 0.82
        let colSpacing = orbSize * 0.92
        let generatedRows = difficulty.generateStartingRows(gameMode: gameMode)
        let maxColumnCount = generatedRows.map { $0.count }.max() ?? 8
        let fullRowWidth = orbSize + CGFloat(maxColumnCount - 1) * colSpacing
        let startY = ceilingY + orbSize / 2
        let fullRowStartX = (playWidth - fullRowWidth) / 2 + orbSize / 2

        for (rowIndex, row) in generatedRows.enumerated() {
            let rowOffset: CGFloat = rowIndex.isMultiple(of: 2) ? 0 : colSpacing / 2
            let maxItemsInRow = rowIndex.isMultiple(of: 2) ? maxColumnCount : maxColumnCount - 1

            for (colIndex, type) in row.prefix(maxItemsInRow).enumerated() {
                guard let type else { continue }

                let position = CGPoint(
                    x: fullRowStartX + rowOffset + CGFloat(colIndex) * colSpacing,
                    y: startY + CGFloat(rowIndex) * rowSpacing
                )

                stuckOrbs.append(StuckOrb(type: orbForLevel(type), position: position))
            }
        }
    }
    private func loadPuzzleLevel(_ puzzle: PuzzleLevel) {
        let rowSpacing = orbSize * 0.82
        let colSpacing = orbSize * 0.92
        let maxColumnCount = puzzle.columns ?? 8
        let fullRowWidth = orbSize + CGFloat(maxColumnCount - 1) * colSpacing
        let startY = ceilingY + orbSize / 2
        let fullRowStartX = (playWidth - fullRowWidth) / 2 + orbSize / 2

        for (rowIndex, row) in puzzle.grid.enumerated() {
            let rowOffset: CGFloat = rowIndex.isMultiple(of: 2) ? 0 : colSpacing / 2
            // Walled levels (columns set): even rows hold maxColumnCount orbs, odd rows one fewer,
            // and extra entries are ignored so an orb can never be placed inside a wall.
            // Levels without walls load every entry exactly as written.
            let maxItemsInRow: Int
            if puzzle.columns != nil {
                maxItemsInRow = rowIndex.isMultiple(of: 2) ? maxColumnCount : maxColumnCount - 1
            } else {
                maxItemsInRow = row.count
            }
            for (colIndex, type) in row.prefix(maxItemsInRow).enumerated() {
                guard let type = type else { continue }
                let position = CGPoint(
                    x: fullRowStartX + rowOffset + CGFloat(colIndex) * colSpacing,
                    y: startY + CGFloat(rowIndex) * rowSpacing
                )
                stuckOrbs.append(StuckOrb(type: type, position: position))
            }
        }

        // Load the shot queue
        if let firstShot = puzzle.shotQueue.first {
            currentType = firstShot
        }
        if puzzle.shotQueue.count > 1 {
            nextType = puzzle.shotQueue[1]
        } else if let firstShot = puzzle.shotQueue.first {
            nextType = firstShot
        }
    }

    private var launcherPosition: CGPoint {
        CGPoint(x: playWidth / 2, y: launcherY)
    }

    private func predictedTrajectoryPoints() -> [CGPoint] {
        let radius = orbSize / 2
        var position = launcherPosition
        let radians = aimAngle * .pi / 180
        var velocity = CGVector(
            dx: cos(radians) * shotSpeed,
            dy: sin(radians) * shotSpeed
        )

        var points: [CGPoint] = [position]

        for _ in 0..<220 {
            position.x += velocity.dx
            position.y += velocity.dy

            if position.x <= leftWallX + radius {
                position.x = leftWallX + radius
                velocity.dx *= -1
                points.append(position)
            }

            if position.x >= rightWallX - radius {
                position.x = rightWallX - radius
                velocity.dx *= -1
                points.append(position)
            }

            if stuckOrbs.contains(where: { distance(from: position, to: $0.position) <= shotCollisionDistance }) {
                points.append(position)
                break
            }

            if position.y <= ceilingY + radius {
                position.y = ceilingY + radius
                points.append(position)
                break
            }
        }

        if points.last != position {
            points.append(position)
        }

        return points
    }

    private func handleAimDrag(_ value: DragGesture.Value) {
        guard movingOrb == nil && !isGameOver && !isLevelClear else { return }

        aimToward(value.location)
        lastStableAimAngle = aimAngle
    }

    private func aimToward(_ location: CGPoint) {
        guard movingOrb == nil && !isGameOver && !isLevelClear else { return }

        let dx = location.x - launcherPosition.x
        let dy = location.y - launcherPosition.y
        var degrees = atan2(dy, dx) * 180 / .pi

        degrees = min(-20, max(-160, degrees))

        let smoothing = 0.18
        aimAngle += (degrees - aimAngle) * smoothing
    }

    private func shoot() {
        guard movingOrb == nil && !isGameOver && !isLevelClear else { return }

        SoundManager.shared.play("orb_launch")
        if isAimerEnabled && !isPuzzleMode { usedAimer = true }
        if isPuzzleMode && puzzleAimerEnabled { puzzleUsedAimer = true }
        if !isPuzzleMode { shotsFiredThisLevel += 1 }

        aimAngle = lastStableAimAngle

        let radians = aimAngle * .pi / 180
        let velocity = CGVector(
            dx: cos(radians) * shotSpeed,
            dy: sin(radians) * shotSpeed
        )

        movingOrb = MovingOrb(
            type: currentType,
            position: launcherPosition,
            velocity: velocity,
            powerUp: activePowerUp
        )
    }

    private func updateMovingOrb() {
        guard var orb = movingOrb else { return }

        orb.position.x += orb.velocity.dx
        orb.position.y += orb.velocity.dy

        let radius = orbSize / 2

        if orb.position.x <= leftWallX + radius {
            orb.position.x = leftWallX + radius
            orb.velocity.dx *= -1
        }

        if orb.position.x >= rightWallX - radius {
            orb.position.x = rightWallX - radius
            orb.velocity.dx *= -1
        }

        if let hitOrb = stuckOrbs.first(where: { distance(from: orb.position, to: $0.position) <= shotCollisionDistance }) {
            let snappedPosition = nearestOpenGridSlot(to: orb.position, near: hitOrb.position)
            placeOrb(type: orb.type, at: snappedPosition)
            return
        }

        if orb.position.y <= ceilingY + radius {
            orb.position.y = ceilingY + radius
            let snappedPosition = nearestOpenGridSlot(to: orb.position, near: orb.position)
            placeOrb(type: orb.type, at: snappedPosition)
            return
        }

        movingOrb = orb
    }

    private func placeOrb(type: OrbType, at position: CGPoint) {
        let placedPowerUp = movingOrb?.powerUp ?? activePowerUp
        let newOrb = StuckOrb(type: type, position: position)
        stuckOrbs.append(newOrb)
        movingOrb = nil

        var totalCleared = 0
        var droppedCount = 0

        if placedPowerUp == .bomb {
            totalCleared += applyBombPowerUp(at: newOrb)
            activePowerUp = nil
        } else if placedPowerUp == .typeErase {
            let targetType = nearestExistingOrbType(to: position, excluding: newOrb.id) ?? newOrb.type
            totalCleared += applyTypeErasePowerUp(targetType: targetType)
            activePowerUp = nil
        } else {
            let dominanceCount = clearWeakerNeighbors(around: newOrb)
            let matchCount = gameMode == .classic ? clearMatchingGroup(connectedTo: newOrb) : 0
            droppedCount = dropFloatingOrbs()
            totalCleared = dominanceCount + matchCount + droppedCount
        }

        if activePowerUp == nil {
            // no-op, keeps the one-shot power-up logic explicit
        }

        if frozenShotsRemaining > 0 {
            frozenShotsRemaining -= 1
            if frozenShotsRemaining == 0 {
                frozenType = nil
            }
        }

        if totalCleared > 0 {
            SoundManager.shared.play("orb_clear")

            if droppedCount >= 3 {
                SoundManager.shared.play("big_drop_cheer", delay: 0.65)
            }

            let pointsEarned = totalCleared * 10
            totalPoints += pointsEarned
            levelPoints += pointsEarned
            showAchievementUnlocks(
                AchievementManager.shared.recordScore(totalPoints: totalPoints)
            )
        }

        if droppedCount > 0 {
            showAchievementUnlocks(
                AchievementManager.shared.recordDrop(count: droppedCount, mode: gameMode)
            )
            missCount = 0
        } else if totalCleared > 0 && !(gameMode == .counter && difficulty == .hard) {
            // Classic and easier Counter clears prevent danger from increasing.
            // Counter Hard is stricter: only dropping disconnected orbs protects you.
        } else {
            missCount += 1
            if missCount >= difficulty.missesBeforeDrop {
                moveBoardDown()
                missCount = 0
            }
        }

        // Count every puzzle shot, including the one that clears the board,
        // so "shots used" matches the number of orbs actually fired.
        if isPuzzleMode {
            puzzleShotsUsed += 1
        }

        checkLevelClear()
        checkGameOver()

        if !isLevelClear && !isGameOver {
            if isPuzzleMode, let puzzle = puzzleLevel {
                if puzzleShotsUsed >= puzzle.shotQueue.count {
                    isPuzzleFailed = true
                } else {
                    // Always take the real queued shot — the last shot is never random.
                    currentType = puzzle.shotQueue[puzzleShotsUsed]
                    let nextIndex = puzzleShotsUsed + 1
                    nextType = nextIndex < puzzle.shotQueue.count ? puzzle.shotQueue[nextIndex] : currentType
                }
            } else {
                currentType = nextType
                nextType = randomOrbForCurrentMode()
            }
            }
    }

    private func activatePowerUp(_ powerUp: ActivePowerUp) {
        guard movingOrb == nil && !isGameOver && !isLevelClear else { return }
        guard !isPuzzleMode else { return }   // power-ups are not allowed in puzzles

        switch powerUp {
        case .bomb:
            guard bombOrbCount > 0 else { return }
            bombOrbCount -= 1
            activePowerUp = .bomb

        case .typeFreeze:
            guard typeFreezeCount > 0 else { return }
            showFreezeTypePicker = true

        case .typeErase:
            guard typeEraseCount > 0 else { return }
            typeEraseCount -= 1
            activePowerUp = .typeErase
        }
    }

    private func activateTypeFreeze(_ type: OrbType) {
        guard typeFreezeCount > 0 else { return }
        typeFreezeCount -= 1
        frozenType = type
        frozenShotsRemaining = 10

        if currentType == type {
            currentType = randomOrbForCurrentMode()
        }

        if nextType == type {
            nextType = randomOrbForCurrentMode()
        }
    }

    private func applyBombPowerUp(at newOrb: StuckOrb) -> Int {
        let blastRadius = orbSize * 3.0
        let orbsToRemove = stuckOrbs.filter { orb in
            distance(from: orb.position, to: newOrb.position) <= blastRadius
        }

        guard !orbsToRemove.isEmpty else { return 0 }

        animateClearEffects(orbsToRemove, style: .breakApart)
        let idsToRemove = Set(orbsToRemove.map { $0.id })
        stuckOrbs.removeAll { idsToRemove.contains($0.id) }

        let droppedCount = dropFloatingOrbs()
        if droppedCount > 0 {
            showAchievementUnlocks(
                AchievementManager.shared.recordDrop(count: droppedCount, mode: gameMode)
            )
        }
        if droppedCount >= 3 {
            SoundManager.shared.play("big_drop_cheer", delay: 0.65)
        }
        return orbsToRemove.count + droppedCount
    }

    private func applyTypeErasePowerUp(targetType: OrbType) -> Int {
        let orbsToRemove = stuckOrbs.filter { $0.type == targetType }

        guard !orbsToRemove.isEmpty else { return 0 }

        animateClearEffects(orbsToRemove, style: .breakApart)
        let idsToRemove = Set(orbsToRemove.map { $0.id })
        stuckOrbs.removeAll { idsToRemove.contains($0.id) }

        let droppedCount = dropFloatingOrbs()
        if droppedCount > 0 {
            showAchievementUnlocks(
                AchievementManager.shared.recordDrop(count: droppedCount, mode: gameMode)
            )
        }
        if droppedCount >= 3 {
            SoundManager.shared.play("big_drop_cheer", delay: 0.65)
        }
        return orbsToRemove.count + droppedCount
    }

    private func nearestExistingOrbType(to position: CGPoint, excluding newOrbID: UUID) -> OrbType? {
        stuckOrbs
            .filter { $0.id != newOrbID }
            .min { lhs, rhs in
                distance(from: lhs.position, to: position) < distance(from: rhs.position, to: position)
            }?
            .type
    }

    private func moveBoardDown() {
        ceilingY += boardDropAmount
        stuckOrbs = stuckOrbs.map { orb in
            StuckOrb(
                type: orb.type,
                position: CGPoint(x: orb.position.x, y: orb.position.y + boardDropAmount)
            )
        }
    }

    private func checkForNewUnlock(mode: GameMode, difficulty: Difficulty) -> String? {
        switch (mode, difficulty) {
        case (.classic, .easy):
            if !UnlockManager.shared.classicMediumUnlocked { return "Classic Medium Unlocked!" }
        case (.classic, .medium):
            if !UnlockManager.shared.classicHardUnlocked { return "Classic Hard Unlocked!" }
        case (.classic, .hard):
            if !UnlockManager.shared.counterEasyUnlocked { return "Counter Mode Unlocked!" }
        case (.counter, .easy):
            if !UnlockManager.shared.counterMediumUnlocked { return "Counter Medium Unlocked!" }
        case (.counter, .medium):
            if !UnlockManager.shared.counterHardUnlocked { return "Counter Hard Unlocked!" }
        default:
            return nil
        }
        return nil
    }

    private func showUnlockToast(_ title: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            unlockedAchievementTitle = "🔓 " + title
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.unlockedAchievementTitle = nil
            }
        }
    }

    private func checkLevelClear() {
        if stuckOrbs.isEmpty && !isLevelClear {
            SoundManager.shared.play("level_complete")
            // Collect every unlock from this clear and show them as one queue of toasts.
            var unlockedTitles = AchievementManager.shared.recordLevelComplete(
                difficulty: difficulty,
                isAimerEnabled: isAimerEnabled
            )

            if !isPuzzleMode {
                let unlockTitle = checkForNewUnlock(mode: gameMode, difficulty: difficulty)
                UnlockManager.shared.recordWin(mode: gameMode, difficulty: difficulty)
                sessionPoints += levelPoints + 100
                if let title = unlockTitle {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showUnlockToast(title)
                    }
                }
            }

            // Puzzle scoring: points by stars, +100 if the aimer was never used this level.
            if isPuzzleMode, let puzzle = puzzleLevel {
                let threeStar = puzzle.threeStarShots ?? puzzle.parShots
                if puzzleShotsUsed <= threeStar {
                    puzzleLevelStars = 3
                } else if puzzleShotsUsed <= puzzle.twoStarShots {
                    puzzleLevelStars = 2
                } else {
                    puzzleLevelStars = 1
                }
                puzzleLevelStarPoints = PuzzleRun.starPoints(for: puzzleLevelStars)
                puzzleLevelAimerBonus = puzzleUsedAimer ? 0 : PuzzleRun.noAimerBonus
                PuzzleRun.shared.score += puzzleLevelStarPoints + puzzleLevelAimerBonus

                unlockedTitles += AchievementManager.shared.recordPuzzleLevelComplete(
                    level: puzzle,
                    stars: puzzleLevelStars,
                    aimerEnabled: PuzzleRun.shared.aimerEnabled,
                    runScore: PuzzleRun.shared.score
                )
            }

            isLevelClear = true
            movingOrb = nil
            lastCompletedLevelPoints = levelPoints
            totalPoints += 100
            unlockedTitles += AchievementManager.shared.recordScore(totalPoints: totalPoints)
            showAchievementUnlocks(unlockedTitles)
        }
    }

    private func checkGameOver() {
        if stuckOrbs.contains(where: { $0.position.y >= dangerLineY }) {
            isGameOver = true
            // In puzzle mode, reaching the danger line counts as losing the level.
            if isPuzzleMode { isPuzzleFailed = true }
        }
    }

    private func clearWeakerNeighbors(around newOrb: StuckOrb) -> Int {
        let weakerNeighbors = stuckOrbs.filter { other in
            other.id != newOrb.id &&
            distance(from: newOrb.position, to: other.position) <= orbSize * 1.15 &&
            newOrb.type.beats(other.type, in: gameMode)
        }

        guard !weakerNeighbors.isEmpty else { return 0 }

        var idsToRemove = Set<UUID>()

        for weakOrb in weakerNeighbors {
            let weakGroup = matchingGroup(startingAt: weakOrb)
            idsToRemove.formUnion(weakGroup.map { $0.id })
        }

        idsToRemove.insert(newOrb.id)

        let attackerOrb = stuckOrbs.first { $0.id == newOrb.id }
        let weakerRemovedOrbs = stuckOrbs.filter { idsToRemove.contains($0.id) && $0.id != newOrb.id }

        if let attackerOrb {
            animateClearEffects([attackerOrb], style: .typePower)
        }
        animateClearEffects(weakerRemovedOrbs, style: .breakApart)

        stuckOrbs.removeAll { idsToRemove.contains($0.id) }
        return idsToRemove.count
    }

    private func dropFloatingOrbs() -> Int {
            


        let ceilingOrbs = stuckOrbs.filter { $0.position.y <= ceilingY + orbSize * 0.75 }
        guard !ceilingOrbs.isEmpty else {
            let floatingOrbs = stuckOrbs
            animateFallingOrbs(floatingOrbs)
            let count = stuckOrbs.count
            stuckOrbs.removeAll()
            return count
        }

        var connectedIDs = Set<UUID>()
        var stack = ceilingOrbs

        while let orb = stack.popLast() {
            if connectedIDs.contains(orb.id) { continue }
            connectedIDs.insert(orb.id)

            let neighbors = stuckOrbs.filter { other in
                other.id != orb.id &&
                !connectedIDs.contains(other.id) &&
                distance(from: orb.position, to: other.position) <= orbSize * 1.15
            }

            stack.append(contentsOf: neighbors)
        }

        let floatingOrbs = stuckOrbs.filter { !connectedIDs.contains($0.id) }
        guard !floatingOrbs.isEmpty else { return 0 }

        animateFallingOrbs(floatingOrbs)
        let idsToRemove = Set(floatingOrbs.map { $0.id })
        stuckOrbs.removeAll { idsToRemove.contains($0.id) }
        return floatingOrbs.count
    }

    private func animateFallingOrbs(_ orbs: [StuckOrb]) {
        let visibleOrbs = orbs.count > 12 ? Array(orbs.prefix(12)) : orbs
        let falling = visibleOrbs.map { FallingOrb(type: $0.type, startPosition: $0.position) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.fallingOrbs.append(contentsOf: falling)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let fallingIDs = Set(falling.map { $0.id })
            self.fallingOrbs.removeAll { fallingIDs.contains($0.id) }
        }
    }

    private func animateClearEffects(_ orbs: [StuckOrb], style: ClearEffect.Style) {
        let effects = orbs.map { ClearEffect(type: $0.type, position: $0.position, style: style) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.clearEffects.append(contentsOf: effects)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.57) {
            let effectIDs = Set(effects.map { $0.id })
            self.clearEffects.removeAll { effectIDs.contains($0.id) }
        }
    }

    private func clearMatchingGroup(connectedTo newOrb: StuckOrb) -> Int {
        guard stuckOrbs.contains(where: { $0.id == newOrb.id }) else { return 0 }

        let group = matchingGroup(startingAt: newOrb)
        guard group.count >= 3 else { return 0 }

        let idsToRemove = Set(group.map { $0.id })
        let removedOrbs = stuckOrbs.filter { idsToRemove.contains($0.id) }

        let normalMatchCount = removedOrbs.filter { $0.type == .normal }.count
        if normalMatchCount > 0 {
            showAchievementUnlocks(
                AchievementManager.shared.recordNormalMatch(count: normalMatchCount)
            )
        }

        animateClearEffects(removedOrbs, style: .breakApart)
        stuckOrbs.removeAll { idsToRemove.contains($0.id) }
        return group.count
    }

    private func matchingGroup(startingAt startOrb: StuckOrb) -> [StuckOrb] {
        var group: [StuckOrb] = []
        var checkedIDs = Set<UUID>()
        var stack: [StuckOrb] = [startOrb]

        while let orb = stack.popLast() {
            if checkedIDs.contains(orb.id) { continue }
            checkedIDs.insert(orb.id)

            guard orb.type == startOrb.type else { continue }
            group.append(orb)

            let neighbors = stuckOrbs.filter { other in
                other.id != orb.id &&
                !checkedIDs.contains(other.id) &&
                other.type == startOrb.type &&
                distance(from: orb.position, to: other.position) <= orbSize * 1.15
            }

            stack.append(contentsOf: neighbors)
        }

        return group
    }

    private func distance(from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    private func nearestOpenGridSlot(to movingPosition: CGPoint, near anchorPosition: CGPoint) -> CGPoint {
        let slots = gridSlots(rowLimit: 18)
        let occupiedDistance = orbSize * 0.72

        let openSlots = slots.filter { slot in
            !stuckOrbs.contains { orb in
                distance(from: slot, to: orb.position) < occupiedDistance
            }
        }

        // Important: choose the closest open slot to the actual shot position.
        // This allows tight pocket shots and wall-bounce placements to work naturally.
        return openSlots.min { first, second in
            distance(from: first, to: movingPosition) < distance(from: second, to: movingPosition)
        } ?? movingPosition
    }

    private func gridSlots(rowLimit: Int) -> [CGPoint] {
        let rowSpacing = orbSize * 0.82
        let colSpacing = orbSize * 0.92
        let maxColumnCount = puzzleLevel?.columns ?? difficulty.columnCount
        let fullRowWidth = orbSize + CGFloat(maxColumnCount - 1) * colSpacing
        let fullRowStartX = (playWidth - fullRowWidth) / 2 + orbSize / 2
        let startY = ceilingY + orbSize / 2

        var slots: [CGPoint] = []

        for row in 0..<rowLimit {
            let rowOffset: CGFloat = row.isMultiple(of: 2) ? 0 : colSpacing / 2
            let count = row.isMultiple(of: 2) ? maxColumnCount : maxColumnCount - 1

            for col in 0..<count {
                slots.append(
                    CGPoint(
                        x: fullRowStartX + rowOffset + CGFloat(col) * colSpacing,
                        y: startY + CGFloat(row) * rowSpacing
                    )
                )
            }
        }

        return slots
    }

    private func showAchievementUnlocks(_ titles: [String]) {
        guard let title = titles.first else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            unlockedAchievementTitle = title
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                if unlockedAchievementTitle == title {
                    unlockedAchievementTitle = nil
                }
            }

            let remainingTitles = Array(titles.dropFirst())
            if !remainingTitles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    showAchievementUnlocks(remainingTitles)
                }
            }
        }
    }

    private func preventVisualOverlap(for startingPosition: CGPoint) -> CGPoint {
        var position = startingPosition
        let minimumDistance = orbSize * 0.98

        for _ in 0..<6 {
            for orb in stuckOrbs {
                let dx = position.x - orb.position.x
                let dy = position.y - orb.position.y
                let currentDistance = max(0.001, sqrt(dx * dx + dy * dy))

                if currentDistance < minimumDistance {
                    let pushAmount = (minimumDistance - currentDistance) / 2
                    position.x += (dx / currentDistance) * pushAmount
                    position.y += (dy / currentDistance) * pushAmount
                }
            }
        }

        return position
    }
}


struct AchievementToastView: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3.bold())
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.bold())
                    .foregroundStyle(.cyan.opacity(0.9))

                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.black.opacity(0.78))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.green.opacity(0.25), lineWidth: 1)
                }
        )
        .shadow(color: .black.opacity(0.32), radius: 14, x: 0, y: 8)
    }
}

struct LevelCompleteOverlayView: View {
    let levelPoints: Int
    let bonusPoints: Int
    let roundTotal: Int
    let shotsFired: Int
    let onNextLevel: () -> Void
    let onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("LEVEL COMPLETE")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Elemental Energy Collected")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                VStack(spacing: 10) {
                    ScoreRow(label: "Level Points", value: levelPoints)
                    ScoreRow(label: "Level Bonus", value: bonusPoints)

                    Rectangle()
                        .fill(.white.opacity(0.18))
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    ScoreRow(label: "Shots Fired", value: shotsFired, isGameTotal: false)

                    Rectangle()
                        .fill(.white.opacity(0.12))
                        .frame(height: 1)
                        .padding(.vertical, 2)

                    ScoreRow(label: "Round Total", value: roundTotal, isGameTotal: true)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.black.opacity(0.42))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(.cyan.opacity(0.22), lineWidth: 1)
                        }
                )

                HStack(spacing: 12) {
                    Button(action: onBackToMenu) {
                        Label("Menu", systemImage: "house.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white.opacity(0.92))
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.white.opacity(0.12))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(.white.opacity(0.16), lineWidth: 1)
                                    }
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onNextLevel) {
                        Label("Next Level", systemImage: "arrow.right.circle.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.92), .blue.opacity(0.82)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .cyan.opacity(0.28), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.07, green: 0.08, blue: 0.16).opacity(0.96),
                                Color(red: 0.13, green: 0.15, blue: 0.30).opacity(0.96),
                                Color(red: 0.09, green: 0.08, blue: 0.12).opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.45), .orange.opacity(0.25), .white.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    }
                    .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 14)
            )
            .padding(.horizontal, 24)
        }
    }
}

struct ScoreRow: View {
    let label: String
    let value: Int
    var isTotal: Bool = false
    var isGameTotal: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font((isTotal || isGameTotal) ? .headline.bold() : .headline)
                .foregroundStyle(.white.opacity(isTotal ? 0.95 : (isGameTotal ? 0.78 : 0.82)))

            Spacer()

            Text("\(value)")
                .font(isTotal ? .title3.bold() : .headline.bold())
                .foregroundStyle(isTotal ? .green : (isGameTotal ? .cyan.opacity(0.92) : .white))
        }
    }
}






struct FreezeTypeButton: View {
    let type: OrbType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                OrbView(type: type, size: 48)

                Text(type.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.cyan.opacity(0.30), lineWidth: 1)
            )
    }
}

struct FreezeTypePickerSheetView: View {
    let orbTypes: [OrbType]
    let onSelectType: (OrbType) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.16),
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.05, green: 0.07, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.22)

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type Freeze")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Choose one type to block for 10 throws.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(orbTypes.enumerated()), id: \.offset) { item in
                        FreezeTypeButton(type: item.element) {
                            onSelectType(item.element)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Text("Frozen types will not appear as the current or next orb while the freeze is active.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.horizontal, 30)

                Spacer()
            }
        }
    }
}


struct PowerUpPickerSheetView: View {
    let bombCount: Int
    let freezeCount: Int
    let eraseCount: Int
    let activePowerUp: ActivePowerUp?
    let frozenType: OrbType?
    let frozenShotsRemaining: Int
    let onSelectBomb: () -> Void
    let onSelectFreeze: () -> Void
    let onSelectErase: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.16),
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.05, green: 0.07, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Powerups")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Choose one to load for your next shot.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                if let activePowerUp {
                    Text("\(activePowerUp.title) is loaded for the next shot.")
                        .font(.headline.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 24)
                } else if let frozenType, frozenShotsRemaining > 0 {
                    Text("\(frozenType.symbol) is frozen for \(frozenShotsRemaining) throws.")
                        .font(.headline.bold())
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 14) {
                    PowerUpPickerCardView(
                        title: "Bomb Orb",
                        subtitle: "Loads a bomb shot that clears a 3-orb radius.",
                        symbol: "burst.fill",
                        count: bombCount,
                        color: .red,
                        action: onSelectBomb
                    )

                    PowerUpPickerCardView(
                        title: "Type Freeze",
                        subtitle: "Choose one type to block from spawning for 10 throws.",
                        symbol: "snowflake",
                        count: freezeCount,
                        color: .cyan,
                        action: onSelectFreeze
                    )

                    PowerUpPickerCardView(
                        title: "Type Erase",
                        subtitle: "Loads a shot that erases every orb matching the type you hit.",
                        symbol: "wand.and.stars",
                        count: eraseCount,
                        color: .purple,
                        action: onSelectErase
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

struct PowerUpPickerCardView: View {
    let title: String
    let subtitle: String
    let symbol: String
    let count: Int
    let color: Color
    let action: () -> Void

    private var isAvailable: Bool {
        count > 0
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(color.opacity(isAvailable ? 0.9 : 0.28))
                        .frame(width: 56, height: 56)

                    Image(systemName: symbol)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)

                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.72)))
                        .offset(x: 8, y: -6)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white.opacity(isAvailable ? 1 : 0.45))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(isAvailable ? 0.68 : 0.34))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundStyle(.white.opacity(isAvailable ? 0.65 : 0.20))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white.opacity(isAvailable ? 0.10 : 0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.white.opacity(isAvailable ? 0.14 : 0.07), lineWidth: 1)
                    }
            )
        }
        .disabled(!isAvailable)
        .buttonStyle(.plain)
    }
}

struct CurrentShotView: View {
    let type: OrbType
    let activePowerUp: ActivePowerUp?
    let size: CGFloat

    var body: some View {
        if let activePowerUp {
            PowerUpShotOrbView(powerUp: activePowerUp, size: size)
        } else {
            OrbView(type: type, size: size)
        }
    }
}

struct PowerUpShotOrbView: View {
    let powerUp: ActivePowerUp
    let size: CGFloat

    var body: some View {
        Image(powerUp.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

struct GameTopHUDView: View {
    let modeTitle: String
    let levelNumber: Int
    let difficulty: Difficulty
    let score: Int
    let nextType: OrbType
    let activePowerUp: ActivePowerUp?
    let frozenType: OrbType?
    let frozenShotsRemaining: Int
    let currentMisses: Int
    let maxMisses: Int
    var usedAimer: Bool = false
    let onBack: () -> Void
    let onRules: () -> Void
    let onPowerUp: () -> Void
    var onCounterHelp: (() -> Void)? = nil
    var chamberName: String? = nil   // Puzzle mode only — shown on the right of the danger bar
    var puzzleLevelNumber: Int? = nil   // Puzzle mode only — hides score and power-ups

    private var dangerRatio: CGFloat {
        guard maxMisses > 0 else { return 0 }
        return min(1, max(0, CGFloat(currentMisses) / CGFloat(maxMisses)))
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(.black.opacity(0.58)))
                        .overlay {
                            Circle().stroke(.white.opacity(0.18), lineWidth: 1)
                        }
                }

                HStack(spacing: 8) {
                    if let puzzleLevelNumber {
                        // Puzzle mode: no running score and no power-ups — just the level.
                        HUDLevelDifficultyCardView(
                            levelNumber: puzzleLevelNumber,
                            difficulty: difficulty,
                            subtitle: puzzleLevelNumber <= 6 ? "TUTORIAL" : "PUZZLE"
                        )
                    } else {
                        HUDLevelDifficultyCardView(
                            levelNumber: levelNumber,
                            difficulty: difficulty
                        )

                        HUDCardView(
                            label: "SCORE",
                            value: "\(score)"
                        )

                        HUDPowerUpCardView(
                            activePowerUp: activePowerUp,
                            frozenType: frozenType,
                            frozenShotsRemaining: frozenShotsRemaining,
                            action: onPowerUp
                        )
                    }
                }

                HStack(spacing: 6) {
                    if let onCounterHelp {
                        Button(action: onCounterHelp) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(.black.opacity(0.72)))
                                .overlay { Circle().stroke(.white.opacity(0.18), lineWidth: 1) }
                        }
                    }

                    Button(action: onRules) {
                        Image(systemName: "questionmark")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(.black.opacity(0.72)))
                            .overlay {
                                Circle().stroke(.white.opacity(0.18), lineWidth: 1)
                            }
                    }
                }
            }

            DangerMeterView(
                currentMisses: currentMisses,
                maxMisses: maxMisses
            )
            .frame(height: 34)
            .overlay(alignment: .leading) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("DANGER")
                        .font(.caption.bold())
                }
                .foregroundStyle(dangerRatio >= 0.75 ? .red : .orange)
                .padding(.leading, 12)
                .animation(.easeInOut(duration: 0.25), value: dangerRatio)
            }
            .overlay(alignment: .trailing) {
                if let chamberName {
                    Text(chamberName)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                        .padding(.leading, 110)   // keeps clear of the DANGER label
                        .padding(.trailing, 14)
                }
            }
        }
    }
}

struct HUDLevelDifficultyCardView: View {
    let levelNumber: Int
    let difficulty: Difficulty
    var subtitle: String? = nil   // overrides the difficulty label (puzzle mode)

    var body: some View {
        VStack(spacing: 2) {
            Text("LEVEL")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.85))

            Text("\(levelNumber)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle ?? difficulty.displayName.uppercased())
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(subtitle == nil && difficulty == .hard ? .orange : .white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(HUDPanelBackground(isActive: false))
    }
}

struct HUDCardView: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.85))

            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(HUDPanelBackground(isActive: false))
    }
}

struct HUDPanelBackground: View {
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isActive ? .orange.opacity(0.50) : .black.opacity(0.58))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? .orange.opacity(0.78) : .white.opacity(0.15), lineWidth: 1)
            }
    }
}

struct HUDNextOrbCardView: View {
    let nextType: OrbType

    var body: some View {
        VStack(spacing: 3) {
            Text("NEXT")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.85))

            OrbView(type: nextType, size: 23)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.58))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                }
        )
    }
}


struct HUDPowerUpCardView: View {
    let activePowerUp: ActivePowerUp?
    let frozenType: OrbType?
    let frozenShotsRemaining: Int
    let action: () -> Void

    private var isActive: Bool {
        activePowerUp != nil || frozenShotsRemaining > 0
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("POWER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan.opacity(0.85))

                if let activePowerUp {
                    Image(activePowerUp.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else if let frozenType, frozenShotsRemaining > 0 {
                    OrbView(type: frozenType, size: 26)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(HUDPanelBackground(isActive: isActive))
        }
        .buttonStyle(.plain)
    }
}

struct NextOrbBoardPreviewView: View {
    let nextType: OrbType
    let orbSize: CGFloat
    var shotsRemaining: Int? = nil

    var body: some View {
        VStack(spacing: 4) {
            Text("NEXT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .tracking(1)

            if let shotsRemaining, shotsRemaining <= 1 {
                // Puzzle mode: the current shot is the last one, so there is no next orb.
                Text("LAST")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(width: orbSize * 0.92, height: orbSize * 0.92)
            } else {
                OrbView(type: nextType, size: orbSize * 0.92)
            }

            if let shotsRemaining {
                Text("\(shotsRemaining) left")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(shotsRemaining <= 3 ? .red : .white.opacity(0.86))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.46))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
        )
        .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 4)
        .allowsHitTesting(false)
    }
}

struct PuzzleParBarView: View {
    let shotsUsed: Int
    let parShots: Int
    let threeStarShots: Int
    let twoStarShots: Int
    let isFinished: Bool

    // While playing: the best rating still possible if the NEXT shot clears the board.
    // Once cleared: the rating actually earned.
    private var stars: Int {
        if isFinished {
            if shotsUsed <= threeStarShots { return 3 }
            if shotsUsed <= twoStarShots { return 2 }
            return 1
        }
        if shotsUsed < threeStarShots { return 3 }
        if shotsUsed < twoStarShots { return 2 }
        return 1
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("Shots \(shotsUsed)")
                .foregroundStyle(.white)

            Text("·")
                .foregroundStyle(.white.opacity(0.5))

            Text("Par \(parShots)")
                .foregroundStyle(shotsUsed <= parShots ? .white : .orange)

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .foregroundStyle(index < stars ? Color.yellow : Color.white.opacity(0.22))
                        .scaleEffect(index < stars ? 1.0 : 0.85)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: stars)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.black.opacity(0.55))
                .overlay {
                    Capsule().stroke(.white.opacity(0.16), lineWidth: 1)
                }
        )
        .allowsHitTesting(false)
    }
}

struct PuzzleWallsView: View {
    let leftWallX: CGFloat
    let rightWallX: CGFloat
    let playWidth: CGFloat
    let playHeight: CGFloat

    private let wallFill = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.17, blue: 0.24).opacity(0.92),
            Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let edgeGlow = LinearGradient(
        colors: [.white.opacity(0.55), .cyan.opacity(0.35), .white.opacity(0.15)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        let rightWidth = playWidth - rightWallX

        ZStack {
            if leftWallX > 0 {
                Rectangle()
                    .fill(wallFill)
                    .frame(width: leftWallX, height: playHeight)
                    .position(x: leftWallX / 2, y: playHeight / 2)

                Rectangle()
                    .fill(edgeGlow)
                    .frame(width: 3, height: playHeight)
                    .shadow(color: .cyan.opacity(0.4), radius: 4, x: 0, y: 0)
                    .position(x: leftWallX - 1.5, y: playHeight / 2)
            }

            if rightWidth > 0 {
                Rectangle()
                    .fill(wallFill)
                    .frame(width: rightWidth, height: playHeight)
                    .position(x: rightWallX + rightWidth / 2, y: playHeight / 2)

                Rectangle()
                    .fill(edgeGlow)
                    .frame(width: 3, height: playHeight)
                    .shadow(color: .cyan.opacity(0.4), radius: 4, x: 0, y: 0)
                    .position(x: rightWallX + 1.5, y: playHeight / 2)
            }
        }
        .frame(width: playWidth, height: playHeight)
        .allowsHitTesting(false)
    }
}

struct MountainRangeView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY * 0.26))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY * 0.42))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.maxY * 0.80))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.maxY * 0.34))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY * 0.74))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.maxY * 0.38))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.68))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct TitanGroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.21, blue: 0.10),
                    Color(red: 0.25, green: 0.13, blue: 0.08),
                    Color(red: 0.08, green: 0.07, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            ForEach(0..<18, id: \.self) { index in
                let x = CGFloat((index * 47) % 320)
                let y = CGFloat(14 + (index * 31) % 150)
                Capsule()
                    .fill(.black.opacity(index.isMultiple(of: 2) ? 0.24 : 0.15))
                    .frame(width: CGFloat(18 + (index % 5) * 7), height: CGFloat(6 + (index % 3) * 3))
                    .rotationEffect(.degrees(Double(index * 19)))
                    .position(x: x, y: y)
            }
        }
        .clipShape(Rectangle())
    }
}

struct CharacterBacksView: View {
    let launcherPosition: CGPoint
    let launcherY: CGFloat

    var body: some View {
        ZStack {
            Image("herbback")
                .resizable()
                .scaledToFit()
                .frame(width: 44)
                .position(x: launcherPosition.x + 58, y: launcherY - 2)

            Image("dottyback")
                .resizable()
                .scaledToFit()
                .frame(width: 36)
                .position(x: launcherPosition.x + 96, y: launcherY + 2)
        }
        .opacity(0.92)
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
        .allowsHitTesting(false)
    }
}

struct DangerMeterView: View {
    let currentMisses: Int
    let maxMisses: Int

    private var fillRatio: CGFloat {
        guard maxMisses > 0 else { return 0 }
        return min(1, max(0, CGFloat(currentMisses) / CGFloat(maxMisses)))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.58))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(fillRatio >= 0.75 ? .red.opacity(0.55) : .white.opacity(0.14), lineWidth: 1)
                    }

                Capsule()
                    .fill(.white.opacity(0.08))
                    .frame(height: 12)
                    .padding(.horizontal, 92)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: fillRatio >= 0.75
                                ? [.orange.opacity(0.90), .red.opacity(0.95)]
                                : [.cyan.opacity(0.90), .green.opacity(0.75), .orange.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, (geometry.size.width - 104) * fillRatio), height: 12)
                    .padding(.leading, 92)
                    .shadow(color: fillRatio >= 0.75 ? .red.opacity(0.55) : .cyan.opacity(0.35), radius: 8, x: 0, y: 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: fillRatio)
            }
        }
        .accessibilityLabel("Danger meter")
        .accessibilityValue("\(currentMisses) out of \(maxMisses)")
    }
}

struct RulesSheetView: View {
    let gameMode: GameMode
    @Environment(\.dismiss) private var dismiss

    private var title: String {
        gameMode == .classic ? "Classic Rules" : "Counter Rules"
    }

    private var subtitle: String {
        gameMode == .classic
        ? "Match orbs and use Water to clear Fire."
        : "No match clears. Stronger types remove weaker types."
    }

    private var rules: [(String, String)] {
        if gameMode == .classic {
            return [
                ("1", "Match 3 or more touching orbs of the same type to clear them."),
                ("2", "Water has a special advantage: 💧 Water clears 🔥 Fire when launched next to it."),
                ("3", "Other orb types act like regular matching orbs."),
                ("4", "Orbs not connected to the ceiling fall away."),
                ("5", "The danger meter fills when you miss. Drop floating orbs to empty it.")
            ]
        } else {
            return [
                ("1", "Match-3 clearing is turned off."),
                ("2", "Clear orbs by launching a stronger type next to a weaker type."),
                ("💧", "Water beats 🔥 Fire and 🪨 Rock."),
                ("🔥", "Fire beats 🌱 Plant."),
                ("🌱", "Plant beats 💧 Water."),
                ("⚡️", "Electric beats 💧 Water."),
                ("🪨", "Rock beats ⚡️ Electric."),
                ("⚪️", "Normal does not appear in Counter Mode."),
                ("9", "Orbs not connected to the ceiling fall away.")
            ]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.16),
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.05, green: 0.07, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.18)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(subtitle)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(rules.enumerated()), id: \.offset) { _, item in
                            RuleCardView(badge: item.0, text: item.1, accent: gameMode == .classic ? .cyan : .orange)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 26)
                }
            }
        }
    }
}

struct RuleCardView: View {
    let badge: String
    let text: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.24))
                    .frame(width: 34, height: 34)

                Text(badge)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.65)
            }

            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white.opacity(0.09))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
        )
    }
}

struct ClearEffectView: View {
    let type: OrbType
    let position: CGPoint
    let style: ClearEffect.Style

    @State private var animate = false

    var body: some View {
        ZStack {
            if style == .typePower {
                Circle()
                    .stroke(type.color.opacity(0.7), lineWidth: 4)
                    .frame(width: animate ? 62 : 26, height: animate ? 62 : 26)
                    .opacity(animate ? 0 : 1)

                Text(effectSymbol)
                    .font(.system(size: animate ? 30 : 18))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.4 : 0.8)
            } else {
                Circle()
                    .stroke(.gray.opacity(0.65), lineWidth: 3)
                    .frame(width: animate ? 46 : 30, height: animate ? 46 : 30)
                    .opacity(animate ? 0 : 1)

                Text("✦")
                    .font(.system(size: animate ? 22 : 14))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.3 : 0.8)
            }
        }
        .position(position)
        .animation(.easeOut(duration: 0.48), value: animate)
        .onAppear {
            animate = true
        }
    }

    private var effectSymbol: String {
        switch type {
        case .ember: return "🔥"
        case .tide: return "💦"
        case .sprout: return "🍃"
        case .electric: return "⚡️"
        case .boulder: return "💥"
        case .normal: return "✨"
        }
    }
}

struct FallingOrbView: View {
    let type: OrbType
    let size: CGFloat
    let startPosition: CGPoint
    let dangerLineY: CGFloat

    @State private var y: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        OrbView(type: type, size: size)
            .position(x: startPosition.x, y: y)
            .opacity(opacity)
            .onAppear {
                y = startPosition.y

                // Fall straight down to the danger line
                withAnimation(.easeIn(duration: 0.6)) {
                    y = dangerLineY + size
                }

                // Disappear right as it reaches the line
                withAnimation(.linear(duration: 0.1).delay(0.55)) {
                    opacity = 0
                }
            }
    }
}

struct OrbView: View {
    let type: OrbType
    
    
    let size: CGFloat

    var body: some View {
        Image(type.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
struct SelectedGame {
    let mode: GameMode
    let difficulty: Difficulty
    let isAimerEnabled: Bool
}

struct CounterTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    private let counters: [(String, Color, String, Color)] = [
        ("💧 Water", .blue,    "🔥 Fire",      .red),
        ("💧 Water", .blue,    "🪨 Rock",      .brown),
        ("🔥 Fire",  .red,     "🌱 Plant",     .green),
        ("🌱 Plant", .green,   "💧 Water",     .blue),
        ("⚡️ Electric", .yellow, "💧 Water",  .blue),
        ("🪨 Rock",  .brown,   "⚡️ Electric", .yellow),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.16),
                    Color(red: 0.12, green: 0.14, blue: 0.28),
                    Color(red: 0.05, green: 0.07, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.18)

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Counter Guide")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Use stronger types to clear weaker ones.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(Array(counters.enumerated()), id: \.offset) { _, counter in
                        HStack(spacing: 12) {
                            Text(counter.0)
                                .font(.headline.bold())
                                .foregroundStyle(counter.1)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text("beats")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                            Text(counter.2)
                                .font(.headline.bold())
                                .foregroundStyle(counter.3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.08))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                }
                        )
                    }
                }
                .padding(.horizontal, 24)

                Text("Tap the ⚡️? button anytime during play to see this guide again.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 32)

                Button { dismiss() } label: {
                    Text("Got it — let's play!")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(
                                    colors: [.orange.opacity(0.9), .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
