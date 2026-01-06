//
//  SelectionComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit

/// Component that tracks selection and hover state for interactive entities
struct SelectionComponent: Component {
    /// Whether this entity is currently selected
    var isSelected: Bool
    
    /// Whether this entity is currently hovered (hand/gaze targeting it)
    var isHovered: Bool
    
    /// Collision radius for hit testing in meters
    var collisionRadius: Float
    
    /// Initializes a SelectionComponent with specified parameters
    /// - Parameters:
    ///   - isSelected: Whether the entity starts as selected (default: false)
    ///   - isHovered: Whether the entity starts as hovered (default: false)
    ///   - collisionRadius: Collision radius for hit testing in meters (default: 0.1)
    init(isSelected: Bool = false, isHovered: Bool = false, collisionRadius: Float = 0.1) {
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.collisionRadius = collisionRadius
    }
}
