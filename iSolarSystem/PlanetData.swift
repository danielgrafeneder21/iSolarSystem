//
//  PlanetData.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import Foundation

/// UI model representing planet information for display in Info Panel
struct PlanetData: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let radiusCategory: String
    let distanceCategory: String
    let orbitalPeriodCategory: String
    let rotationPeriod: String
    let orbitalPeriod: String
    let diameter: String
    let distanceFromSun: String
    let interestingFact: String
}
