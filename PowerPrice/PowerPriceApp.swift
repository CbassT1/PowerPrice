import SwiftUI
import SwiftData

@main
struct PowerPriceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: ProductItem.self)
    }
}
