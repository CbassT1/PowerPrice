import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("profileImageData") private var profileImageData: Data = Data()
    @AppStorage("favoriteStores") private var favoriteStoresData: String = ""
    
    @State private var isEditing: Bool = false
    @State private var tempName: String = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var isLoading = false
    
    // Estados para el buscador de tiendas
    @State private var showingAddFavorite = false
    @State private var tiendasDisponibles: [String] = []
    
    var tiendasFavoritas: [String] {
        get { favoriteStoresData.isEmpty ? [] : favoriteStoresData.components(separatedBy: ",") }
        set { favoriteStoresData = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            if let uiImage = UIImage(data: profileImageData) {
                                Image(uiImage: uiImage)
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
                            
                            if isEditing {
                                PhotosPicker("Cambiar fotografía", selection: $avatarItem, matching: .images)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .onChange(of: avatarItem) {
                                        Task {
                                            if let data = try? await avatarItem?.loadTransferable(type: Data.self),
                                               let uiImage = UIImage(data: data),
                                               let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                                                profileImageData = compressedData
                                            }
                                        }
                                    }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    Text(userEmail)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.subheadline)
                    
                    TextField("Nombre", text: $tempName)
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .gray)
                    
                } header: {
                    Text("Datos del Usuario")
                }
                
                // Nueva Sección de Favoritos
                Section(header: HStack {
                    Text("Supermercados Favoritos")
                    Spacer()
                    if isEditing {
                        Button(action: { showingAddFavorite = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }) {
                    if tiendasFavoritas.isEmpty {
                        Text("No tienes supermercados favoritos.")
                            .foregroundColor(.gray)
                            .font(.caption)
                    } else {
                        ForEach(tiendasFavoritas, id: \.self) { tienda in
                            HStack {
                                Text(tienda)
                                Spacer()
                                if isEditing {
                                    Button(action: {
                                        var actual = tiendasFavoritas
                                        actual.removeAll(where: { $0 == tienda })
                                        favoriteStoresData = actual.joined(separator: ",")
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: cerrarSesion) {
                        Text("Cerrar Sesión")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Mi Cuenta")
            .onAppear {
                tempName = userName
                cargarSupermercados()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Guardar" : "Editar") {
                        if isEditing { guardarCambiosEnFirebase() }
                        isEditing.toggle()
                    }
                    .bold(isEditing)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { hideKeyboard() }
                }
            }
            .sheet(isPresented: $showingAddFavorite) {
                // Modal para buscar y agregar
                AddFavoriteStoreView(
                    tiendasDisponibles: tiendasDisponibles,
                    tiendasFavoritas: $favoriteStoresData
                )
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Guardando...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                }
            }
        }
    }
    
    func cargarSupermercados() {
        let db = Firestore.firestore()
        db.collection("supermercados").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                var fetchedStores = docs.compactMap { $0.data()["nombre"] as? String }
                fetchedStores.sort()
                self.tiendasDisponibles = fetchedStores
            }
        }
    }
    
    func guardarCambiosEnFirebase() {
        hideKeyboard()
        userName = tempName
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        db.collection("usuarios").document(uid).updateData([
            "nombre": tempName,
            "supermercadosFavoritos": tiendasFavoritas
        ]) { error in
            isLoading = false
            if let error = error {
                print("Error actualizando perfil: \(error.localizedDescription)")
            }
        }
    }
    
    func cerrarSesion() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            userName = ""; userEmail = ""; favoriteStoresData = ""; profileImageData = Data()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}

// Vista separada para el buscador de supermercados
struct AddFavoriteStoreView: View {
    @Environment(\.dismiss) var dismiss
    let tiendasDisponibles: [String]
    @Binding var tiendasFavoritas: String
    
    @State private var searchText = ""
    
    // Convertimos el string separado por comas a un arreglo para validaciones
    var arregloFavoritos: [String] {
        tiendasFavoritas.isEmpty ? [] : tiendasFavoritas.components(separatedBy: ",")
    }
    
    var tiendasFiltradas: [String] {
        if searchText.isEmpty {
            return tiendasDisponibles
        } else {
            return tiendasDisponibles.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(tiendasFiltradas, id: \.self) { tienda in
                let yaEsFavorito = arregloFavoritos.contains(tienda)
                
                HStack {
                    Text(tienda)
                        .foregroundColor(yaEsFavorito ? .gray : .primary)
                    Spacer()
                    if yaEsFavorito {
                        Text("Agregado")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Button(action: {
                            var actual = arregloFavoritos
                            actual.append(tienda)
                            tiendasFavoritas = actual.joined(separator: ",")
                            dismiss() // Cierra la hoja automáticamente al seleccionar
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .navigationTitle("Añadir Supermercado")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar tienda...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
