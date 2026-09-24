import SwiftUI
import FirebaseFirestore

struct StoreResult: Identifiable {
    let id: String
    let productName: String // Agregado para diferenciar productos
    let storeName: String
    var distance: String
    let price: Double
    var isBestPrice: Bool
    var isFavorite: Bool = false // Nueva propiedad agregada
}

struct ContentView: View {
    @State private var searchInput: String = ""
    @State private var activeProduct: String = ""
    @State private var allFetchedResults: [StoreResult] = []
    @State private var isLoading = false
    
    // Autocompletado
    @State private var suggestions: [String] = []
    
    // Filtros
    @State private var filterFavorites = false
    @State private var filterCheapest = false
    @State private var filterNearest = false
    @State private var mostrarSoloMisFavoritos = false // Nuevo filtro local de favoritos
    
    @StateObject private var locationManager = LocationManager()
    
    @State private var showAddedAlert = false
    @State private var addedItemName = ""
    
    @AppStorage("favoriteStores") private var favoriteStoresData: String = ""
    @AppStorage("cartItemsData") private var cartItemsData: Data = Data()
    
    // Variables para agregar comercio
    @State private var mostrarAgregarSupermercado = false
    @State private var storeName: String = ""
    @State private var distance: String = ""
    @State private var price: String = ""
    @State private var isBestPrice: Bool = false
    @State private var isFavorite: Bool = false
    
    var tiendasFavoritas: [String] {
        favoriteStoresData.isEmpty ? [] : favoriteStoresData.components(separatedBy: ",")
    }
    
    var carrito: [CartItem] {
        get {
            if let decoded = try? JSONDecoder().decode([CartItem].self, from: cartItemsData) { return decoded }
            return []
        }
    }
    
    var results: [StoreResult] {
        var filteredList = allFetchedResults
        
        if filterFavorites {
            filteredList = filteredList.filter { tiendasFavoritas.contains($0.storeName) }
        }
        
        // Aplica el nuevo filtro local
        if mostrarSoloMisFavoritos {
            filteredList = filteredList.filter { $0.isFavorite }
        }
        
        if filterNearest, locationManager.isAuthorized {
            filteredList = filteredList.map { item in
                var updatedItem = item
                if let km = locationManager.distanceTo(storeName: item.storeName) {
                    updatedItem.distance = String(format: "%.1f km", km)
                } else {
                    updatedItem.distance = "Calculando..."
                }
                return updatedItem
            }
            filteredList.sort {
                let dist1 = Double($0.distance.replacingOccurrences(of: " km", with: "")) ?? 999
                let dist2 = Double($1.distance.replacingOccurrences(of: " km", with: "")) ?? 999
                return dist1 < dist2
            }
        }
        
        if !filteredList.isEmpty {
            let minPrice = filteredList.map { $0.price }.min() ?? 0
            if filterCheapest {
                filteredList = filteredList.filter { $0.price == minPrice }
            }
            for i in 0..<filteredList.count {
                filteredList[i].isBestPrice = (filteredList[i].price == minPrice)
            }
        }
        
        if !filterNearest {
            filteredList.sort(by: { $0.price < $1.price })
        }
        
        return filteredList
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }
                
