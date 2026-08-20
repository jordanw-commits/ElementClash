//
//  GameCenterManager.swift
//  Orbito
//
//  Created by Jordan Westlund on 8/12/26.
//

import GameKit
import UIKit

final class GameCenterManager: NSObject {
    static let shared = GameCenterManager()

    let leaderboardID = "com.flyingtire.elementclash.highscore"
    
    var onScoreSubmitted: ((Int) -> Void)?

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let vc = viewController {
                self.rootViewController?.present(vc, animated: true)
            } else if GKLocalPlayer.local.isAuthenticated {
                print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
            } else if let error {
                print("Game Center auth error: \(error.localizedDescription)")
            }
        }
    }

    func submitScore(_ score: Int) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Not authenticated — score not submitted")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                print("Score \(score) submitted to Game Center")
                await MainActor.run {
                    self.onScoreSubmitted?(score)
                }
            } catch {
                print("Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Not authenticated with Game Center")
            return
        }

        let vc = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = self
        rootViewController?.present(vc, animated: true)
    }
}

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
