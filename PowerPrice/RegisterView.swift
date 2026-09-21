import SwiftUI

struct RegisterView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName") private var storedName: String = ""
    @AppStorage("userEmail") private var storedEmail: String = ""
    @AppStorage("favoriteStoresData") private var favoriteStoresData: String = ""
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    // Teclado
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Crear Cuenta")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
            TextField("Nombre completo", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isInputActive)
            
            TextField("Correo electrónico", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($isInputActive)
            
            SecureField("Contraseña", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($isInputActive)
            
            Button(action: {
                if !name.isEmpty && !email.isEmpty && !password.isEmpty {
                    storedName = name
                    storedEmail = email
                    favoriteStoresData = "" // Limpia tiendas anteriores si había una cuenta vieja
                    isLoggedIn = true
                }
            }) {
                Text("Registrarse")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") { isInputActive = false }
            }
        }
    }
}
