//
//  JuDoWidgetExtensionBundle.swift
//  JuDoWidgetExtension
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct JuDoWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        JuDoWidgetExtension()
        JuDoWidgetExtensionControl()
    }
}
