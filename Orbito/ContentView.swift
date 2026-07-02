import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedGame: SelectedGame?

    var body: some View {
        if let selectedGame {
            ShooterPrototypeView(
                initialGameMode: selectedGame.mode,
                initialDifficulty: selectedGame.difficulty,
                onBackToMenu: {
                    self.selectedGame = nil
                }
            )
        } else {
            MainMenuView { mode, difficulty in
                selectedGame = SelectedGame(mode: mode, difficulty: difficulty)
            }
        }
    }
}

struct SelectedGame {
    let mode: GameMode
    let difficulty: Difficulty
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

        // Hard: mostly singles, very few pairs
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

        return grid
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
    let onBackToMenu: () -> Void
    @State private var difficulty: Difficulty = .easy
    private var playWidth: CGFloat {
        let colSpacing = orbSize * 0.92
        return orbSize + CGFloat(difficulty.columnCount - 1) * colSpacing
    }
    private let playHeight: CGFloat = 560
    private let orbSize: CGFloat = 34
    private let launcherY: CGFloat = 510
    private let shotSpeed: CGFloat = 8
    private let shotCollisionDistance: CGFloat = 29
    private let boardDropAmount: CGFloat = 28
    private let startingCeilingY: CGFloat = 30
    private let dangerLineY: CGFloat = 455

    @State private var gameMode: GameMode = .classic
    @State private var aimAngle: Double = -90
    @State private var lastStableAimAngle: Double = -90
    @State private var currentType: OrbType = .tide
    @State private var movingOrb: MovingOrb?
    @State private var stuckOrbs: [StuckOrb] = []
    @State private var fallingOrbs: [FallingOrb] = []
    @State private var clearEffects: [ClearEffect] = []
    @State private var ceilingY: CGFloat = 30
    @State private var missCount: Int = 0
    @State private var isGameOver: Bool = false
    @State private var isLevelClear: Bool = false
    @State private var showRules: Bool = false
    @State private var levelNumber: Int = 1

    private let gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    onBackToMenu()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("Element Clash")
                    .font(.largeTitle.bold())

                Spacer()

