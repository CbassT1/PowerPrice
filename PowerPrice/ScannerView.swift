import SwiftUI
import FirebaseFirestore
import AVFoundation

struct ScannerView: View {
    @State private var isShowingForm = false
    @State private var cameraPermissionGranted = false
    @State private var isCameraActive = false
    
    @State private var productName = ""
    @State private var price = ""
    @State private var selectedStore = "Seleccionar..."
    
    // Variables para el buscador de supermercados
    @State private var stores: [String] = ["Cargando supermercados..."]
    @State private var showingStoreSearch = false
    
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    if cameraPermissionGranted && isCameraActive {
                        CameraPreview()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.black.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .overlay(
                                Text(cameraPermissionGranted ? "Cámara pausada" : "Se requiere acceso a la cámara para escanear.")
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            )
                    }
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 120)
                    
                    Image(systemName: "barcode")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .foregroundColor(.white.opacity(0.3))
                }
                .onTapGesture {
                    productName = ""
                    price = ""
                    selectedStore = "Seleccionar..."
                    isShowingForm = true
                }
                
                Text("Apunta al código y toca la cámara para capturar manualmente")
                    .padding()
                Spacer()
            }
            .navigationTitle("Escanear Producto")
            .onAppear {
                checkCameraPermission()
                isCameraActive = true
                cargarSupermercados()
            }
            .onDisappear {
                isCameraActive = false
            }
            .sheet(isPresented: $isShowingForm) {
                NavigationStack {
                    Form {
                        Section(header: Text("Producto Detectado")) {
                            TextField("Nombre del producto", text: $productName)
                                .focused($isInputActive)
                        }
                        
                        Section(header: Text("Precio Actual")) {
                            TextField("Precio", text: $price)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                        }
                        
                        Section(header: Text("Comercio")) {
                            Button(action: {
                                isInputActive = false
                                showingStoreSearch = true
                            }) {
                                HStack {
                                    Text(selectedStore)
                                        .foregroundColor(selectedStore == "Seleccionar..." ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .navigationTitle("Aportar Precio")
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Listo") { isInputActive = false }
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancelar") { isShowingForm = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Guardar") { guardarProductoEnFirebase() }
                        }
                    }
                    // Hoja modal anidada para el buscador de tiendas
                    .sheet(isPresented: $showingStoreSearch) {
                        StoreScannerSelectionView(
                            tiendasDisponibles: stores,
                            selectedStore: $selectedStore
                        )
                    }
                }
            }
        }
    }
    
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.cameraPermissionGranted = granted }
            }
        default:
            cameraPermissionGranted = false
        }
    }
    
    func cargarSupermercados() {
        let db = Firestore.firestore()
        db.collection("supermercados").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                var fetchedStores = docs.compactMap { $0.data()["nombre"] as? String }
                fetchedStores.sort()
                if !fetchedStores.isEmpty {
                    self.stores = fetchedStores
                }
            }
        }
    }
    
    func guardarProductoEnFirebase() {
        let safeProduct = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeStore = selectedStore.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let priceValue = Double(price), !safeProduct.isEmpty, safeStore != "Seleccionar...", !safeStore.isEmpty else { return }
        
        let db = Firestore.firestore()

        if !stores.contains(safeStore) {
            let storeID = safeStore.lowercased().folding(options: .diacriticInsensitive, locale: .current).replacingOccurrences(of: " ", with: "_")
            db.collection("supermercados").document(storeID).setData([
                "nombre": safeStore,
                "sucursales": []
            ], merge: true)
        }
        
        let textoNormalizado = "\(safeProduct)_\(safeStore)"
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
        
        let nuevoProducto: [String: Any] = [
            "nombre": safeProduct.lowercased(),
            "tienda": safeStore,
            "precio": priceValue,
            "fechaRegistro": FieldValue.serverTimestamp()
        ]
        
        db.collection("productos").document(textoNormalizado).setData(nuevoProducto, merge: true) { error in
            if let error = error {
                print("Error al guardar: \(error.localizedDescription)")
            } else {
                productName = ""
                price = ""
                selectedStore = "Seleccionar..."
                isShowingForm = false
            }
        }
    }
}

struct StoreScannerSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let tiendasDisponibles: [String]
    @Binding var selectedStore: String
    
    @State private var searchText = ""
    @State private var showCustomStoreAlert = false
    @State private var customStoreName = ""
    
    var tiendasFiltradas: [String] {
        if searchText.isEmpty {
            return tiendasDisponibles
        } else {
            return tiendasDisponibles.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Buscador inteligente (si no existe, te sugiere crearla)
                if !searchText.isEmpty && tiendasFiltradas.isEmpty {
                    Button(action: {
                        selectedStore = searchText
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.green)
                            Text("Agregar \"\(searchText)\" como nueva tienda")
                        }
                    }
                }
                
                ForEach(tiendasFiltradas, id: \.self) { tienda in
                    Button(action: {
                        selectedStore = tienda
                        dismiss()
                    }) {
                        HStack {
                            Text(tienda).foregroundColor(.primary)
                            Spacer()
                            if selectedStore == tienda {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Botón manual fijo al final de la lista
                Section {
                    Button(action: { showCustomStoreAlert = true }) {
                        HStack {
                            Image(systemName: "pencil").foregroundColor(.blue)
                            Text("Escribir otra tienda manualmente")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar Comercio")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar tienda...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("Nueva Tienda", isPresented: $showCustomStoreAlert) {
                TextField("Nombre de la tienda", text: $customStoreName)
                Button("Cancelar", role: .cancel) { }
                Button("Agregar") {
                    if !customStoreName.isEmpty {
                        selectedStore = customStoreName
                        dismiss()
                    }
                }
            } message: {
                Text("Ingresa el nombre del comercio local.")
            }
        }
    }
}
