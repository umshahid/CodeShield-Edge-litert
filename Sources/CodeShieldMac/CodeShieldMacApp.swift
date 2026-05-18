import SwiftUI

@main
struct CodeShieldMacApp: App {
    @StateObject private var store = ConversationStore()

    var body: some Scene {
        WindowGroup("CodeShield") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 720)
        }
        .windowStyle(.titleBar)

        Window("Scammer Console", id: "scammer-console") {
            ScammerConsoleView()
                .environmentObject(store)
        }
        .windowResizability(.contentSize)
    }
}
