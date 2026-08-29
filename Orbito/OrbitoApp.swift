import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct OrbitoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Force portrait orientation
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                        try? windowScene.requestGeometryUpdate(geometryPreferences)
                    }
                }
        }
    }
}
