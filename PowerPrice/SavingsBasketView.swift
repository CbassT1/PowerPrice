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
        get { if let decoded = try? JSONDecoder().decode([CartItem].self, from: cartItemsData) { return decoded }; return [] }
    }
    
    var productosAgrupados: [String: [CartItem]] { Dictionary(grouping: carrito, by: { $0.store }) }
    
    var totalGlobal: Double { carrito.reduce(0) { $0 + $1.price } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if carrito.isEmpty {
                    // Estado Vacío Moderno
                    VStack(spacing: 20) {
                        Image(systemName: "basket.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.3))
                        Text("Tu canasta está vacía")
                            .font(.title2).bold()
                            .foregroundColor(.primary)
                        Text("Busca productos y agrégalos para comparar tus ahorros.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    VStack(spacing: 0) {
                        List {
                            ForEach(productosAgrupados.keys.sorted(), id: \.self) { tienda in
                                Section {
                                    ForEach(productosAgrupados[tienda] ?? []) { item in
                                        HStack {
                                            Text(item.name)
                                                .font(.body)
                                            Spacer()
                                            Text("$\(item.price, specifier: "%.2f")")
                                                .font(.headline)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .onDelete { offsets in
                                        eliminarProducto(de: tienda, en: offsets)
                                    }
                                    
                                    // Subtotal de la tienda
                                    HStack {
                                        Text("Subtotal")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("$\(subtotal(para: tienda), specifier: "%.2f")")
                                            .font(.subheadline).bold()
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 8)
                                } header: {
                                    HStack {
                                        Image(systemName: "storefront.fill")
                                        Text(tienda)
                                    }
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        
                        // Panel flotante del Total
                        VStack {
                            HStack {
                                Text("Total Estimado")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("$\(totalGlobal, specifier: "%.2f")")
                                    .font(.title).bold()
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {
                                withAnimation { cartItemsData = Data() }
                            }) {
                                Text("Vaciar Canasta")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.9))
                                    .cornerRadius(14)
                            }
                            .padding(.top, 10)
                        }
                        .padding(20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
                    }
                }
            }
            .navigationTitle("Mi Canasta")
        }
    }
    
    func subtotal(para tienda: String) -> Double {
        let items = productosAgrupados[tienda] ?? []
        return items.reduce(0) { $0 + $1.price }
    }
    
    func eliminarProducto(de tienda: String, en offsets: IndexSet) {
        let itemsEnTienda = productosAgrupados[tienda] ?? []
        var actual = carrito
        
        for index in offsets {
            let itemAEliminar = itemsEnTienda[index]
            if let indexOriginal = actual.firstIndex(where: { $0.id == itemAEliminar.id }) {
                actual.remove(at: indexOriginal)
            }
        }
        
        if let encoded = try? JSONEncoder().encode(actual) {
            cartItemsData = encoded
        }
    }
}
