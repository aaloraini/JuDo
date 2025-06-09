//
//  RestaurantStore.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import Foundation

class RestaurantStore: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    private let key = "savedRestaurants"
    
    let defaultRestaurants: [Restaurant] = [
        Restaurant(name: "McDonald's", menu: [
            "Main Dish": ["Big Mac", "McChicken", "Ayam Goreng McD (Spicy)", "Ayam Goreng McD (Regular)", "Spicy Chicken McDeluxe", "GCB (Grilled Chicken Burger)", "Filet-O-Fish", "Double Cheeseburger", "Nasi Lemak McD", "Bubur Ayam McD"],
            "Side Dish": ["French Fries", "Apple Pie", "McNuggets (6 pcs)", "McNuggets (9 pcs)", "Corn Cup", "Hash Browns"],
            "Drink": ["Coca-Cola", "Iced Milo", "Iced Lemon Tea", "Iced Latte", "Hot Coffee", "Orange Juice"],
            "Extra": ["Oreo McFlurry", "Sundae (Chocolate)", "Sundae (Strawberry)", "Cendol Sundae", "Banana Pie", "Lychee Pie"]
        ]),
        Restaurant(name: "Burger King", menu: [
            "Main Dish": ["Whopper", "Whopper Jr.", "Double Whopper", "Mushroom Swiss (Single)", "Mushroom Swiss (Double)", "Tendergrill Chicken", "Tendercrisp Chicken", "Long Chicken", "Fish N' Crisp", "Cheeseburger", "Double Cheeseburger"],
            "Side Dish": ["Fries", "Onion Rings", "Cheesy Fries", "Chicken Nuggets (6 pcs)", "Chicken Nuggets (9 pcs)"],
            "Drink": ["Coca-Cola", "Iced Lemon Tea", "Iced Milo", "Hot Coffee", "Orange Juice"],
            "Extra": ["Soft Serve Cone", "Vanilla Shake", "Chocolate Shake", "Sundae", "Apple Pie"]
        ])
    ]
    
    init() {
        load()
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Restaurant].self, from: data) else {
            restaurants = defaultRestaurants
            return
        }
        restaurants = decoded
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(restaurants) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func resetToDefault() {
        restaurants = defaultRestaurants
        save()
    }
    
    func delete(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants.remove(at: index)
            save()
        }
    }
    
    func toggleFavorite(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index].isFavorite.toggle()
            save()
        }
    }
}
