import SwiftUI

@main
struct TallhagenApp: App {
    init() {
        // Sets the ambient audio session and renders the quiet sound cues off the main thread.
        SoundCuePlayer.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                // The palette is tuned for a light paper background.
                .preferredColorScheme(.light)
                // Sentences follow Dynamic Type up to the largest non-accessibility size;
                // the equation rows and dot grids are not designed for the accessibility sizes.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
