import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("userRole") private var userRole: String = ""
    @AppStorage("favoriteStores") private var favoriteStoresData: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }
                
                VStack(spacing: 30) {
                    // Cabecera Visual
                    VStack(spacing: 15) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.blue)
                        
                        Text("Iniciar Sesión")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("¡Bienvenido de vuelta a PowerPrice!")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        CustomInputField(icon: "envelope.fill", placeholder: "Correo electrónico", text: $email, keyboardType: .emailAddress)
                        
                        PasswordInputField(placeholder: "Contraseña", text: $password, isVisible: $isPasswordVisible)
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
                    Button(action: iniciarSesion) {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Entrar")
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
                    
                    Spacer()
                    
                    NavigationLink(destination: RegisterView()) {
                        HStack {
                            Text("¿No tienes cuenta?")
                                .foregroundColor(.gray)
                            Text("Regístrate aquí")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func iniciarSesion() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Ingresa tu correo y contraseña."
            return
        }
        
        isLoading = true
        errorMessage = ""
        hideKeyboard()
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                isLoading = false
                errorMessage = error.localizedDescription
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // Descargamos el perfil desde Firestore
            let db = Firestore.firestore()
            db.collection("usuarios").document(uid).getDocument { document, error in
                isLoading = false
                if let document = document, document.exists {
                    let data = document.data()
                    
                    userName = data?["nombre"] as? String ?? "Usuario"
                    userEmail = data?["email"] as? String ?? email
                    userRole = data?["rol"] as? String ?? "usuario"
                    
                    if let favoritos = data?["supermercadosFavoritos"] as? [String] {
                        favoriteStoresData = favoritos.joined(separator: ",")
                    } else {
                        favoriteStoresData = ""
                    }
                    
                    isLoggedIn = true
                } else {
                    errorMessage = "No se encontró el perfil en la base de datos."
                }
            }
        }
    }
}
