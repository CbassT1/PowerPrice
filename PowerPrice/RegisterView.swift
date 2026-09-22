import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var nombre = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userRole") private var userRole: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Cabecera Visual
                        VStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Crear Cuenta")
                                .font(.largeTitle)
                                .bold()
                        }
                        .padding(.top, 20)
                        
                        // Formulario
                        VStack(spacing: 16) {
                            CustomInputField(icon: "person.fill", placeholder: "Nombre completo", text: $nombre)
                            
                            CustomInputField(icon: "envelope.fill", placeholder: "Correo electrónico", text: $email, keyboardType: .emailAddress)
                            
                            PasswordInputField(placeholder: "Contraseña", text: $password, isVisible: $isPasswordVisible)
                            
                            PasswordInputField(placeholder: "Confirmar contraseña", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
                        }
                        .padding(.horizontal)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Botón principal
                        Button(action: registrarUsuario) {
                            if isLoading {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Registrarse")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func registrarUsuario() {
        guard !nombre.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor, llena todos los campos."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
            return
        }
        
        isLoading = true
        errorMessage = ""
        hideKeyboard()
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                isLoading = false
                errorMessage = error.localizedDescription
                return
            }
            guard let uid = result?.user.uid else { return }
            
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "nombre": nombre, "email": email, "rol": "usuario", "supermercadosFavoritos": []
            ]
            db.collection("usuarios").document(uid).setData(userData) { error in
                isLoading = false
                if let error = error {
                    errorMessage = "Error al guardar perfil: \(error.localizedDescription)"
                } else {
                    userName = nombre
                    userEmail = email
                    userRole = "usuario"
                    isLoggedIn = true
                }
            }
        }
    }
}

// Componentes reutilizables para el diseño de los textfields
struct CustomInputField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct PasswordInputField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
            } else {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
            }
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
