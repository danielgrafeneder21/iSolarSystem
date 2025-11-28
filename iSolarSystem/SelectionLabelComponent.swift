//
//  SelectionLabelComponent.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit

/// Component that manages 3D floating labels for selected planets
struct SelectionLabelComponent: Component {
    /// Whether the label should be visible
    var isVisible: Bool
    
    /// The text to display in the label
    var labelText: String
    
    /// Vertical offset from the planet center (in meters)
    var verticalOffset: Float
    
    /// Initializes a SelectionLabelComponent
    /// - Parameters:
    ///   - isVisible: Whether the label should be visible (default: false)
    ///   - labelText: The text to display (default: empty string)
    ///   - verticalOffset: Vertical offset from planet center (default: 0.15m)
    init(isVisible: Bool = false, labelText: String = "", verticalOffset: Float = 0.15) {
        self.isVisible = isVisible
        self.labelText = labelText
        self.verticalOffset = verticalOffset
    }
}
