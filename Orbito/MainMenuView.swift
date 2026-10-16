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
    @State private var showPuzzleStart = false     // aimer question, then straight into the levels
    @State private var showPuzzleLockedAlert = false

    @AppStorage("totalPoints") private var totalPoints: Int = 0
    @AppStorage("bombOrbCount") private var bombOrbCount: Int = 0
    @AppStorage("typeFreezeCount") private var typeFreezeCount: Int = 0
    @AppStorage("typeEraseCount") private var typeEraseCount: Int = 0

    // Full-art menu (ChatGPT render). Add the image to Assets as "menu_full".
    // If the asset is missing, the old built-in layout is used instead.
    private var hasRenderedMenu: Bool { UIImage(named: MenuArt.imageName) != nil }

    var body: some View {
        ZStack {
            if hasRenderedMenu {
                renderedMenu
            } else {
                legacyMenu
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
        .sheet(isPresented: $showPuzzleStart) {
            PuzzleStartView {
                showPuzzleStart = false
                onSelectPuzzle?(nil)
            }
        }
        // Game-styled "Locked" popup (replaces the system alert)
        .overlay {
            if showPuzzleLockedAlert {
                LockedPopupView(
                    title: "Locked",
                    message: "Puzzle Mode unlocks when Counter Hard does.",
                    goalText: "Win a Counter Medium game",
                    progress: min(UnlockManager.shared.counterMediumWins, 1),
                    goal: 1
                ) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        showPuzzleLockedAlert = false
                    }
                }
                .transition(.opacity)
                .zIndex(30)
            }
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


    // MARK: - Rendered (full-art) menu

    private var renderedMenu: some View {
        GeometryReader { geo in
            let scale = MenuArt.scale(for: geo.size)
            let artSize = CGSize(width: MenuArt.size.width * scale, height: MenuArt.size.height * scale)
            let origin = CGPoint(x: (geo.size.width - artSize.width) / 2,
                                 y: (geo.size.height - artSize.height) / 2)

            ZStack(alignment: .topLeading) {
                // Blurred fill behind the art, only visible on wide screens (iPad) where the art is fitted.
                Image(MenuArt.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .blur(radius: 24)
                    .overlay(Color.black.opacity(0.30))

                Image(MenuArt.imageName)
                    .resizable()
                    .frame(width: artSize.width, height: artSize.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Tap areas over the painted buttons
                MenuHotspot(rect: MenuArt.classic, scale: scale, origin: origin, label: "Classic") {
                    selectedModeForDifficulty = .classic
                }
                MenuHotspot(rect: MenuArt.counter, scale: scale, origin: origin, label: "Counter Mode") {
                    selectedModeForDifficulty = .counter
                }
                MenuHotspot(rect: MenuArt.puzzle, scale: scale, origin: origin, label: "Puzzle Mode") {
                    if UnlockManager.shared.puzzleModeUnlocked {
                        showPuzzleStart = true
                    } else {
                        withAnimation(.easeOut(duration: 0.18)) {
                            showPuzzleLockedAlert = true
                        }
                    }
                }
                MenuHotspot(rect: MenuArt.howToPlay, scale: scale, origin: origin, cornerRadius: 18, label: "How to Play") {
                    showHowToPlay = true
                }
                MenuHotspot(rect: MenuArt.settings, scale: scale, origin: origin, cornerRadius: 18, label: "Settings") {
                    showSettings = true
                }
                MenuHotspot(rect: MenuArt.store, scale: scale, origin: origin, cornerRadius: 18, label: "Store") {
                    showStore = true
                }
                MenuHotspot(rect: MenuArt.achievements, scale: scale, origin: origin, cornerRadius: 18, label: "Achievements") {
                    showAchievements = true
                }

                // Lock shade over the painted Puzzle card until it's unlocked
                if !UnlockManager.shared.puzzleModeUnlocked {
                    MenuLockShade(rect: MenuArt.puzzle, scale: scale, origin: origin)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        // The render has no Leaderboard tile, so it sits in the top-right corner.
        .overlay(alignment: .topTrailing) {
            Button {
                showLeaderboard = true
            } label: {
                Image(systemName: "crown.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.yellow)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color(red: 0.06, green: 0.12, blue: 0.30).opacity(0.85))
                            .overlay(Circle().stroke(.cyan.opacity(0.55), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Leaderboard")
            .padding(.trailing, 8)
            .padding(.top, 4)
        }
    }

    // MARK: - Legacy (built-in) menu, used only if "menu_full" isn't in Assets

    private var legacyMenu: some View {
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

                        // Puzzle Mode unlocks together with Counter Hard.
                        if UnlockManager.shared.puzzleModeUnlocked {
                            MenuSmallButton(title: "Puzzle Mode", symbol: "puzzlepiece.fill", compact: true, style: .highlight) {
                                showPuzzleStart = true
                            }
                        } else {
                            MenuSmallButton(title: "Puzzle Mode\n(Locked)", symbol: "lock.fill", compact: true, style: .highlight) {
                                showPuzzleLockedAlert = true
                            }
                            .opacity(0.55)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 45)

                Spacer()
            }
        }
    }
}

// MARK: - Full-art menu layout

// Button positions measured in pixels on the 850 x 1850 render.
// If the art is replaced with a new render, re-measure these rects.
enum MenuArt {
    static let imageName = "menu_full"
    static let size = CGSize(width: 850, height: 1850)

    static let classic      = CGRect(x: 20,  y: 510,  width: 270, height: 264)
    static let counter      = CGRect(x: 298, y: 510,  width: 254, height: 264)
    static let puzzle       = CGRect(x: 564, y: 510,  width: 268, height: 264)
    static let howToPlay    = CGRect(x: 90,  y: 1366, width: 324, height: 124)
    static let settings     = CGRect(x: 436, y: 1366, width: 326, height: 124)
    static let store        = CGRect(x: 90,  y: 1501, width: 324, height: 123)
    static let achievements = CGRect(x: 436, y: 1501, width: 326, height: 123)

    // Center of the painted puzzle-piece orb on the Puzzle card
    static let puzzleOrbCenter = CGPoint(x: 697, y: 540)

    // Everything from the title down to the bottom tiles must stay on screen.
    private static let mustShow = CGRect(x: 15, y: 150, width: 820, height: 1540)

    // Fill the screen when that keeps all the buttons visible (iPhones);
    // otherwise fit the whole image with a blurred fill behind it (iPad, very short screens).
    static func scale(for screen: CGSize) -> CGFloat {
        guard screen.width > 0, screen.height > 0 else { return 1 }
        let sx = screen.width / size.width
        let sy = screen.height / size.height
        let fill = max(sx, sy)
        let visibleW = screen.width / fill
        let visibleH = screen.height / fill
        let visible = CGRect(x: (size.width - visibleW) / 2,
                             y: (size.height - visibleH) / 2,
                             width: visibleW, height: visibleH)
        return visible.contains(mustShow) ? fill : min(sx, sy)
    }

    static func frame(_ rect: CGRect, scale: CGFloat, origin: CGPoint) -> CGRect {
        CGRect(x: origin.x + rect.minX * scale,
               y: origin.y + rect.minY * scale,
               width: rect.width * scale,
               height: rect.height * scale)
    }
}

// Invisible button over a painted button. Flashes white while pressed.
struct MenuHotspot: View {
    let rect: CGRect
    let scale: CGFloat
    let origin: CGPoint
    var cornerRadius: CGFloat = 24
    let label: String
    let action: () -> Void

    var body: some View {
        let frame = MenuArt.frame(rect, scale: scale, origin: origin)
        let radius = cornerRadius * scale * 2

        Button(action: action) {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.clear)
                .contentShape(RoundedRectangle(cornerRadius: radius))
        }
        .buttonStyle(MenuHotspotPressStyle(cornerRadius: radius))
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .accessibilityLabel(label)
    }
}

struct MenuHotspotPressStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(configuration.isPressed ? 0.22 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Locked styling (matches the painted menu art)

enum LockedStyle {
    static let gold = LinearGradient(
        colors: [Color(red: 1.00, green: 0.94, blue: 0.58), Color(red: 1.00, green: 0.72, blue: 0.20)],
        startPoint: .top, endPoint: .bottom
    )
    static let goldEdge = Color(red: 0.35, green: 0.14, blue: 0.02)
    static let purpleFill = LinearGradient(
        colors: [Color(red: 0.42, green: 0.16, blue: 0.72), Color(red: 0.17, green: 0.06, blue: 0.36)],
        startPoint: .top, endPoint: .bottom
    )
    static let purpleEdge = LinearGradient(
        colors: [Color(red: 0.90, green: 0.68, blue: 1.00), Color(red: 0.58, green: 0.28, blue: 0.98)],
        startPoint: .top, endPoint: .bottom
    )
}

// Glossy purple orb with a gold lock, like the orb icons on the mode cards.
struct LockOrbBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.62, green: 0.32, blue: 0.95), Color(red: 0.24, green: 0.07, blue: 0.48)],
                    center: .init(x: 0.4, y: 0.35), startRadius: 0, endRadius: size * 0.6
                ))
            Circle()
                .stroke(LockedStyle.gold, lineWidth: max(2, size * 0.045))
            Ellipse()
                .fill(.white.opacity(0.32))
                .frame(width: size * 0.55, height: size * 0.24)
                .offset(y: -size * 0.27)
                .blur(radius: size * 0.03)
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(LockedStyle.gold)
                .shadow(color: LockedStyle.goldEdge, radius: 0, x: 0, y: max(1, size * 0.025))
                .shadow(color: .black.opacity(0.45), radius: size * 0.05, x: 0, y: size * 0.03)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.purple.opacity(0.7), radius: size * 0.15)
    }
}

// Dims the painted Puzzle card, puts a lock orb over its icon and a LOCKED ribbon on the bottom edge.
// Taps pass through to the hotspot underneath.
struct MenuLockShade: View {
    let rect: CGRect
    let scale: CGFloat
    let origin: CGPoint

    var body: some View {
        let frame = MenuArt.frame(rect, scale: scale, origin: origin)
        let orb = CGPoint(x: origin.x + MenuArt.puzzleOrbCenter.x * scale,
                          y: origin.y + MenuArt.puzzleOrbCenter.y * scale)
        let unit = scale * 2   // ~1pt on a standard iPhone

        ZStack {
            RoundedRectangle(cornerRadius: 24 * unit)
                .fill(.black.opacity(0.5))
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

            LockOrbBadge(size: 52 * unit)
                .position(orb)

            Text("LOCKED")
                .font(.system(size: 13 * unit, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(LockedStyle.gold)
                .shadow(color: LockedStyle.goldEdge, radius: 0, x: 0, y: 1.5)
                .padding(.horizontal, 14 * unit)
                .padding(.vertical, 5 * unit)
                .background(
                    Capsule()
                        .fill(LockedStyle.purpleFill)
                        .overlay(Capsule().stroke(LockedStyle.gold, lineWidth: 2))
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                )
                .position(x: frame.midX, y: frame.maxY)
        }
        .allowsHitTesting(false)
    }
}

// Game-styled popup for locked content: purple card, gold title, progress toward the unlock, blue button.
struct LockedPopupView: View {
    let title: String
    let message: String
    let goalText: String
    let progress: Int
    let goal: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    private var fraction: CGFloat {
        goal > 0 ? min(1, CGFloat(progress) / CGFloat(goal)) : 0
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(LockedStyle.gold)
                    .shadow(color: LockedStyle.goldEdge, radius: 0, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 4)

                Text(message)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Unlock progress
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(LockedStyle.gold)
                        Text(goalText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer(minLength: 6)
                        Text("\(progress) / \(goal)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LockedStyle.gold)
                    }

                    Capsule()
                        .fill(.white.opacity(0.14))
                        .frame(height: 9)
                        .overlay(alignment: .leading) {
                            GeometryReader { bar in
                                Capsule()
                                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: bar.size.width * fraction)
                            }
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.black.opacity(0.32))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.14), lineWidth: 1))
                )

                Button(action: onDismiss) {
                    Text("Got It")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.20, green: 0.58, blue: 1.00), Color(red: 0.05, green: 0.24, blue: 0.68)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cyan.opacity(0.9), lineWidth: 2))
                                .shadow(color: .cyan.opacity(0.45), radius: 8, x: 0, y: 0)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 54)
            .padding(.bottom, 22)
            .frame(maxWidth: 330)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LockedStyle.purpleFill)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(LockedStyle.purpleEdge, lineWidth: 3))
                    .shadow(color: Color.purple.opacity(0.65), radius: 20, x: 0, y: 0)
            )
            .overlay(alignment: .top) {
                LockOrbBadge(size: 84)
                    .offset(y: -42)
            }
            .padding(.horizontal, 30)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

