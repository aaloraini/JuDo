//
//  JuDoWidgetBundle.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct JuDoWidgetBundle: WidgetBundle {
    var body: some Widget {
        JuDoWidget()
        if #available(macOS 26.0, *) {
            JuDoWidgetControl()
        }
    }
}
