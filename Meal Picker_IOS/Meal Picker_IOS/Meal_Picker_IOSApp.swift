//
//  Meal_Picker_IOSApp.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI

@main
struct MealPicker_IOSApp: App {
    @StateObject private var store = RestaurantStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .onAppear {
                    if store.restaurants.isEmpty {
                        store.restaurants = store.defaultRestaurants
                    }
                }
        }
    }
}
