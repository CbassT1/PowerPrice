import SwiftUI

struct StoreResult: Identifiable {
    let id = UUID()
    let storeName: String
    let distance: String
    let price: Double
    let isBestPrice: Bool
}

struct ContentView: View {
    @State private var searchInput: String = ""
    @State private var activeProduct: String = "Leche LALA Entera 1L"
    @State private var results: [StoreResult] = [
        StoreResult(storeName: "Walmart", distance: "450 m", price: 23.50, isBestPrice: true),
        StoreResult(storeName: "H-E-B", distance: "800 m", price: 24.00, isBestPrice: false),
        StoreResult(storeName: "Soriana", distance: "1.2 km", price: 27.90, isBestPrice: false)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    TextField("Buscar producto por nombre", text: $searchInput)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        simularBusqueda()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Botón para buscar producto")
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Producto consultado:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(activeProduct)
                        .font(.title2)
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                List(results) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.storeName)
                                .font(.headline)
                            Text("Distancia: \(item.distance)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.title3)
                                .bold()
                                .foregroundColor(item.isBestPrice ? .green : .primary)
                            
                            if item.isBestPrice {
                                Text("¡Más barato!")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
                
            }
            .navigationTitle("PowerPrice")
        }
    }
    
    func simularBusqueda() {
        if !searchInput.isEmpty {
            activeProduct = searchInput
            results = [
                StoreResult(storeName: "Walmart", distance: "300 m", price: 18.00, isBestPrice: true),
                StoreResult(storeName: "H-E-B", distance: "1.5 km", price: 21.50, isBestPrice: false)
            ]
            searchInput = ""
        }
    }
}

#Preview {
    ContentView()
}