// Puzzle Mode start: choose the aimer once for the whole run, then jump straight into the levels.
struct PuzzleStartView: View {
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isAimerEnabled = PuzzleRun.shared.aimerEnabled

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
                .opacity(0.3)

            VStack(spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Puzzle Mode")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Beat par for 3 stars. Lose a level and the run starts over.")
                            .font(.subheadline)
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

                // Aimer is chosen once here and stays locked for the whole run.
                Toggle(isOn: $isAimerEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aimer")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(isAimerEnabled
                             ? "Trajectory guide on for this run. No bonus."
                             : "Aimer off for this run: +100 bonus every level.")
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

                Text("The aimer can't be changed once the run starts.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Button {
                    PuzzleRun.shared.aimerEnabled = isAimerEnabled
                    onStart()
                } label: {
                    Text("Start")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.72, blue: 0.65), Color(red: 0.13, green: 0.77, blue: 0.37)],
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
        .presentationDetents([.medium])
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
        ] + (showsPuzzleAchievements ? puzzleAchievements : [])
    }

    // Puzzle Mode is live, so its achievements always show.
    private var showsPuzzleAchievements: Bool { true }

    // MARK: - Puzzle Mode achievements

    private var puzzleAchievements: [AchievementRowData] {
        let defaults = UserDefaults.standard
        let total = PuzzleLevels.all.count
        let oneStar = AchievementManager.puzzleLevelsWith(atLeast: 1)
        let twoStar = AchievementManager.puzzleLevelsWith(atLeast: 2)
        let threeStar = AchievementManager.puzzleLevelsWith(atLeast: 3)

        func done(_ key: String) -> Bool { defaults.bool(forKey: key) }

        return [
            AchievementRowData(
                title: "Tutorial Graduate",
                description: "Finish all 6 Puzzle Mode tutorials",
                progressText: done("achievementPuzzleTutorials") ? "Unlocked" : "Locked",
                isUnlocked: done("achievementPuzzleTutorials")
            ),
            AchievementRowData(
                title: "Puzzle Solver",
                description: "Finish the last puzzle level in a single run",
                progressText: done("achievementPuzzleSolver") ? "Unlocked" : "Locked",
                isUnlocked: done("achievementPuzzleSolver")
            ),
            AchievementRowData(
                title: "Steady Hand",
                description: "Finish Puzzle Mode with the aimer off",
                progressText: done("achievementPuzzleNoAimer") ? "Unlocked" : "Locked",
                isUnlocked: done("achievementPuzzleNoAimer")
            ),
            AchievementRowData(
                title: "Star Collector I",
                description: "Earn at least 1 star on every puzzle level",
                progressText: "\(oneStar) / \(total)",
                isUnlocked: done("achievementPuzzleStars1")
            ),
            AchievementRowData(
                title: "Star Collector II",
                description: "Earn at least 2 stars on every puzzle level",
                progressText: "\(twoStar) / \(total)",
                isUnlocked: done("achievementPuzzleStars2")
            ),
            AchievementRowData(
                title: "Perfectionist",
                description: "Earn 3 stars on every puzzle level",
                progressText: "\(threeStar) / \(total)",
                isUnlocked: done("achievementPuzzleStars3")
            ),
            AchievementRowData(
                title: "Puzzle Pro",
                description: "Score 10,000 points in a single Puzzle Mode run",
                progressText: done("achievementPuzzleScore10000") ? "Unlocked" : "Locked",
                isUnlocked: done("achievementPuzzleScore10000")
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

                Text("🎯 Scores are only submitted when playing without the aimer. Turn off the aimer in the difficulty screen to compete on the leaderboard.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange.opacity(0.85))
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                Spacer()
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    MainMenuView { _, _, _ in }
}