                VStack(spacing: 12) {
                    // Barra de búsqueda con sugerencias en vivo
                    VStack(spacing: 0) {
                        HStack {
                            TextField("Buscar producto (ej. Leche)", text: $searchInput)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .onChange(of: searchInput) { newValue in
                                    buscarSugerencias(query: newValue)
                                }
                            
                            Button(action: {
                                hideKeyboard()
                                suggestions.removeAll()
                                buscarProductoEnFirebase(query: searchInput)
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
                        .padding(.top, 10)
                        
                        // Lista desplegable de autocompletado
                        if !suggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(suggestions, id: \.self) { sug in
                                    Button(action: {
                                        searchInput = sug.capitalized
                                        suggestions.removeAll()
                                        hideKeyboard()
                                        buscarProductoEnFirebase(query: sug)
                                    }) {
                                        HStack {
                                            Text(sug.capitalized)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "arrow.up.backward")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                    }
                                    Divider()
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
                            .padding(.horizontal)
                            .padding(.top, 5)
                            .zIndex(1) // Mantiene las sugerencias por encima de los filtros
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "Mis Favoritos", icon: "heart.fill", isSelected: $filterFavorites)
                            FilterChip(title: "Más Barato", icon: "dollarsign.circle.fill", isSelected: $filterCheapest)
                            FilterChip(title: "Más Cerca", icon: "location.fill", isSelected: $filterNearest)
                        }
                        .padding(.horizontal)
                    }
                    .zIndex(0)
                    
                    // Nuevo botón global (toggle) para filtrar la lista actual por artículos marcados con la estrella local
                    HStack {
                        Spacer()
                        Toggle(isOn: $mostrarSoloMisFavoritos) {
                            Image(systemName: mostrarSoloMisFavoritos ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(mostrarSoloMisFavoritos ? .yellow : .blue)
                        }
                        .toggleStyle(.button)
                        .tint(.clear)
                        .accessibilityLabel("Filtrar resultados por favoritos locales")
                        .padding(.horizontal)
                    }
                    
                    if isLoading {
                        ProgressView("Buscando en la nube...")
                            .padding(.top, 40)
                        Spacer()
                    } else if results.isEmpty && !activeProduct.isEmpty {
                        Text("No se encontraron precios que coincidan.")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                        Spacer()
                    } else {
                        List {
                            ForEach(results.indices, id: \.self) { index in
                                let item = results[index]
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Ahora mostramos el nombre exacto del producto
                                        Text(item.productName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Image(systemName: "storefront.fill")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                            Text(item.storeName)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if filterNearest {
                                            HStack {
                                                Image(systemName: "location.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                                Text(item.distance)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
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
                                    
                                    // Botón para agregar/quitar de favoritos
                                    Button(action: {
                                        // Modifica el estado de 'isFavorite' en allFetchedResults
                                        if let realIndex = allFetchedResults.firstIndex(where: { $0.id == item.id }) {
                                            allFetchedResults[realIndex].isFavorite.toggle()
                                        }
                                    }) {
                                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                                            .foregroundColor(item.isFavorite ? .yellow : .gray)
                                            .font(.title2)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        let newItem = CartItem(name: item.productName, store: item.storeName, price: item.price)
                                        var actual = carrito
                                        actual.append(newItem)
                                        
                                        if let encoded = try? JSONEncoder().encode(actual) {
                                            cartItemsData = encoded
                                        }
                                        
                                        addedItemName = item.productName
                                        showAddedAlert = true
                                    }) {
                                        Image(systemName: "cart.badge.plus")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                            .padding(.leading, 2)
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
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("PowerPrice")
            .toolbar {
                // Botón global en la barra de navegación para añadir comercios manualmente
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        mostrarAgregarSupermercado = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Añadir Comercio Manualmente")
                }
            }
            // Hoja modal con el formulario
            .sheet(isPresented: $mostrarAgregarSupermercado) {
                NavigationStack {
                    Form {
                        Section(header: Text("Datos del Supermercado")) {
                            TextField("Nombre (ej. Soriana, Walmart)", text: $storeName)
                            TextField("Distancia (ej. 1.5 km)", text: $distance)
                            
                            TextField("Precio del producto", text: $price)
                                .keyboardType(.decimalPad)
                        }
                        
                        Section(header: Text("Opciones Adicionales")) {
                            Toggle("¿Tiene el mejor precio?", isOn: $isBestPrice)
                                .tint(.green)
                            Toggle("Guardar en Favoritos", isOn: $isFavorite)
                                .tint(.yellow)
                        }
                    }
                    .navigationTitle("Añadir Comercio")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancelar") { mostrarAgregarSupermercado = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Guardar") {
                                let cleanPrice = price.replacingOccurrences(of: ",", with: ".")
                                guard let priceValue = Double(cleanPrice), !storeName.isEmpty else { return }
                                
                                let newStore = StoreResult(
                                    id: UUID().uuidString,
                                    productName: activeProduct.isEmpty ? "Producto Manual" : activeProduct,
                                    storeName: storeName,
                                    distance: distance.isEmpty ? "0 m" : distance,
                                    price: priceValue,
                                    isBestPrice: isBestPrice,
                                    isFavorite: isFavorite
                                )
                                
                                allFetchedResults.append(newStore)
                                
                                // Limpia variables
                                storeName = ""
                                distance = ""
                                price = ""
                                isBestPrice = false
                                isFavorite = false
                                mostrarAgregarSupermercado = false
                            }
                            .bold()
                        }
                    }
                }
            }
            .onAppear { locationManager.requestPermission() }
            .alert("Agregado a la canasta", isPresented: $showAddedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("\(addedItemName) se añadió correctamente.")
            }
        }
    }
    
    // Función para el autocompletado rápido
    func buscarSugerencias(query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.count < 2 {
            suggestions.removeAll()
            return
        }
        
        let db = Firestore.firestore()
        db.collection("productos")
            .whereField("nombre", isGreaterThanOrEqualTo: text)
            .whereField("nombre", isLessThanOrEqualTo: text + "\u{f8ff}")
            .limit(to: 5)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // Extraemos los nombres y usamos Set para eliminar duplicados (ej. si hay 5 leches lala en distintas tiendas)
                let names = documents.compactMap { $0.data()["nombre"] as? String }
                let uniqueNames = Array(Set(names)).sorted()
                self.suggestions = uniqueNames
            }
    }
    
    func buscarProductoEnFirebase(query: String) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return }
        
        activeProduct = text
        isLoading = true
        allFetchedResults.removeAll()
        
        let db = Firestore.firestore()
        db.collection("productos")
            .whereField("nombre", isGreaterThanOrEqualTo: text)
            .whereField("nombre", isLessThanOrEqualTo: text + "\u{f8ff}")
            .getDocuments { snapshot, error in
                isLoading = false
                guard let documents = snapshot?.documents else { return }
                
                var fetched: [StoreResult] = []
                
                for doc in documents {
                    let data = doc.data()
                    let prodName = data["nombre"] as? String ?? "Desconocido"
                    let store = data["tienda"] as? String ?? "Desconocido"
                    let price = data["precio"] as? Double ?? 0.0
                    // Se inicializa isFavorite como false
                    fetched.append(StoreResult(id: doc.documentID, productName: prodName.capitalized, storeName: store, distance: "A calcular", price: price, isBestPrice: false, isFavorite: false))
                }
                allFetchedResults = fetched
            }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            withAnimation { isSelected.toggle() }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .bold(isSelected)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
