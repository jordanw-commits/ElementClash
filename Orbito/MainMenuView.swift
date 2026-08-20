import SwiftUI
import GameKit

struct MainMenuView: View {
    let onSelectMode: (GameMode, Difficulty, Bool) -> Void
    var onSelectPuzzle: ((PuzzleLevel?) -> Void)? = nil

    @State private var showHowToPlay = false
    @State private var showStore = false
    @State private var showSettings = false
    @State private var selectedModeForDifficulty: GameMode?
    @State private var isAimerEnabled = true
    @State private var showAchievements = false
    @State private var unlockedAchievementTitle: String?
    @State private var showPuzzleMode = false
    @State private var showLeaderboard = false

    @AppStorage("totalPoints") private var totalPoints: Int = 0
    @AppStorage("bombOrbCount") private var bombOrbCount: Int = 0
    @AppStorage("typeFreezeCount") private var typeFreezeCount: Int = 0
    @AppStorage("typeEraseCount") private var typeEraseCount: Int = 0

    var body: some View {
        ZStack {
            Image("menu_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.24),
                    .black.opacity(0.04),
                    .black.opacity(0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 7) {
                    Text("Element Clash")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.9), .blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .shadow(color: .black.opacity(0.70), radius: 9, x: 0, y: 4)
                        .shadow(color: .cyan.opacity(0.28), radius: 14, x: 0, y: 5)

                    Text("Aim • Match • Counter • Clear")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .shadow(color: .black.opacity(0.70), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 78)

                VStack(spacing: 9) {
                    ModeCardView(
                        title: "Classic",
                        subtitle: "Match 3 orbs. Water clears Fire.",
                        symbol: "sparkles",
                        gradientColors: [.blue, .cyan]
                    ) {
                        selectedModeForDifficulty = .classic
                    }

                    ModeCardView(
                        title: "Counter Mode",
                        subtitle: "No matches. Clear with type counters.",
                        symbol: "bolt.fill",
                        gradientColors: [.purple, .orange]
                    ) {
                        selectedModeForDifficulty = .counter
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        MenuSmallButton(title: "How to Play", symbol: "book.fill", compact: true, style: .highlight) {
                            showHowToPlay = true
                        }

                        MenuSmallButton(title: "Settings", symbol: "gearshape.fill", compact: true, style: .highlight) {
                            showSettings = true
                        }
                    }

                    HStack(spacing: 10) {
                        MenuSmallButton(title: "Store", symbol: "bag.fill", compact: true, style: .highlight) {
                            showStore = true
                        }

                        MenuSmallButton(title: "Achievements", symbol: "trophy.fill", compact: true, style: .highlight) {
                            showAchievements = true
                        }
                    }

                    HStack(spacing: 10) {
                        MenuSmallButton(title: "Leaderboard", symbol: "list.number", compact: true, style: .highlight) {
                            showLeaderboard = true
                        }

                        MenuSmallButton(title: "Puzzle Mode\n(Coming Soon)", symbol: "puzzlepiece.fill", compact: true, style: .highlight) {
                        }
                        .opacity(0.45)
                        .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 45)

                Spacer()
            }
        }
        .overlay(alignment: .top) {
            if let unlockedAchievementTitle {
                StoreAchievementToastView(title: unlockedAchievementTitle)
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showStore) {
            StoreView(
                totalPoints: $totalPoints,
                bombOrbCount: $bombOrbCount,
                typeFreezeCount: $typeFreezeCount,
                typeEraseCount: $typeEraseCount
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .sheet(item: $selectedModeForDifficulty) { mode in
            DifficultySelectionView(
                mode: mode,
                isAimerEnabled: $isAimerEnabled
            ) { difficulty in
                selectedModeForDifficulty = nil
                onSelectMode(mode, difficulty, isAimerEnabled)
            }
        }
        .onAppear {
            GameCenterManager.shared.authenticate()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundEffectsVolume") private var soundEffectsVolume: Double = 0.85

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
                .opacity(0.24)

            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Adjust sound before playing.")
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

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.cyan)

                        Text("Sound Effects")
                            .font(.headline.bold())
                            .foregroundStyle(.white)

                        Spacer()

                        Text("\(Int(soundEffectsVolume * 100))%")
                            .font(.headline.bold())
                            .foregroundStyle(.cyan.opacity(0.9))
                    }

                    Slider(value: $soundEffectsVolume, in: 0...1)
                        .tint(.cyan)

                    Text("Use the buttons below to test the sound level.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.white.opacity(0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                )
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    SettingsSoundTestButton(
                        title: "Launch",
                        subtitle: "Orb shot sound",
                        symbol: "paperplane.fill",
                        soundName: "orb_launch"
                    )

                    SettingsSoundTestButton(
                        title: "Clear",
                        subtitle: "Match or counter clear",
                        symbol: "sparkles",
                        soundName: "orb_clear"
                    )

                    SettingsSoundTestButton(
                        title: "Big Drop",
                        subtitle: "Herb reaction",
                        symbol: "arrow.down.circle.fill",
                        soundName: "big_drop_cheer"
                    )

                    SettingsSoundTestButton(
                        title: "Level Complete",
                        subtitle: "Celebration sound",
                        symbol: "flag.checkered",
                        soundName: "level_complete"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .presentationDetents([.large])
    }
}

struct SettingsSoundTestButton: View {
    let title: String
    let subtitle: String
    let symbol: String
    let soundName: String

    var body: some View {
        Button {
            SoundManager.shared.play(soundName)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.cyan.opacity(0.22))
                        .frame(width: 48, height: 48)

                    Image(systemName: symbol)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan.opacity(0.9))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            )
        }
        .buttonStyle(.plain)
    }
}

struct StoreAchievementToastView: View {
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

struct StoreView: View {
    @Binding var totalPoints: Int
    @Binding var bombOrbCount: Int
    @Binding var typeFreezeCount: Int
    @Binding var typeEraseCount: Int

    @State private var unlockedAchievementTitle: String?

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

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.28)

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Spend points on helpful power-ups.")
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

                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.title3.bold())
                        .foregroundStyle(.cyan)

                    Text("\(totalPoints) Points")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                )
                .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    StoreItemCardView(
                        title: "Bomb Orb",
                        subtitle: "Blows up orbs within a 3-orb radius.",
                        symbol: "orb_bomb",
                        color: .red,
                        cost: 500,
                        ownedCount: bombOrbCount,
                        totalPoints: totalPoints
                    ) {
                        buyItem(cost: 500) {
                            bombOrbCount += 1
                            showAchievementUnlocks(
                                AchievementManager.shared.recordPurchase(.bomb)
                            )
                        }
                    }

