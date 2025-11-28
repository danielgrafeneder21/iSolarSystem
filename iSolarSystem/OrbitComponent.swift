//
//  OrbitComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit

/// Component that defines orbital parameters for celestial bodies
struct OrbitComponent: Component {
    /// Distance from the Sun in meters (scene units)
    var radius: Float
    
    /// Angular velocity in radians per second at 1× time scale
    var speed: Float
    
    /// Current angle in radians (0 = positive X axis)
    var currentPhase: Float
    
    /// Orbital plane tilt in radians (for visual variety)
    var inclination: Float
    
    /// Initializes an OrbitComponent with specified parameters
    /// - Parameters:
    ///   - radius: Distance from the Sun in meters (default: 1.0)
    ///   - speed: Angular velocity in radians per second (default: 1.0)
    ///   - currentPhase: Starting angle in radians (default: 0.0)
    ///   - inclination: Orbital plane tilt in radians (default: 0.0)
    init(radius: Float = 1.0, speed: Float = 1.0, currentPhase: Float = 0.0, inclination: Float = 0.0) {
        self.radius = radius
        self.speed = speed
        self.currentPhase = currentPhase
        self.inclination = inclination
    }
}
