import SwiftUI

@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()

                if showOnboarding {
                    OnboardingView(isPresented: $showOnboarding)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .onChange(of: showOnboarding) { newValue in
                if !newValue {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
