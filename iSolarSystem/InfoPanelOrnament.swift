//
//  InfoPanelOrnament.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import SwiftUI

/// Info Panel ornament displaying detailed planet information
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
            
            // Attribute rows
            InfoRow(label: "Size", value: planetData.radiusCategory)
            InfoRow(label: "Distance", value: planetData.distanceCategory)
            InfoRow(label: "Orbit Speed", value: planetData.orbitalPeriodCategory)
        }
        .padding()
        .frame(width: 250)
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
        orbitalPeriodCategory: "Moderate"
    ))
}