                Color.clear
                    .frame(width: 44, height: 34)
            }
            .padding(.horizontal)

            Text("Level \(levelNumber)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(difficulty.displayName)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                DangerMeterView(
                    currentMisses: missCount,
                    maxMisses: difficulty.missesBeforeDrop
                )
                .frame(width: playWidth, height: 14)

                HStack(spacing: 12) {
                    if isGameOver {
                        Text("Game Over")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }

                    if isLevelClear {
                        Text("Level Clear!")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.08))
                    .frame(width: playWidth, height: playHeight)

                Rectangle()
                    .fill(.secondary.opacity(0.35))
                    .frame(width: playWidth - 28, height: 4)
                    .position(x: playWidth / 2, y: ceilingY)

                Rectangle()
                    .fill(.red.opacity(0.35))
                    .frame(width: playWidth - 36, height: 3)
                    .position(x: playWidth / 2, y: dangerLineY)

                Path { path in
                    let points = predictedTrajectoryPoints()
                    guard let firstPoint = points.first else { return }

                    path.move(to: firstPoint)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(.blue.opacity(0.55), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [10, 10]))

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

                Capsule()
                    .fill(.gray.gradient)
                    .frame(width: 22, height: 64)
                    .rotationEffect(.degrees(aimAngle + 90))
                    .position(launcherPosition)

                if movingOrb == nil && !isGameOver && !isLevelClear {
                    OrbView(type: currentType, size: orbSize)
                        .position(launcherPosition)
                }

                if let movingOrb {
                    OrbView(type: movingOrb.type, size: orbSize)
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

            HStack(spacing: 14) {
                Button {
                    showRules = true
                } label: {
                    Label("Rules", systemImage: "questionmark.circle")
                        .font(.headline)
                }
                .buttonStyle(.bordered)

                if isLevelClear {
                    Button {
                        nextLevel()
                    } label: {
                        Label("Next Level", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .padding(.top)
        .onAppear {
            gameMode = initialGameMode
            difficulty = initialDifficulty
            resetGame()
        }
        .sheet(isPresented: $showRules) {
            RulesSheetView(gameMode: gameMode)
                .presentationDetents([.medium])
        }
    }

    private func resetGame() {
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
        currentType = randomOrbForCurrentMode()
        loadFreePlayLevel(difficulty)
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
        currentType = randomOrbForCurrentMode()
        loadFreePlayLevel(difficulty)
    }

    private func randomOrbForCurrentMode() -> OrbType {
        switch gameMode {
        case .classic:
            return OrbType.allCases.randomElement()!
        case .counter:
            return OrbType.allCases.filter { $0 != .normal }.randomElement()!
        }
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

            if position.x <= radius {
                position.x = radius
                velocity.dx *= -1
                points.append(position)
            }

            if position.x >= playWidth - radius {
                position.x = playWidth - radius
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

        aimAngle = lastStableAimAngle

        let radians = aimAngle * .pi / 180
        let velocity = CGVector(
            dx: cos(radians) * shotSpeed,
            dy: sin(radians) * shotSpeed
        )

        movingOrb = MovingOrb(
            type: currentType,
            position: launcherPosition,
            velocity: velocity
        )
    }

    private func updateMovingOrb() {
        guard var orb = movingOrb else { return }

        orb.position.x += orb.velocity.dx
        orb.position.y += orb.velocity.dy

        let radius = orbSize / 2

        if orb.position.x <= radius {
            orb.position.x = radius
            orb.velocity.dx *= -1
        }

        if orb.position.x >= playWidth - radius {
            orb.position.x = playWidth - radius
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
        let newOrb = StuckOrb(type: type, position: position)
        stuckOrbs.append(newOrb)
        movingOrb = nil

        let dominanceCount = clearWeakerNeighbors(around: newOrb)
        let matchCount = gameMode == .classic ? clearMatchingGroup(connectedTo: newOrb) : 0
        let droppedCount = dropFloatingOrbs()
        let totalCleared = dominanceCount + matchCount + droppedCount

        if droppedCount > 0 {
            missCount = 0
        } else if totalCleared > 0 {
            // A clear prevents the danger meter from increasing,
            // but only dropping disconnected orbs empties the meter.
        } else {
            missCount += 1
            if missCount >= difficulty.missesBeforeDrop {
                moveBoardDown()
                missCount = 0
            }
        }

        checkLevelClear()
        checkGameOver()

        if !isLevelClear && !isGameOver {
            currentType = randomOrbForCurrentMode()
        }
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

    private func checkLevelClear() {
        if stuckOrbs.isEmpty {
            isLevelClear = true
            movingOrb = nil
        }
    }

    private func checkGameOver() {
        if stuckOrbs.contains(where: { $0.position.y >= dangerLineY }) {
            isGameOver = true
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
        let falling = orbs.map { FallingOrb(type: $0.type, startPosition: $0.position) }
        fallingOrbs.append(contentsOf: falling)

        Task {
            try? await Task.sleep(for: .milliseconds(650))
            await MainActor.run {
                let fallingIDs = Set(falling.map { $0.id })
                fallingOrbs.removeAll { fallingIDs.contains($0.id) }
            }
        }
    }

    private func animateClearEffects(_ orbs: [StuckOrb], style: ClearEffect.Style) {
        let effects = orbs.map { ClearEffect(type: $0.type, position: $0.position, style: style) }
        clearEffects.append(contentsOf: effects)

        Task {
            try? await Task.sleep(for: .milliseconds(520))
            await MainActor.run {
                let effectIDs = Set(effects.map { $0.id })
                clearEffects.removeAll { effectIDs.contains($0.id) }
            }
        }
    }

    private func clearMatchingGroup(connectedTo newOrb: StuckOrb) -> Int {
        guard stuckOrbs.contains(where: { $0.id == newOrb.id }) else { return 0 }

        let group = matchingGroup(startingAt: newOrb)
        guard group.count >= 3 else { return 0 }

        let idsToRemove = Set(group.map { $0.id })
        let removedOrbs = stuckOrbs.filter { idsToRemove.contains($0.id) }
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
        let maxColumnCount = difficulty.columnCount
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
                Capsule()
                    .fill(.gray.opacity(0.18))

                Capsule()
                    .fill(fillRatio >= 0.75 ? .red.opacity(0.75) : .orange.opacity(0.7))
                    .frame(width: geometry.size.width * fillRatio)
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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(gameMode == .classic ? "Classic Rules" : "Counter Mode Rules")
                    .font(.largeTitle.bold())

                if gameMode == .classic {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("• Match 3 or more touching orbs of the same type to clear them.")
                        Text("• 💧 Water clears 🔥 Fire when launched next to it.")
                        Text("• Other orb types act like regular matching orbs.")
                        Text("• Orbs not connected to the ceiling fall away.")
                    }
                    .font(.body)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("• Match-3 clearing is off.")
                        Text("• Clear orbs by launching a stronger type next to a weaker type.")
                        Text("• 💧 Water beats 🔥 Fire and 🪨 Boulder")
                        Text("• 🔥 Fire beats 🌱 Plant")
                        Text("• 🌱 Plant beats 💧 Water")
                        Text("• ⚡️ Electric beats 💧 Water")
                        Text("• 🪨 Boulder beats ⚡️ Electric")
                        Text("• ⚪️ Normal does not appear in Counter Mode.")
                        Text("• Orbs not connected to the ceiling fall away.")
                    }
                    .font(.body)
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
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
        ZStack {
            Circle()
                .fill(type.color.gradient)
                .frame(width: size, height: size)
                .shadow(radius: 3)

            Text(type.symbol)
                .font(.system(size: size * 0.48))
        }
    }
}

#Preview {
    ContentView()
}
