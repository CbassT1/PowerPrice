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
    
    @State private var showingAddFavorite = false
    @State private var tiendasDisponibles: [String] = []
    
    var tiendasFavoritas: [String] {
        get { favoriteStoresData.isEmpty ? [] : favoriteStoresData.components(separatedBy: ",") }
        set { favoriteStoresData = newValue.joined(separator: ",") }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Tarjeta de Cabecera (Foto de Perfil)
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                if let uiImage = UIImage(data: profileImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                
                                if isEditing {
                                    PhotosPicker(selection: $avatarItem, matching: .images) {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .onChange(of: avatarItem) {
                                        Task {
                                            if let data = try? await avatarItem?.loadTransferable(type: Data.self),
                                               let uiImage = UIImage(data: data),
                                               let compressed = uiImage.jpegData(compressionQuality: 0.1) {
                                                profileImageData = compressed
                                            }
                                        }
                                    }
                                }
                            }
                            
                            VStack(spacing: 4) {
                                if isEditing {
                                    TextField("Tu Nombre", text: $tempName)
                                        .font(.title2).bold()
                                        .multilineTextAlignment(.center)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 250)
                                } else {
                                    Text(userName)
                                        .font(.title2).bold()
                                }
                                Text(userEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 20)
                        
                        // 2. Tarjeta de Supermercados Favoritos
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Supermercados Favoritos")
                                    .font(.headline)
                                Spacer()
                                if isEditing {
                                    Button(action: { showingAddFavorite = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            if tiendasFavoritas.isEmpty {
                                Text("Aún no tienes favoritos agregados.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                            } else {
                                // Diseño de etiquetas (Chips) para los favoritos
                                let colums = [GridItem(.adaptive(minimum: 140), spacing: 10)]
                                LazyVGrid(columns: colums, alignment: .leading, spacing: 10) {
                                    ForEach(tiendasFavoritas, id: \.self) { tienda in
                                        HStack {
                                            Text(tienda)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                            if isEditing {
                                                Button(action: {
                                                    var actual = tiendasFavoritas
                                                    actual.removeAll(where: { $0 == tienda })
                                                    favoriteStoresData = actual.joined(separator: ",")
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red.opacity(0.8))
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 3. Botón de Cerrar Sesión
                        Button(action: cerrarSesion) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Cerrar Sesión")
                                    .bold()
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                tempName = userName
                cargarSupermercados()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Guardar" : "Editar") {
                        if isEditing { guardarCambiosEnFirebase() }
                        withAnimation { isEditing.toggle() }
                    }
                    .bold(isEditing)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { hideKeyboard() }
                }
            }
            .sheet(isPresented: $showingAddFavorite) {
                AddFavoriteStoreView(tiendasDisponibles: tiendasDisponibles, tiendasFavoritas: $favoriteStoresData)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Actualizando...").padding().background(Color.white).cornerRadius(12)
                }
            }
        }
    }
    
    // Funciones lógicas sin cambios
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
        Firestore.firestore().collection("usuarios").document(uid).updateData([
            "nombre": tempName,
            "supermercadosFavoritos": tiendasFavoritas
        ]) { error in
            isLoading = false
            if let error = error { print("Error actualizando perfil: \(error.localizedDescription)") }
        }
    }
    
    func cerrarSesion() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            userName = ""; userEmail = ""; favoriteStoresData = ""; profileImageData = Data()
        } catch { print("Error: \(error.localizedDescription)") }
    }
}

// Vista anidada (Buscador de favoritos) se mantiene igual lógicamente, pero con ligeros toques visuales
struct AddFavoriteStoreView: View {
    @Environment(\.dismiss) var dismiss
    let tiendasDisponibles: [String]
    @Binding var tiendasFavoritas: String
    
    @State private var searchText = ""
    
    var arregloFavoritos: [String] { tiendasFavoritas.isEmpty ? [] : tiendasFavoritas.components(separatedBy: ",") }
    var tiendasFiltradas: [String] { searchText.isEmpty ? tiendasDisponibles : tiendasDisponibles.filter { $0.localizedCaseInsensitiveContains(searchText) } }
    
    var body: some View {
        NavigationStack {
            List(tiendasFiltradas, id: \.self) { tienda in
                let yaEsFavorito = arregloFavoritos.contains(tienda)
                HStack {
                    Text(tienda).foregroundColor(yaEsFavorito ? .gray : .primary)
                    Spacer()
                    if yaEsFavorito {
                        Text("Agregado").font(.caption).foregroundColor(.gray)
                    } else {
                        Button(action: {
                            var actual = arregloFavoritos
                            actual.append(tienda)
                            tiendasFavoritas = actual.joined(separator: ",")
                            dismiss()
                        }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.blue).font(.title3)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .navigationTitle("Añadir Supermercado")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar tienda...")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { dismiss() } } }
        }
    }
}
