import SwiftUI
import PhotosUI

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("favoriteStoresData") private var favoriteStoresData: String = ""
    
    // Control del teclado
    @FocusState private var isInputActive: Bool
    
    // Selección de fotografía
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    // Hoja para agregar tiendas
    @State private var isShowingStorePicker = false
    let allStores = ["Soriana", "H-E-B", "Walmart", "Bodega Aurrera", "Mercadito Local", "Chedraui", "S-Mart", "City Club", "Sam's Club"]
    
    var favoriteStores: [String] {
        if favoriteStoresData.isEmpty { return [] }
        return favoriteStoresData.components(separatedBy: ",")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let avatarImage {
                                avatarImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            
                            PhotosPicker("Cambiar fotografía", selection: $avatarItem, matching: .images)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .onChange(of: avatarItem) {
                                    Task {
                                        if let loaded = try? await avatarItem?.loadTransferable(type: Image.self) {
                                            avatarImage = loaded
                                        }
                                    }
                                }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    TextField("Nombre", text: $userName)
                        .focused($isInputActive)
                    
                    TextField("Correo", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($isInputActive)
                } header: {
                    Text("Datos del Usuario")
                }
                
                Section {
                    ForEach(favoriteStores, id: \.self) { store in
                        Text(store)
                    }
                    .onDelete(perform: removeStore)
                    
                    Button(action: {
                        isShowingStorePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Agregar supermercado")
                        }
                    }
                } header: {
                    Text("Supermercados Favoritos")
                } footer: {
                    Text("Desliza hacia la izquierda sobre una tienda para eliminarla.")
                }
                
                Section {
                    Button(action: {
                        isLoggedIn = false
                    }) {
                        Text("Cerrar Sesión")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Mi Cuenta")
            // Botón "Listo" para ocultar el teclado
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        isInputActive = false
                    }
                }
            }
            // Hoja emergente para seleccionar más tiendas
            .sheet(isPresented: $isShowingStorePicker) {
                NavigationStack {
                    List {
                        ForEach(allStores.filter { !favoriteStores.contains($0) }, id: \.self) { store in
                            Button(action: {
                                addStore(store)
                                isShowingStorePicker = false
                            }) {
                                Text(store)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .navigationTitle("Seleccionar Tienda")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancelar") {
                                isShowingStorePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    func addStore(_ store: String) {
        var current = favoriteStores
        current.append(store)
        favoriteStoresData = current.joined(separator: ",")
    }
    
    func removeStore(at offsets: IndexSet) {
        var current = favoriteStores
        current.remove(atOffsets: offsets)
        favoriteStoresData = current.joined(separator: ",")
    }
}
