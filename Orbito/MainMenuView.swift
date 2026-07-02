import SwiftUI

struct MainMenuView: View {
    let onSelectMode: (GameMode) -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text("Orbito")
                    .font(.system(size: 54, weight: .bold, design: .rounded))

                Text("Aim. Match. Counter. Clear.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                Button {
                    onSelectMode(.classic)
                } label: {
                    VStack(spacing: 6) {
                        Text("Classic")
                            .font(.title2.bold())
                        Text("Match 3 orbs. Water clears Fire.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onSelectMode(.counter)
                } label: {
                    VStack(spacing: 6) {
                        Text("Counter Mode")
                            .font(.title2.bold())
                        Text("No matches. Clear only with type counters.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("More modes coming later")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }
}