                    StoreItemCardView(
                        title: "Type Freeze",
                        subtitle: "Block a type from spawning for 10 shots.",
                        symbol: "orb_freeze",
                        color: .cyan,
                        cost: 800,
                        ownedCount: typeFreezeCount,
                        totalPoints: totalPoints
                    ) {
                        buyItem(cost: 800) {
                            typeFreezeCount += 1
                            showAchievementUnlocks(
                                AchievementManager.shared.recordPurchase(.typeFreeze)
                            )
                        }
                    }

                    StoreItemCardView(
                        title: "Type Erase",
                        subtitle: "Removes all orbs of the type you hit.",
                        symbol: "orb_erase",
                        color: .purple,
                        cost: 1000,
                        ownedCount: typeEraseCount,
                        totalPoints: totalPoints
                    ) {
                        buyItem(cost: 1000) {
                            typeEraseCount += 1
                            showAchievementUnlocks(
                                AchievementManager.shared.recordPurchase(.typeErase)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                Text("Purchased items are available from the Power button during gameplay.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.46))
                    .padding(.horizontal, 36)
                    .padding(.top, 4)

                Spacer()
            }
        }
        .presentationDetents([.large])
        .overlay(alignment: .top) {
            if let unlockedAchievementTitle {
                StoreAchievementToastView(title: unlockedAchievementTitle)
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(50)
            }
        }
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

    private func buyItem(cost: Int, addItem: () -> Void) {
        guard totalPoints >= cost else { return }
        totalPoints -= cost
        addItem()
    }
}

struct StoreItemCardView: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let cost: Int
    let ownedCount: Int
    let totalPoints: Int
    let action: () -> Void

    private var canAfford: Bool {
        totalPoints >= cost
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(color.opacity(0.25))
                        .frame(width: 60, height: 60)

                    Image(symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .frame(width: 60, height: 60)

                    Text("\(ownedCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.7)))
                        .offset(x: 8, y: -6)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack {
                    Text("\(cost)")
                        .font(.headline.bold())
                        .foregroundStyle(canAfford ? .green : .red)

                    Text("PTS")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white.opacity(0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
            )
        }
        .disabled(!canAfford)
        .buttonStyle(.plain)
    }
}

struct DifficultySelectionView: View {
    let mode: GameMode
    @Binding var isAimerEnabled: Bool
    let onSelectDifficulty: (Difficulty) -> Void

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

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.35)

            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Choose Difficulty")
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

                Toggle(isOn: $isAimerEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aimer")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(isAimerEnabled ? "Trajectory guide is on." : "Trajectory guide is off for extra challenge.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                }
                .tint(.cyan)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                )
                .padding(.horizontal, 24)

                VStack(spacing: 14) {
                    DifficultyCardView(
                        title: "Easy",
                        subtitle: "Friendly layouts with bigger match opportunities.",
                        symbol: "leaf.fill",
                        color: .green,
                        isLocked: !UnlockManager.shared.isUnlocked(mode: mode, difficulty: .easy),
                        lockText: UnlockManager.shared.winsNeeded(mode: mode, difficulty: .easy)
                    ) {
                        onSelectDifficulty(.easy)
                    }

                    DifficultyCardView(
                        title: "Medium",
                        subtitle: "Wider board with mostly pairs and more precision.",
                        symbol: "circle.grid.cross.fill",
                        color: .orange,
                        isLocked: !UnlockManager.shared.isUnlocked(mode: mode, difficulty: .medium),
                        lockText: UnlockManager.shared.winsNeeded(mode: mode, difficulty: .medium)
                    ) {
                        onSelectDifficulty(.medium)
                    }

                    DifficultyCardView(
                        title: "Hard",
                        subtitle: "Largest board, fewer obvious clears, higher pressure.",
                        symbol: "flame.fill",
                        color: .red,
                        isLocked: !UnlockManager.shared.isUnlocked(mode: mode, difficulty: .hard),
                        lockText: UnlockManager.shared.winsNeeded(mode: mode, difficulty: .hard)
                    ) {
                        onSelectDifficulty(.hard)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .presentationDetents([.large])
    }
}

struct HowToPlayView: View {
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

            OrbBackgroundView(floatAmount: -6)
                .opacity(0.35)

            VStack(spacing: 14) {
                HStack {
                    Text("How To Play")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

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

                TabView {
                    BackstoryPageView()

                    HowToPlayImagePageView(
                        imageName: "classicmode",
                        footerText: ""
                    )

                    HowToPlayImagePageView(
                        imageName: "countermode",
                        footerText: ""
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
        .presentationDetents([.large])
    }
}

struct HowToPlayImagePageView: View {
    let imageName: String
    let footerText: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)

                Text(footerText)
                    .font(.headline)
                    .foregroundStyle(.cyan.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 70)
        }
    }
}

struct BackstoryPageView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image("story_intro")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 70)
        }
    }
}

