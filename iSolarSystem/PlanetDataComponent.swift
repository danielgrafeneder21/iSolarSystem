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
    
    /// String describing the planet's rotation period (e.g., "24 hours", "58.6 days")
    var rotationPeriod: String
    
    /// String describing the planet's orbital period (e.g., "365.25 days", "12 years")
    var orbitalPeriod: String
    
    /// String describing the planet's diameter (e.g., "12,742 km")
    var diameter: String
    
    /// String describing the planet's distance from the Sun (e.g., "149.6 million km")
    var distanceFromSun: String
    
    /// Educational fact about the planet
    var interestingFact: String
    
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
    ///   - rotationPeriod: String describing the planet's rotation period
    ///   - orbitalPeriod: String describing the planet's orbital period
    ///   - diameter: String describing the planet's diameter
    ///   - distanceFromSun: String describing the planet's distance from the Sun
    ///   - interestingFact: Educational fact about the planet
    init(name: String, type: PlanetType, radiusCategory: String, distanceCategory: String, orbitalPeriodCategory: String, rotationPeriod: String, orbitalPeriod: String, diameter: String, distanceFromSun: String, interestingFact: String) {
        self.name = name
        self.type = type
        self.radiusCategory = radiusCategory
        self.distanceCategory = distanceCategory
        self.orbitalPeriodCategory = orbitalPeriodCategory
        self.rotationPeriod = rotationPeriod
        self.orbitalPeriod = orbitalPeriod
        self.diameter = diameter
        self.distanceFromSun = distanceFromSun
        self.interestingFact = interestingFact
    }
}
