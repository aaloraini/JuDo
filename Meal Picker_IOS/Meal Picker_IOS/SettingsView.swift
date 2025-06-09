//
//  SettingsView.swift
//  Meal Picker_IOS
//
//  Created by Abdulhakim Aloraini on 08/06/2025.
//

import SwiftUI  
struct SettingsView: View {
    @EnvironmentObject private var store: RestaurantStore
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset to Default Restaurants", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("This will remove all custom restaurants and restore the original list.")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Restaurants?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    store.resetToDefault()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all custom restaurants and restore the original list.")
            }
        }
    }
}
