import SwiftUI
import FirebaseFirestore // Importamos Firestore

struct ScannerView: View {
    @State private var isShowingForm = false
    
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
                    CameraPreview()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipped()
                    
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
                
                Text("Apunta al código y toca la cámara para simular")
                    .padding()
                Spacer()
            }
            .navigationTitle("Escanear Producto")
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
                            // Cambiamos el botón para llamar a Firebase
                            Button("Guardar") { guardarProductoEnFirebase() }
                        }
                    }
                }
            }
        }
    }
    
    func guardarProductoEnFirebase() {
        let finalStore = selectedStore == "Otra" ? customStore : selectedStore
        
        // Validamos que los datos sean correctos antes de enviarlos
        guard let priceValue = Double(price),
              !productName.isEmpty,
              finalStore != "Seleccionar...",
              !finalStore.isEmpty else { return }
        
        // 1. Instanciamos Firestore
        let db = Firestore.firestore()
        
        // 2. Creamos un diccionario con la estructura de nuestro documento
        let nuevoProducto: [String: Any] = [
            "nombre": productName.lowercased(), // Minúsculas para facilitar búsquedas
            "tienda": finalStore,
            "precio": priceValue,
            "fechaRegistro": FieldValue.serverTimestamp() // Sello de tiempo automático
        ]
        
        // 3. Insertamos el documento en la colección "productos"
        db.collection("productos").addDocument(data: nuevoProducto) { error in
            if let error = error {
                print("Error al guardar en Firestore: \(error.localizedDescription)")
            } else {
                print("¡Producto insertado exitosamente en la nube!")
                isShowingForm = false
            }
        }
    }
}
