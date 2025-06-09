//
//  Restaurant.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import Foundation

struct Restaurant: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var menu: [String: [String]] // category: [items]
    var isFavorite: Bool = false
    
    func randomMeal() -> [String: String] {
        var result: [String: String] = [:]
        for (category, items) in menu {
            if let randomItem = items.randomElement() {
                result[category] = randomItem
            }
        }
        return result
    }
    
    var itemCount: Int {
        menu.values.reduce(0) { $0 + $1.count }
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
}
