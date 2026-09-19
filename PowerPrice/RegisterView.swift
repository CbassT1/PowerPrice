import SwiftUI

struct RegisterView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName") private var storedName: String = ""
    @AppStorage("userEmail") private var storedEmail: String = ""
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Crear Cuenta")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            
            TextField("Nombre completo", text: $name)
                .textFieldStyle(.roundedBorder)
            
            TextField("Correo electrónico", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Contraseña", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button(action: {
                if !name.isEmpty && !email.isEmpty && !password.isEmpty {
                    // Guardamos los datos de registro en la memoria persistente
                    storedName = name
                    storedEmail = email
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
    }
}

#Preview {
    RegisterView()
}
