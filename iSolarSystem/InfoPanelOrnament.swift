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
    @Environment(AppModel.self) private var appModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section with planet name and icon
            HStack(spacing: 12) {
                // Planet icon/thumbnail placeholder
                Circle()
                    .fill(planetTypeColor(for: planetData.type))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: planetIcon(for: planetData.type))
                            .font(.title3)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: planetTypeColor(for: planetData.type).opacity(0.5), radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Planet name as title
                    Text(planetData.name)
                        .font(.title2)
                        .bold()
                    
                    // Type badge with capsule background
                    Text(planetData.type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(planetTypeColor(for: planetData.type).opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Quick facts section
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Quick Facts", icon: "info.circle.fill")
                
                InfoRow(label: "Size", value: planetData.radiusCategory, icon: "circle.fill")
                InfoRow(label: "Distance", value: planetData.distanceCategory, icon: "arrow.left.and.right")
                InfoRow(label: "Orbit Speed", value: planetData.orbitalPeriodCategory, icon: "speedometer")
            }
            
            Divider()
            
            // Detailed information section
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Details", icon: "chart.bar.fill")
                
                InfoRow(label: "Rotation Period", value: planetData.rotationPeriod, icon: "arrow.clockwise")
                InfoRow(label: "Orbital Period", value: planetData.orbitalPeriod, icon: "arrow.triangle.2.circlepath")
                InfoRow(label: "Diameter", value: planetData.diameter, icon: "ruler")
                InfoRow(label: "Distance from Sun", value: planetData.distanceFromSun, icon: "sun.max")
            }
            
            Divider()
            
            // Interesting fact section with different styling
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Did You Know?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .bold()
                }
                
                Text(planetData.interestingFact)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .italic()
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(.yellow.opacity(0.1))
            .cornerRadius(8)
            
        }
        .padding(22)
        .frame(width: 320)
        .frame(minHeight: 600)
        .glassBackgroundEffect()
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .onChange(of: planetData.id) { _, _ in
            // Animate transition when planet changes
            isAnimating = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
    
    /// Returns the color associated with a planet type
    private func planetTypeColor(for type: String) -> Color {
        switch type {
        case "Terrestrial":
            return .blue
        case "Gas Giant":
            return .orange
        default:
            return .gray
        }
    }
    
    /// Returns the icon associated with a planet type
    private func planetIcon(for type: String) -> String {
        switch type {
        case "Terrestrial":
            return "globe"
        case "Gas Giant":
            return "cloud.fill"
        default:
            return "circle.fill"
        }
    }
}

/// Section header view for organizing information
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .bold()
                .textCase(.uppercase)
        }
    }
}

/// Helper view for displaying attribute label-value pairs
struct InfoRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(.primary)
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
