//
//  ComponentTestView.swift
//  iSolarSystem
//
//  Created by Kiro AI - Component Testing
//

import SwiftUI
import RealityKit

/// A test view that demonstrates all ECS components working together
struct ComponentTestView: View {
    var body: some View {
        RealityView { content in
            // Create a test solar system with the Sun and a few planets
            await setupTestSolarSystem(content: content)
        }
    }
    
    private func setupTestSolarSystem(content: RealityViewContent) async {
        // Create the Sun at the center
        let sun = createSun()
        content.add(sun)
        
        // Create test planets with different components
        let mercury = createPlanet(
            name: "Mercury",
            radius: 0.05,
            orbitRadius: 0.5,
            orbitSpeed: 2.0,
            color: .gray,
            type: .terrestrial
        )
        content.add(mercury)
        
        let earth = createPlanet(
            name: "Earth",
            radius: 0.08,
            orbitRadius: 1.0,
            orbitSpeed: 1.0,
            color: .blue,
            type: .terrestrial
        )
        content.add(earth)
        
        let jupiter = createPlanet(
            name: "Jupiter",
            radius: 0.15,
            orbitRadius: 1.8,
            orbitSpeed: 0.5,
            color: .orange,
            type: .gasGiant
        )
        content.add(jupiter)
        
        print("✅ Test solar system created with ECS components")
        print("📊 Components attached:")
        print("   - OrbitComponent: Controls orbital motion")
        print("   - SelectionComponent: Enables interaction")
        print("   - PlanetDataComponent: Stores educational data")
        print("   - HighlightComponent: Manages visual feedback")
    }
    
    private func createSun() -> Entity {
        let sun = Entity()
        
        // Create a glowing sphere for the Sun
        let mesh = MeshResource.generateSphere(radius: 0.2)
        var material = UnlitMaterial(color: .yellow)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        
        let model = ModelComponent(mesh: mesh, materials: [material])
        sun.components.set(model)
        
        sun.name = "Sun"
        
        return sun
    }
    
    private func createPlanet(
        name: String,
        radius: Float,
        orbitRadius: Float,
        orbitSpeed: Float,
        color: UIColor,
        type: PlanetDataComponent.PlanetType
    ) -> Entity {
        let planet = Entity()
        
        // Create visual mesh
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, isMetallic: false)
        let model = ModelComponent(mesh: mesh, materials: [material])
        planet.components.set(model)
        
        // Add OrbitComponent - controls orbital motion
        let orbitComponent = OrbitComponent(
            radius: orbitRadius,
            speed: orbitSpeed,
            currentPhase: Float.random(in: 0...(2 * .pi)),
            inclination: Float.random(in: -0.1...0.1)
        )
        planet.components.set(orbitComponent)
        
        // Add SelectionComponent - enables interaction
        let selectionComponent = SelectionComponent(
            isSelected: false,
            isHovered: false,
            collisionRadius: radius * 1.5
        )
        planet.components.set(selectionComponent)
        
        // Add PlanetDataComponent - stores educational data
        let radiusCategory = radius < 0.07 ? "Small" : radius < 0.12 ? "Medium" : "Large"
        let distanceCategory = orbitRadius < 0.8 ? "Inner" : "Outer"
        let speedCategory = orbitSpeed > 1.5 ? "Fast" : orbitSpeed > 0.8 ? "Moderate" : "Slow"
        
        let planetData = PlanetDataComponent(
            name: name,
            type: type,
            radiusCategory: radiusCategory,
            distanceCategory: distanceCategory,
            orbitalPeriodCategory: speedCategory
        )
        planet.components.set(planetData)
        
        // Add HighlightComponent - manages visual feedback
        let highlightComponent = HighlightComponent(
            targetIntensity: 0.0,
            currentIntensity: 0.0,
            animationSpeed: 5.0
        )
        planet.components.set(highlightComponent)
        
        planet.name = name
        
        // Position planet at its initial orbit position
        let x = orbitRadius * cos(orbitComponent.currentPhase)
        let z = orbitRadius * sin(orbitComponent.currentPhase)
        planet.position = SIMD3(x: x, y: 0, z: z)
        
        // Log component data for verification
        print("🪐 Created \(name):")
        print("   Orbit: radius=\(orbitRadius)m, speed=\(orbitSpeed)rad/s")
        print("   Data: \(type.rawValue), \(radiusCategory), \(distanceCategory), \(speedCategory)")
        print("   Selection: collision radius=\(selectionComponent.collisionRadius)m")
        print("   Highlight: animation speed=\(highlightComponent.animationSpeed)")
        
        return planet
    }
}

#Preview(immersionStyle: .mixed) {
    ComponentTestView()
}
