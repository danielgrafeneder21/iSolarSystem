//
//  InfoPanelOrnament.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import SwiftUI

/// Info Panel window displaying detailed planet information
struct InfoPanelOrnament: View {
    let planetData: PlanetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Planet name as title
            Text(planetData.name)
                .font(.title2)
                .bold()
            
            // Type badge with capsule background
            Text(planetData.type)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.3))
                .clipShape(Capsule())
            
            Divider()
            
            // Attribute rows - categories
            InfoRow(label: "Size", value: planetData.radiusCategory)
            InfoRow(label: "Distance", value: planetData.distanceCategory)
            InfoRow(label: "Orbit Speed", value: planetData.orbitalPeriodCategory)
            
            Divider()
            
            // Attribute rows - detailed information
            InfoRow(label: "Rotation Period", value: planetData.rotationPeriod)
            InfoRow(label: "Orbital Period", value: planetData.orbitalPeriod)
            InfoRow(label: "Diameter", value: planetData.diameter)
            InfoRow(label: "Distance from Sun", value: planetData.distanceFromSun)
            
            Divider()
            
            // Interesting fact section with different styling
            VStack(alignment: .leading, spacing: 6) {
                Text("Did You Know?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .bold()
                Text(planetData.interestingFact)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .italic()
            }
        }
        .padding(20)
        .glassBackgroundEffect()
    }
}

/// Helper view for displaying attribute label-value pairs
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}

#Preview {
    InfoPanelOrnament(planetData: PlanetData(
        id: UUID(),
        name: "Earth",
        type: "Terrestrial",
        radiusCategory: "Medium",
        distanceCategory: "Inner",
        orbitalPeriodCategory: "Moderate",
        rotationPeriod: "24 hours",
        orbitalPeriod: "365.25 days",
        diameter: "12,742 km",
        distanceFromSun: "149.6 million km",
        interestingFact: "Earth is the only known planet to support life and has liquid water on its surface."
    ))
}
