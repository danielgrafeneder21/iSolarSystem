//
//  RotationComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit

/// Component that defines rotation parameters for celestial bodies
struct RotationComponent: Component {
    /// Rotation speed in radians per second around Y-axis at 1× time scale
    var rotationSpeed: Float
    
    /// Current rotation angle in radians around Y-axis
    var currentRotation: Float
    
    /// Initializes a RotationComponent with specified parameters
    /// - Parameters:
    ///   - rotationSpeed: Rotation speed in radians per second (default: 1.0)
    ///   - currentRotation: Starting rotation angle in radians (default: 0.0)
    init(rotationSpeed: Float = 1.0, currentRotation: Float = 0.0) {
        self.rotationSpeed = rotationSpeed
        self.currentRotation = currentRotation
    }
}
