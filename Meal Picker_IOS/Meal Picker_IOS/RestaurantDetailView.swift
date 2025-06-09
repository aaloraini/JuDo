//
//  RestaurantDetailView.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @State private var randomMeal: [String: String] = [:]
    @State private var showMealResult = false
    
    private let categoryOrder = ["Main Dish", "Side Dish", "Extra", "Drink"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.largeTitle)
                        .bold()
                    
                    Text("\(restaurant.itemCount) menu items")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Meal Picker
                VStack(spacing: 20) {
                    Image(systemName: "dice")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.primary)
                        .padding()
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(spacing: 8) {
                        Text("Feeling indecisive?")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Let us pick your meal")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Button(action: pickRandomMeal) {
                        HStack {
                            Text("Pick Random Meal")
                            Image(systemName: "dice.fill")
                        }
                        .font(.headline)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding()
                
                // Meal Result
                if showMealResult && !randomMeal.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Random Meal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 8)
                        
                        ForEach(categoryOrder, id: \.self) { category in
                            if let item = randomMeal[category] {
                                mealResultRow(category: category, item: item)
                            }
                        }
                        
                        ForEach(randomMeal.keys.sorted().filter { !categoryOrder.contains($0) }, id: \.self) { category in
                            if let item = randomMeal[category] {
                                mealResultRow(category: category, item: item)
                            }
                        }
                    }
                    .padding()
                    .background(AppColors.card)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Menu Categories
                ForEach(categoryOrder, id: \.self) { category in
                    if let items = restaurant.menu[category], !items.isEmpty {
                        menuCategorySection(category: category, items: items)
                    }
                }
                
                ForEach(restaurant.menu.keys.sorted().filter { !categoryOrder.contains($0) }, id: \.self) { category in
                    if let items = restaurant.menu[category], !items.isEmpty {
                        menuCategorySection(category: category, items: items)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func pickRandomMeal() {
        withAnimation {
            randomMeal = restaurant.randomMeal()
            showMealResult = true
        }
    }
    
    private func mealResultRow(category: String, item: String) -> some View {
        HStack(alignment: .top) {
            Text(category)
                .font(.headline)
                .foregroundColor(categoryColor(for: category))
                .frame(width: 100, alignment: .leading)
            
            Text(item)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.vertical, 8)
    }
    
    private func menuCategorySection(category: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: categoryIcon(for: category))
                    .foregroundColor(categoryColor(for: category))
                    .font(.system(size: 18))
                
                Text(category)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor(for: category))
                
                Spacer()
                
                Text("\(items.count) items")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Grid layout
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(categoryColor(for: category).opacity(0.12))
                        .cornerRadius(10)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Main Dish": return AppColors.mainDish
        case "Side Dish": return AppColors.sideDish
        case "Drink": return AppColors.drink
        case "Extra": return AppColors.extra
        default: return AppColors.textPrimary
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Main Dish": return "takeoutbag.and.cup.and.straw.fill"
        case "Side Dish": return "frenchfries"
        case "Drink": return "glass.fill"
        case "Extra": return "plus.app.fill"
        default: return "circle.fill"
        }
    }
}
