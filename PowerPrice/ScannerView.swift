import SwiftUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingForm = false
    @State private var productName = ""
    @State private var price = ""
    @State private var selectedStore = "Soriana"
    @State private var customStore = ""
    
    let stores = ["Soriana", "H-E-B", "Walmart", "Bodega Aurrera", "Mercado Local", "Otra"]
    
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
                    productName = "Leche Entera 1L"
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
                            TextField("Nombre", text: $productName)
                        }
                        
                        Section(header: Text("Precio Actual")) {
                            TextField("Precio", text: $price)
                                .keyboardType(.decimalPad)
                        }
                        
                        Section(header: Text("Comercio")) {
                            Picker("Selecciona la tienda", selection: $selectedStore) {
                                ForEach(stores, id: \.self) {
                                    Text($0)
                                }
                            }
                            
                            if selectedStore == "Otra" {
                                TextField("Nombre de la tienda", text: $customStore)
                            }
                        }
                    }
                    .navigationTitle("Aportar Precio")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancelar") {
                                isShowingForm = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Guardar") {
                                guardarProducto()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func guardarProducto() {
        let finalStore = selectedStore == "Otra" ? customStore : selectedStore
        if let priceValue = Double(price), !productName.isEmpty, !finalStore.isEmpty {
            let newItem = ProductItem(name: productName, store: finalStore, price: priceValue)
            modelContext.insert(newItem)
            
            productName = ""
            price = ""
            selectedStore = "Soriana"
            customStore = ""
            isShowingForm = false
        }
    }
}

#Preview {
    ScannerView()
}
