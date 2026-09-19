import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Buscar", systemImage: "magnifyingglass")
                }
            
            ScannerView()
                .tabItem {
                    Label("Escanear", systemImage: "barcode.viewfinder")
                }
            
            SavingsBasketView()
                .tabItem {
                    Label("Canasta", systemImage: "cart.fill")
                }
                
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
