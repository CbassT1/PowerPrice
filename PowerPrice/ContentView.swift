import SwiftUI
import FirebaseFirestore

struct StoreResult: Identifiable {
    let id: String
    let storeName: String
    let distance: String
    let price: Double
    var isBestPrice: Bool
}

struct ContentView: View {
    @State private var searchInput: String = ""
    @State private var activeProduct: String = ""
    @State private var results: [StoreResult] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    TextField("Buscar producto por nombre...", text: $searchInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        buscarProductoEnFirebase()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                if !activeProduct.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resultados para:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(activeProduct.capitalized)
                            .font(.title2)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView("Buscando en la nube...")
                        .padding(.top, 40)
                    Spacer()
                } else if results.isEmpty && !activeProduct.isEmpty {
                    Text("No se encontraron precios para este producto.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    Spacer()
                } else {
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
            }
            .navigationTitle("PowerPrice")
        }
    }
    
    func buscarProductoEnFirebase() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return }
        
        activeProduct = query
        isLoading = true
        results.removeAll()
        
        let db = Firestore.firestore()
        // Buscamos productos que coincidan con el nombre
        db.collection("productos")
          .whereField("nombre", isEqualTo: query)
          .getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                print("Error al buscar: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var fetchedResults: [StoreResult] = []
            var minPrice: Double = .greatestFiniteMagnitude
            
            for doc in documents {
                let data = doc.data()
                let store = data["tienda"] as? String ?? "Desconocido"
                let price = data["precio"] as? Double ?? 0.0
                
                // Mantenemos registro del precio más bajo
                if price < minPrice { minPrice = price }
                
                fetchedResults.append(StoreResult(id: doc.documentID, storeName: store, distance: "A calcular", price: price, isBestPrice: false))
            }
            
            // Marcamos el más barato
            for i in 0..<fetchedResults.count {
                if fetchedResults[i].price == minPrice {
                    fetchedResults[i].isBestPrice = true
                }
            }
            
            // Ordenamos la lista del más barato al más caro
            results = fetchedResults.sorted(by: { $0.price < $1.price })
        }
    }
}