struct StoryCard: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.25))
                    .frame(width: 34, height: 34)

                Image(systemName: symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                Text(text)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
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

struct HowToPlayPageView: View {
    let title: String
    let subtitle: String
    let badgeColor: Color
    let rules: [String]
    let footer: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, badgeColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(badgeColor.opacity(0.25))
                                    .frame(width: 30, height: 30)

                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }

                            Text(rule)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.84))
                                .fixedSize(horizontal: false, vertical: true)
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

                Text(footer)
                    .font(.headline)
                    .foregroundStyle(badgeColor.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 70)
        }
    }
}

struct ModeCardView: View {
    let title: String
    let subtitle: String
    let symbol: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: gradientColors.first?.opacity(0.45) ?? .blue.opacity(0.4), radius: 10, x: 0, y: 6)

                    Image(systemName: symbol)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.bold())
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.black.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DifficultyCardView: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    var isLocked: Bool = false
    var lockText: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isLocked ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(color.gradient))
                        .frame(width: 54, height: 54)
                        .shadow(color: isLocked ? .clear : color.opacity(0.4), radius: 10, x: 0, y: 6)

                    Image(systemName: isLocked ? "lock.fill" : symbol)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(isLocked ? .white.opacity(0.4) : .white)

                    Text(isLocked ? lockText : subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(isLocked ? 0.5 : 0.68))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isLocked ? "lock.fill" : "play.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.white.opacity(isLocked ? 0.25 : 0.55))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(isLocked ? 0.05 : 0.11))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(isLocked ? 0.08 : 0.16), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 10)
            )
        }
        .disabled(isLocked)
        .buttonStyle(.plain)
    }
}

struct MenuSmallButton: View {
    let title: String
    let symbol: String
    var compact: Bool = false
    var style: ButtonStyleType = .default
    let action: () -> Void

