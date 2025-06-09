//
//  RestaurantRow.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI
struct RestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title)
                .foregroundColor(AppColors.primary)
            
            VStack(alignment: .leading) {
                Text(restaurant.name)
                    .font(.headline)
                
                Text("\(restaurant.itemCount) menu items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if restaurant.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
            }
        }
        .padding(.vertical, 8)
    }
}
