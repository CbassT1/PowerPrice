import SwiftUI

struct SavingsBasketView: View {
    // Leemos la misma variable de @AppStorage usando el separador "|"
    @AppStorage("carritoGuardado") private var carritoGuardadoData: String = ""
    
    var carrito: [String] {
        get { carritoGuardadoData.isEmpty ? [] : carritoGuardadoData.components(separatedBy: "|") }
        set { carritoGuardadoData = newValue.joined(separator: "|") }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack {
                    if carrito.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "cart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Tu canasta está vacía")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                        Spacer()
                    } else {
                        List {
                            ForEach(carrito, id: \.self) { item in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(item)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: eliminarProducto)
                        }
                    }
                }
            }
            .navigationTitle("Mi Canasta")
            .toolbar {
                if !carrito.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Vaciar") {
                            carritoGuardadoData = ""
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    func eliminarProducto(at offsets: IndexSet) {
        var actual = carrito
        actual.remove(atOffsets: offsets)
        carritoGuardadoData = actual.joined(separator: "|")
    }
}

#Preview {
    SavingsBasketView()
}
