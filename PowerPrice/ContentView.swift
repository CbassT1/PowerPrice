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
    
    // Feedback visual
    @State private var showAddedAlert = false
    @State private var addedItemName = ""
    
    // Memoria local (usamos | como separador para evitar conflictos con comas)
    @AppStorage("carritoGuardado") private var carritoGuardadoData: String = ""
    
    var carrito: [String] {
        get { carritoGuardadoData.isEmpty ? [] : carritoGuardadoData.components(separatedBy: "|") }
        set { carritoGuardadoData = newValue.joined(separator: "|") }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    HStack {
                        TextField("Buscar producto...", text: $searchInput)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                        
                        Button(action: { buscarProductoEnFirebase() }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
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
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.storeName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.gray)
                                        Text(item.distance)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("$\(item.price, specifier: "%.2f")")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(item.isBestPrice ? .green : .primary)
                                    
                                    if item.isBestPrice {
                                        Text("Mejor Opción")
                                            .font(.caption)
                                            .bold()
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Button(action: {
                                    let itemString = "\(activeProduct.capitalized) en \(item.storeName): $\(String(format: "%.2f", item.price))"
                                    var actual = carrito
                                    actual.append(itemString)
                                    carritoGuardadoData = actual.joined(separator: "|")
                                    
                                    addedItemName = activeProduct.capitalized
                                    showAddedAlert = true
                                }) {
                                    Image(systemName: "cart.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .padding(.leading, 10)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("PowerPrice")
            .alert("Agregado a la canasta", isPresented: $showAddedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(addedItemName) se añadió correctamente.")
            }
        }
    }
    
    func buscarProductoEnFirebase() {
        let query = searchInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return }
        
        activeProduct = query
        isLoading = true
        results.removeAll()
        
        let db = Firestore.firestore()
        db.collection("productos")
          .whereField("nombre", isGreaterThanOrEqualTo: query)
          .whereField("nombre", isLessThanOrEqualTo: query + "\u{f8ff}")
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
                
                if price < minPrice { minPrice = price }
                fetchedResults.append(StoreResult(id: doc.documentID, storeName: store, distance: "A calcular", price: price, isBestPrice: false))
            }
            
            for i in 0..<fetchedResults.count {
                if fetchedResults[i].price == minPrice { fetchedResults[i].isBestPrice = true }
            }
            
            results = fetchedResults.sorted(by: { $0.price < $1.price })
        }
    }
}
