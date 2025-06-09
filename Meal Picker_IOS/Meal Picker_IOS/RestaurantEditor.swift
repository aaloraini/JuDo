//
//  RestaurantEditor.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI  
struct RestaurantEditor: View {
    @Environment(\.dismiss) var dismiss
    @Binding var restaurants: [Restaurant]
    @State private var name: String = ""
    @State private var menu: [String: [String]] = [:]
    var editingRestaurant: Restaurant?
    
    @State private var newCategoryName = ""
    @State private var newItemName = ""
    @State private var selectedCategory: String?
    
    // Default categories to pre-add
    private let defaultCategories = ["Main Dish", "Side Dish", "Extra", "Drink"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Restaurant Information")) {
                    TextField("Restaurant Name", text: $name)
                }
                
                Section(header: Text("Menu")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(menu.keys.sorted(), id: \.self) { category in
                            Text(category).tag(category as String?)
                        }
                    }
                    
                    if let selected = selectedCategory {
                        Section(header: Text("Items in \(selected)")) {
                            ForEach(menu[selected] ?? [], id: \.self) { item in
                                Text(item)
                            }
                            .onDelete { indices in
                                deleteItems(at: indices, from: selected)
                            }
                            
                            HStack {
                                TextField("New Item", text: $newItemName)
                                Button(action: {
                                    addNewItem(to: selected)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                    }
                    
                    Section(header: Text("Add Category")) {
                        HStack {
                            TextField("New Category", text: $newCategoryName)
                            Button(action: addNewCategory) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .navigationTitle(editingRestaurant == nil ? "Add Restaurant" : "Edit Restaurant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingRestaurant == nil ? "Add" : "Save") {
                        saveRestaurant()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || menu.isEmpty)
                }
            }
            .onAppear {
                if let editing = editingRestaurant {
                    name = editing.name
                    menu = editing.menu
                    selectedCategory = menu.keys.first
                } else {
                    // Pre-add default categories for new restaurants
                    for category in defaultCategories {
                        if menu[category] == nil {
                            menu[category] = []
                        }
                    }
                    selectedCategory = defaultCategories.first
                }
            }
        }
    }
    
    private func addNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if menu[trimmed] == nil {
            menu[trimmed] = []
            selectedCategory = trimmed
            newCategoryName = ""
        }
    }
    
    private func deleteItems(at indices: IndexSet, from category: String) {
        menu[category]?.remove(atOffsets: indices)
    }
    
    private func addNewItem(to category: String) {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let selected = selectedCategory else { return }
        
        menu[selected]?.append(trimmed)
        newItemName = ""
    }
    
    private func saveRestaurant() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Filter out empty categories
        let filteredMenu = menu.filter { !$0.value.isEmpty }
        
        let restaurant = Restaurant(
            id: editingRestaurant?.id ?? UUID(),
            name: trimmedName,
            menu: filteredMenu
        )
        
        if let index = restaurants.firstIndex(where: { $0.id == editingRestaurant?.id }) {
            restaurants[index] = restaurant
        } else {
            restaurants.append(restaurant)
        }
    }
}