    enum ButtonStyleType {
        case `default`
        case highlight
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 5 : 8) {
                Image(systemName: symbol)
                    .font(.system(size: compact ? 15 : 19, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(title)
                    .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 8 : 14)
            .background(
                RoundedRectangle(cornerRadius: compact ? 15 : 18)
                    .fill(backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: compact ? 15 : 18)
                            .stroke(borderColor, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.24), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .default:
            return .black.opacity(0.42)
        case .highlight:
            return .cyan.opacity(0.24)
        }
    }

    private var borderColor: Color {
        switch style {
        case .default:
            return .white.opacity(0.18)
        case .highlight:
            return .cyan.opacity(0.30)
        }
    }
}

struct OrbBackgroundView: View {
    let floatAmount: CGFloat

    var body: some View {
        ZStack {
            BackgroundOrb(color: .red, size: 86, x: 45, y: 120, floatAmount: floatAmount * 0.8)
            BackgroundOrb(color: .blue, size: 118, x: 330, y: 155, floatAmount: -floatAmount)
            BackgroundOrb(color: .green, size: 72, x: 70, y: 610, floatAmount: -floatAmount * 0.7)
            BackgroundOrb(color: .yellow, size: 62, x: 330, y: 650, floatAmount: floatAmount)
            BackgroundOrb(color: .brown, size: 92, x: 40, y: 360, floatAmount: floatAmount * 0.5)
            BackgroundOrb(color: .gray, size: 54, x: 315, y: 430, floatAmount: -floatAmount * 0.6)
        }
        .opacity(0.34)
        .blur(radius: 0.2)
        .allowsHitTesting(false)
    }
}

struct BackgroundOrb: View {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let floatAmount: CGFloat

    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 2)
            }
            .shadow(color: color.opacity(0.35), radius: 18, x: 0, y: 8)
            .position(x: x, y: y + floatAmount)
    }
}

struct MenuCharacterView: View {
    let imageName: String
    let width: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Double
    let floatAmount: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .offset(x: xOffset, y: yOffset + floatAmount)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
            .allowsHitTesting(false)
    }
}

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showEndScene = false
    @AppStorage("achievementEndScene") private var achievementEndScene: Bool = false

    @AppStorage("totalPoints") private var totalPoints: Int = 0
    @AppStorage("largestDropClassic") private var largestDropClassic: Int = 0
    @AppStorage("largestDropCounter") private var largestDropCounter: Int = 0
    @AppStorage("normalOrbsMatched") private var normalOrbsMatched: Int = 0
    @AppStorage("hardLevelsCompleted") private var hardLevelsCompleted: Int = 0
    @AppStorage("noAimerWins") private var noAimerWins: Int = 0
    @AppStorage("hardNoAimerWins") private var hardNoAimerWins: Int = 0
    @AppStorage("bombPurchased") private var bombPurchased: Bool = false
    @AppStorage("freezePurchased") private var freezePurchased: Bool = false
    @AppStorage("erasePurchased") private var erasePurchased: Bool = false

    private var achievements: [AchievementRowData] {
        [
            AchievementRowData(
                title: "Classic Dropper I",
                description: "Drop 5+ orbs at a time in Classic Mode",
                progressText: "\(min(largestDropClassic, 5)) / 5",
                isUnlocked: largestDropClassic >= 5
            ),
            AchievementRowData(
                title: "Classic Dropper II",
                description: "Drop 10+ orbs at a time in Classic Mode",
                progressText: "\(min(largestDropClassic, 10)) / 10",
                isUnlocked: largestDropClassic >= 10
            ),
            AchievementRowData(
                title: "Counter Dropper I",
                description: "Drop 5+ orbs at a time in Counter Mode",
                progressText: "\(min(largestDropCounter, 5)) / 5",
                isUnlocked: largestDropCounter >= 5
            ),
            AchievementRowData(
                title: "Counter Dropper II",
                description: "Drop 10+ orbs at a time in Counter Mode",
                progressText: "\(min(largestDropCounter, 10)) / 10",
                isUnlocked: largestDropCounter >= 10
            ),
            AchievementRowData(
                title: "Normal Master",
                description: "Match 300+ Normal orbs",
                progressText: "\(min(normalOrbsMatched, 300)) / 300",
                isUnlocked: normalOrbsMatched >= 300
            ),
            AchievementRowData(
                title: "Rising Score",
                description: "Reach 25,000 total points",
                progressText: "\(min(totalPoints, 25000)) / 25000",
                isUnlocked: totalPoints >= 25000
            ),
            AchievementRowData(
                title: "Energy Collector",
                description: "Reach 50,000 total points",
                progressText: "\(min(totalPoints, 50000)) / 50000",
                isUnlocked: totalPoints >= 50000
            ),
            AchievementRowData(
                title: "Titan Legend",
                description: "Reach 100,000 total points",
                progressText: "\(min(totalPoints, 100000)) / 100000",
                isUnlocked: totalPoints >= 100000
            ),
            AchievementRowData(
                title: "Hard Survivor",
                description: "Beat 10 levels on Hard",
                progressText: "\(min(hardLevelsCompleted, 10)) / 10",
                isUnlocked: hardLevelsCompleted >= 10
            ),
            AchievementRowData(
                title: "Hard Champion",
                description: "Beat 100 levels on Hard",
                progressText: "\(min(hardLevelsCompleted, 100)) / 100",
                isUnlocked: hardLevelsCompleted >= 100
            ),
            AchievementRowData(
                title: "No Aimer Win",
                description: "Beat a level with the aimer off",
                progressText: "\(min(noAimerWins, 1)) / 1",
                isUnlocked: noAimerWins >= 1
            ),
            AchievementRowData(
                title: "Hard No Aimer",
                description: "Beat a Hard level with the aimer off",
                progressText: "\(min(hardNoAimerWins, 1)) / 1",
                isUnlocked: hardNoAimerWins >= 1
            ),
            AchievementRowData(
                title: "Bomb Buyer",
                description: "Purchase a Bomb Orb",
                progressText: bombPurchased ? "1 / 1" : "0 / 1",
                isUnlocked: bombPurchased
            ),
            AchievementRowData(
                title: "Freeze Buyer",
                description: "Purchase a Freeze Orb",
                progressText: freezePurchased ? "1 / 1" : "0 / 1",
                isUnlocked: freezePurchased
            ),
            AchievementRowData(
                title: "Erase Buyer",
                description: "Purchase an Erase Orb",
                progressText: erasePurchased ? "1 / 1" : "0 / 1",
                isUnlocked: erasePurchased
            ),
            AchievementRowData(
                title: "End Scene",
                description: "Complete 15 levels to unlock the ending comic",
                progressText: UserDefaults.standard.bool(forKey: "achievementEndScene") ? "Unlocked" : "Locked",
                isUnlocked: UserDefaults.standard.bool(forKey: "achievementEndScene")
            )
        ]
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
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
                .opacity(0.24)

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievements")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(unlockedCount) / \(achievements.count) unlocked")
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

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(achievements) { achievement in
                            AchievementRowView(achievement: achievement)
                                .onTapGesture {
                                    if achievement.title == "End Scene" && achievementEndScene {
                                        showEndScene = true
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(24)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showEndScene) {
            EndSceneView()
        }
    }
}

