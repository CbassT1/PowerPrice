import Foundation
import SwiftData

@Model
class ProductItem {
    var name: String
    var store: String
    var price: Double
    var isSavedInBasket: Bool

    init(name: String, store: String, price: Double, isSavedInBasket: Bool = true) {
        self.name = name
        self.store = store
        self.price = price
        self.isSavedInBasket = isSavedInBasket
    }
}
