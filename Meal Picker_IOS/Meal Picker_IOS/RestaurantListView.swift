//
//  RestaurantListView.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI 

struct RestaurantListView: View {
    @EnvironmentObject private var store: RestaurantStore
    @State private var showEditor = false
    @State private var editorRestaurant: Restaurant? = nil
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var restaurantToDelete: Restaurant?
    
    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return store.restaurants
        } else {
            return store.restaurants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredRestaurants.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Restaurants Found",
                        message: "Try changing your search or add a new restaurant"
                    )
                } else {
                    List {
                        ForEach(filteredRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantRow(restaurant: restaurant)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    restaurantToDelete = restaurant
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editorRestaurant = restaurant
                                    showEditor = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppColors.primary)
                                
                                Button {
                                    store.toggleFavorite(restaurant)
                                } label: {
                                    Label(restaurant.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: restaurant.isFavorite ? "heart.slash" : "heart")
                                }
                                .tint(restaurant.isFavorite ? .gray : .pink)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Restaurants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editorRestaurant = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Delete Restaurant?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let restaurant = restaurantToDelete {
                        store.delete(restaurant)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(restaurantToDelete?.name ?? "this restaurant")?")
            }
            .sheet(isPresented: $showEditor) {
                RestaurantEditor(restaurants: $store.restaurants, editingRestaurant: editorRestaurant)
            }
        }
    }
}