struct AchievementRowData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let progressText: String
    let isUnlocked: Bool
}

struct AchievementRowView: View {
    let achievement: AchievementRowData

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? .green.opacity(0.24) : .white.opacity(0.08))
                    .frame(width: 44, height: 44)

                Image(systemName: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                    .font(.title3.bold())
                    .foregroundStyle(achievement.isUnlocked ? .green : .white.opacity(0.52))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(.headline.bold())
                    .foregroundStyle(achievement.isUnlocked ? .white : .white.opacity(0.58))

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(achievement.isUnlocked ? 0.68 : 0.42))
                    .fixedSize(horizontal: false, vertical: true)

                Text(achievement.progressText)
                    .font(.caption2.bold())
                    .foregroundStyle(achievement.isUnlocked ? .green : .cyan.opacity(0.72))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(achievement.isUnlocked ? .white.opacity(0.11) : .white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(achievement.isUnlocked ? .green.opacity(0.22) : .white.opacity(0.09), lineWidth: 1)
                }
        )
    }
}

struct EndSceneView: View {
    @Environment(\.dismiss) private var dismiss

    private let slides = [
        "slide_1_rotated",
        "slide_2_rotated",
        "slide_3_rotated",
        "slide_4_rotated",
        "slide_5_rotated"
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Text("End Scene")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                TabView {
                    ForEach(slides, id: \.self) { slide in
                        Image(slide)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 10)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Leaderboard

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false

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
                        Text("Leaderboard")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Top scores worldwide")
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

                Button {
                    GameCenterManager.shared.showLeaderboard()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "list.number")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("View Global Leaderboard")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("Powered by Game Center")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.white.opacity(0.10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            }
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Text("Sign in to Game Center in your iPhone Settings to submit and view scores.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    MainMenuView { _, _, _ in }
}
