//
//  EmptyStateView.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI 

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary.opacity(0.3))
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
