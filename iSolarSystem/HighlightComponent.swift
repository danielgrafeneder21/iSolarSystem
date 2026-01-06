//
//  HighlightComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit

/// Component that manages smooth highlight animation for visual feedback
struct HighlightComponent: Component {
    /// Target highlight intensity (0.0 to 1.0)
    var targetIntensity: Float
    
    /// Current highlight intensity (animated toward target)
    var currentIntensity: Float
    
    /// Animation speed for intensity interpolation
    var animationSpeed: Float
    
    /// Initializes a HighlightComponent with specified parameters
    /// - Parameters:
    ///   - targetIntensity: Target highlight intensity (default: 0.0)
    ///   - currentIntensity: Current highlight intensity (default: 0.0)
    ///   - animationSpeed: Animation speed for intensity interpolation (default: 5.0)
    init(targetIntensity: Float = 0.0, currentIntensity: Float = 0.0, animationSpeed: Float = 5.0) {
        self.targetIntensity = targetIntensity
        self.currentIntensity = currentIntensity
        self.animationSpeed = animationSpeed
    }
}
