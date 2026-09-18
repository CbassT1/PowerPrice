import SwiftUI
import SwiftData

@main
struct PowerPriceApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: ProductItem.self)
    }
}
