//
//  PlanetDataComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit

/// Component that stores educational data about a planet
struct PlanetDataComponent: Component {
    /// The name of the planet
    var name: String
    
    /// The type of planet (terrestrial or gas giant)
    var type: PlanetType
    
    /// Category describing the planet's size (e.g., "Small", "Medium", "Large")
    var radiusCategory: String
    
    /// Category describing the planet's distance from the Sun (e.g., "Inner", "Outer")
    var distanceCategory: String
    
    /// Category describing the planet's orbital speed (e.g., "Fast", "Moderate", "Slow")
    var orbitalPeriodCategory: String
    
    /// Enum representing the type of planet
    enum PlanetType: String {
        case terrestrial = "Terrestrial"
        case gasGiant = "Gas Giant"
    }
    
    /// Initializes a PlanetDataComponent with specified parameters
    /// - Parameters:
    ///   - name: The name of the planet
    ///   - type: The type of planet
    ///   - radiusCategory: Category describing the planet's size
    ///   - distanceCategory: Category describing the planet's distance from the Sun
    ///   - orbitalPeriodCategory: Category describing the planet's orbital speed
    init(name: String, type: PlanetType, radiusCategory: String, distanceCategory: String, orbitalPeriodCategory: String) {
        self.name = name
        self.type = type
        self.radiusCategory = radiusCategory
        self.distanceCategory = distanceCategory
        self.orbitalPeriodCategory = orbitalPeriodCategory
    }
}
