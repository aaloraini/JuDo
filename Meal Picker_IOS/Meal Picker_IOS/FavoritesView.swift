//
//  FavoritesView.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var store: RestaurantStore
    
    var favoriteRestaurants: [Restaurant] {
        store.restaurants.filter { $0.isFavorite }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoriteRestaurants.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "No Favorites",
                        message: "Mark restaurants as favorites to see them here"
                    )
                } else {
                    List {
                        ForEach(favoriteRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantRow(restaurant: restaurant)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    store.toggleFavorite(restaurant)
                                } label: {
                                    Label("Remove", systemImage: "heart.slash")
                                }
                                .tint(.pink)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
