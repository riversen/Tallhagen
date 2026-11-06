import SwiftUI

@main
struct TallhagenApp: App {
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
