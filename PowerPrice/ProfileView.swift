import SwiftUI

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = true
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("favoriteStoresData") private var favoriteStoresData: String = ""
    
    let availableStores = ["Soriana", "H-E-B", "Walmart", "Bodega Aurrera", "Mercadito Local"]
    
    // Propiedad calculada de solo lectura para obtener el Set
    var favoriteStores: Set<String> {
        if favoriteStoresData.isEmpty { return [] }
        return Set(favoriteStoresData.components(separatedBy: ","))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("Cambiar fotografía")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    TextField("Nombre", text: $userName)
                    TextField("Correo", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Datos del Usuario")
                }
                
                Section {
                    ForEach(availableStores, id: \.self) { store in
                        Toggle(store, isOn: Binding(
                            get: { favoriteStores.contains(store) },
                            set: { isSelected in
                                var currentSet = favoriteStores
                                if isSelected {
                                    currentSet.insert(store)
                                } else {
                                    currentSet.remove(store)
                                }
                                // Modificamos directamente la variable @AppStorage
                                favoriteStoresData = currentSet.joined(separator: ",")
                            }
                        ))
                    }
                } header: {
                    Text("Supermercados Favoritos")
                } footer: {
                    Text("Personalizaremos tu canasta en base a tus tiendas preferidas.")
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
        }
    }
}

#Preview {
    ProfileView()
}
