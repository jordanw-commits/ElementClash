import SwiftUI

struct PuzzleCompleteOverlayView: View {
    let chamberName: String
    let shotsUsed: Int
    let parShots: Int
    let twoStarShots: Int
    let oneStarShots: Int
    let hasNextLevel: Bool
    let onNextLevel: () -> Void
    let onBackToMenu: () -> Void

    private var stars: Int {
        if shotsUsed <= parShots { return 3 }
        if shotsUsed <= twoStarShots { return 2 }
        if shotsUsed <= oneStarShots { return 1 }
        return 1
    }

    private var starText: String {
        String(repeating: "⭐️", count: stars)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("CHAMBER CLEARED")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(chamberName)
                    .font(.headline)
                    .foregroundStyle(.cyan.opacity(0.9))

                Text(starText)
                    .font(.system(size: 44))

                VStack(spacing: 8) {
                    HStack {
                        Text("Shots used")
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(shotsUsed)")
                            .bold()
                            .foregroundStyle(.white)
                    }
                    HStack {
                        Text("Par")
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(parShots)")
                            .bold()
                            .foregroundStyle(shotsUsed <= parShots ? .green : .white.opacity(0.6))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        }
                )

                HStack(spacing: 12) {
                    Button(action: onBackToMenu) {
                        Text("Main Menu")
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

                    if hasNextLevel {
                        Button(action: onNextLevel) {
                            Text("Next Chamber")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(LinearGradient(
                                            colors: [.cyan.opacity(0.9), .blue.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.16).opacity(0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.cyan.opacity(0.3), lineWidth: 1)
                    }
            )
            .padding(.horizontal, 28)
        }
    }
}

struct PuzzleFailedOverlayView: View {
    let chamberName: String
    let onRetry: () -> Void
    let onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("OUT OF SHOTS")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.red)

                Text(chamberName)
                    .font(.headline)
                    .foregroundStyle(.cyan.opacity(0.9))

                Text("💀")
                    .font(.system(size: 44))

                Text("You ran out of shots before clearing the chamber.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button(action: onBackToMenu) {
                        Text("Main Menu")
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

                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(LinearGradient(
                                        colors: [.red.opacity(0.9), .orange.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.16).opacity(0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    }
            )
            .padding(.horizontal, 28)
        }
    }
}
