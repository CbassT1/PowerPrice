import SwiftUI
import SwiftData

struct SavingsBasketView: View {
    @Query(filter: #Predicate<ProductItem> { $0.isSavedInBasket }) private var basketItems: [ProductItem]
    
    var groupedItems: [String: [ProductItem]] {
        Dictionary(grouping: basketItems, by: { $0.store })
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(groupedItems.keys.sorted()), id: \.self) { store in
                    Section(header: Text(store)) {
                        ForEach(groupedItems[store] ?? []) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("$\(item.price, specifier: "%.2f")")
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text("Subtotal en \(store):")
                                .bold()
                            Spacer()
                            Text("$\(calculateSubtotal(for: store), specifier: "%.2f")")
                                .bold()
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Mi Canasta")
            .overlay {
                if basketItems.isEmpty {
                    Text("Escanea productos para armar tu lista")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    func calculateSubtotal(for store: String) -> Double {
        let items = groupedItems[store] ?? []
        return items.reduce(0) { $0 + $1.price }
    }
}

#Preview {
    SavingsBasketView()
}
