//
//  ToolType.swift
//  psst
//
//  Created by Taraaf Khalidi on 28/12/2025.
//

import Foundation

enum ToolType: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case pencil = "Pencil"
    case marker = "Marker"
    case eraser = "Eraser"
    
    var id: String { rawValue }
}
