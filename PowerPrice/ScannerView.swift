import SwiftUI
import FirebaseFirestore
import AVFoundation

struct ScannerView: View {
    @State private var isShowingForm = false
    @State private var cameraPermissionGranted = false
    
    @State private var productName = ""
    @State private var price = ""
    @State private var selectedStore = "Seleccionar..."
    @State private var customStore = ""
    
    let stores = ["Seleccionar...", "Soriana", "H-E-B", "Walmart", "Bodega Aurrera", "Mercado Local", "Otra"]
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    if cameraPermissionGranted {
                        CameraPreview()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.black.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .overlay(
                                Text("Se requiere acceso a la cámara para escanear.")
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
                    customStore = ""
                    isShowingForm = true
                }
                
                Text("Apunta al código y toca la cámara para capturar manualmente")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Escanear Producto")
            .onAppear {
                checkCameraPermission()
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
                            Picker("Selecciona la tienda", selection: $selectedStore) {
                                ForEach(stores, id: \.self) {
                                    Text($0)
                                }
                            }
                            
                            if selectedStore == "Otra" {
                                TextField("Nombre de la tienda", text: $customStore)
                                    .focused($isInputActive)
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
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }
    
    func guardarProductoEnFirebase() {
        let finalStore = selectedStore == "Otra" ? customStore : selectedStore
        
        // 1. Limpiamos espacios en blanco al inicio y al final
        let safeProduct = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeStore = finalStore.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let priceValue = Double(price),
              !safeProduct.isEmpty,
              safeStore != "Seleccionar...",
              !safeStore.isEmpty else { return }
        
        // 2. Generamos el ID con los textos limpios
        let textoNormalizado = "\(safeProduct)_\(safeStore)"
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "_")
        
        let db = Firestore.firestore()
        let nuevoProducto: [String: Any] = [
            "nombre": safeProduct.lowercased(),
            "tienda": safeStore,
            "precio": priceValue,
            "fechaRegistro": FieldValue.serverTimestamp()
        ]
        
        // Al usar setData con merge: true, sobrescribe el precio si el producto ya existe
        db.collection("productos").document(textoNormalizado).setData(nuevoProducto, merge: true) { error in
            if let error = error {
                print("Error al guardar: \(error.localizedDescription)")
            } else {
                print("¡Producto guardado exitosamente!")
                productName = ""
                price = ""
                selectedStore = "Seleccionar..."
                customStore = ""
                isShowingForm = false
            }
        }
    }
}
