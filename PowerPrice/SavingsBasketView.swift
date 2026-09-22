import SwiftUI

// Estructura de datos para la canasta
struct CartItem: Codable, Identifiable {
    var id = UUID()
    let name: String
    let store: String
    let price: Double
}

struct SavingsBasketView: View {
    @AppStorage("cartItemsData") private var cartItemsData: Data = Data()
    
    var carrito: [CartItem] {
        get {
            if let decoded = try? JSONDecoder().decode([CartItem].self, from: cartItemsData) { return decoded }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) { cartItemsData = encoded }
        }
    }
    
    // Función que agrupa automáticamente los productos por tienda
    var productosAgrupados: [String: [CartItem]] {
        Dictionary(grouping: carrito, by: { $0.store })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if carrito.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Tu canasta está vacía")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        // Iteramos sobre las tiendas ordenadas alfabéticamente
                        ForEach(productosAgrupados.keys.sorted(), id: \.self) { tienda in
                            Section(header: Text(tienda).font(.headline)) {
                                ForEach(productosAgrupados[tienda] ?? []) { item in
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        Text("$\(item.price, specifier: "%.2f")")
                                            .bold()
                                    }
                                }
                                .onDelete { offsets in
                                    eliminarProducto(de: tienda, en: offsets)
                                }
                                
                                // Subtotal por tienda
                                HStack {
                                    Text("Subtotal")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("$\(subtotal(para: tienda), specifier: "%.2f")")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mi Canasta")
            .toolbar {
                if !carrito.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Vaciar") { cartItemsData = Data() }
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    func subtotal(para tienda: String) -> Double {
        let items = productosAgrupados[tienda] ?? []
        return items.reduce(0) { $0 + $1.price }
    }
    
    func eliminarProducto(de tienda: String, en offsets: IndexSet) {
        let itemsEnTienda = productosAgrupados[tienda] ?? []
        for index in offsets {
            let itemAEliminar = itemsEnTienda[index]
            if let indexOriginal = carrito.firstIndex(where: { $0.id == itemAEliminar.id }) {
                var actual = carrito
                actual.remove(at: indexOriginal)
                
                // FIX: Guardamos directamente en la variable en memoria
                if let encoded = try? JSONEncoder().encode(actual) {
                    cartItemsData = encoded
                }
            }
        }
    }
}
