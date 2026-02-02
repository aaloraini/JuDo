//
//  Task.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Foundation

struct Task: Codable, Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
    
    init(title: String, order: Int) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.order = order
    }
}
