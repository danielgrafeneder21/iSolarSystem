//
//  ImmersiveView.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var useTestMode = false
    @State private var handTrackingProvider = HandTrackingProvider()
    @State private var rootEntity: Entity?
    @State private var updateTimer: Timer?
    @State private var lastUpdateTime: Date = Date()

    var body: some View {
        if useTestMode {
            ComponentTestView()
        } else {
            RealityView { content in
                // Initialize systems
                let orbitSystem = OrbitSystem()
                let selectionSystem = SelectionSystem()
                let highlightSystem = HighlightSystem()
                
                // Store system references in appModel
                appModel.orbitSystem = orbitSystem
                appModel.selectionSystem = selectionSystem
                appModel.highlightSystem = highlightSystem
                
                // Setup the solar system scene
                setupSolarSystem(content: content)
                
                // Store root entity reference for timer updates
                rootEntity = content.entities.first
                
                // Hand tracking is automatically available in visionOS
                // No explicit start needed for HandTrackingProvider
                
                // Start continuous update timer
                startUpdateTimer()
            } update: { content in
                // This update closure is called when dependencies change
                // We use a timer for continuous updates instead
            }
            .onDisappear {
                // Stop timer when view disappears
                updateTimer?.invalidate()
                updateTimer = nil
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleEntityTap(value.entity)
                    }
            )
            .ornament(attachmentAnchor: .scene(.bottom)) {
                TimeControlOrnament()
                    .environment(appModel)
            }
            .ornament(attachmentAnchor: .scene(.trailing)) {
                if let selectedPlanet = appModel.selectedPlanet {
                    InfoPanelOrnament(planetData: selectedPlanet)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    /// Creates the Sun entity at the center of the solar system
    /// - Returns: Entity representing the Sun with emissive material
    /// - Throws: Error if entity creation fails
    private func createSunEntity() throws -> Entity {
        let sunEntity = Entity()
        
        // Create sphere mesh for the Sun
        let sunMesh = MeshResource.generateSphere(radius: 0.15) // 0.3m diameter
        
        // Create emissive material with yellow/orange color
        var sunMaterial = UnlitMaterial()
        sunMaterial.color = .init(tint: .init(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0))
        
        // Add ModelComponent with the mesh and material
        sunEntity.components[ModelComponent.self] = ModelComponent(
            mesh: sunMesh,
            materials: [sunMaterial]
        )
        
        // Position at origin
        sunEntity.position = SIMD3<Float>(0, 0, 0)
        
        return sunEntity
    }
    
    /// Creates a planet entity with all necessary components
    /// - Parameters:
    ///   - name: The name of the planet
    ///   - radius: Orbital radius from the Sun in meters
    ///   - speed: Angular velocity in radians per second
    ///   - size: Physical size (diameter) of the planet in meters
    ///   - type: Planet type (terrestrial or gas giant)
    ///   - color: Color for the planet's material
    ///   - radiusCategory: Educational category for planet size
    ///   - distanceCategory: Educational category for distance from Sun
    ///   - orbitalPeriodCategory: Educational category for orbital speed
    ///   - inclination: Orbital plane tilt in radians (default: 0)
    /// - Returns: Entity representing the planet with all components attached
    /// - Throws: Error if entity creation fails
    private func createPlanetEntity(
        name: String,
        radius: Float,
        speed: Float,
        size: Float,
        type: PlanetDataComponent.PlanetType,
        color: UIColor,
        radiusCategory: String,
        distanceCategory: String,
        orbitalPeriodCategory: String,
        inclination: Float = 0
    ) throws -> Entity {
        let planetEntity = Entity()
        
        // Create sphere mesh for the planet
        let planetMesh = MeshResource.generateSphere(radius: size / 2)
        
        // Create material with the specified color
        var planetMaterial = SimpleMaterial()
        planetMaterial.color = .init(tint: color)
        
        // Add ModelComponent
        planetEntity.components[ModelComponent.self] = ModelComponent(
            mesh: planetMesh,
            materials: [planetMaterial]
        )
        
        // Attach OrbitComponent with provided parameters
        planetEntity.components[OrbitComponent.self] = OrbitComponent(
            radius: radius,
            speed: speed,
            currentPhase: 0,
            inclination: inclination
        )
        
        // Attach SelectionComponent with collision radius matching size
        planetEntity.components[SelectionComponent.self] = SelectionComponent(
            isSelected: false,
            isHovered: false,
            collisionRadius: size / 2
        )
        
        // Attach PlanetDataComponent with educational info
        planetEntity.components[PlanetDataComponent.self] = PlanetDataComponent(
            name: name,
            type: type,
            radiusCategory: radiusCategory,
            distanceCategory: distanceCategory,
            orbitalPeriodCategory: orbitalPeriodCategory
        )
        
        // Attach HighlightComponent with default values
        planetEntity.components[HighlightComponent.self] = HighlightComponent()
        
        return planetEntity
    }
    
    /// Sets up the complete solar system scene with Sun and planets
    /// - Parameter content: RealityView content to add entities to
    private func setupSolarSystem<Content>(content: Content) where Content: RealityViewContentProtocol {
        do {
            // Create root SolarSystemScene entity
            let solarSystemScene = Entity()
            solarSystemScene.name = "SolarSystemScene"
            
            // Create and add the Sun
            let sun = try createSunEntity()
            sun.name = "Sun"
            solarSystemScene.addChild(sun)
            
            // Create Mercury - Closest, fastest, smallest
            let mercury = try createPlanetEntity(
                name: "Mercury",
                radius: 0.6,           // Slightly increased for better visibility
                speed: 3.5,            // Adjusted for engaging motion
                size: 0.055,           // Slightly larger for visibility
                type: .terrestrial,
                color: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
                radiusCategory: "Small",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Fast",
                inclination: 0.03      // Subtle tilt for variety
            )
            mercury.name = "Mercury"
            solarSystemScene.addChild(mercury)
            
            // Create Venus - Second planet, similar size to Earth
            let venus = try createPlanetEntity(
                name: "Venus",
                radius: 0.85,          // Better spacing from Mercury
                speed: 2.8,            // Slower than Mercury
                size: 0.085,           // Slightly larger for differentiation
                type: .terrestrial,
                color: UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0),
                radiusCategory: "Medium",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Fast",
                inclination: 0.06      // More noticeable tilt
            )
            venus.name = "Venus"
            solarSystemScene.addChild(venus)
            
            // Create Earth - Reference planet with moderate values
            let earth = try createPlanetEntity(
                name: "Earth",
                radius: 1.15,          // Increased spacing
                speed: 2.0,            // Baseline speed
                size: 0.09,            // Clear visibility
                type: .terrestrial,
                color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
                radiusCategory: "Medium",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Moderate",
                inclination: 0.12      // Earth's actual tilt for realism
            )
            earth.name = "Earth"
            solarSystemScene.addChild(earth)
            
            // Create Mars - Smaller, reddish planet
            let mars = try createPlanetEntity(
                name: "Mars",
                radius: 1.5,           // Better spacing from Earth
                speed: 1.4,            // Noticeably slower
                size: 0.065,           // Smaller than Earth
                type: .terrestrial,
                color: UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0),
                radiusCategory: "Small",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Moderate",
                inclination: 0.08      // Moderate tilt
            )
            mars.name = "Mars"
            solarSystemScene.addChild(mars)
            
            // Create Jupiter - Largest planet, outer orbit
            let jupiter = try createPlanetEntity(
                name: "Jupiter",
                radius: 2.2,           // Significant gap to outer planets
                speed: 0.9,            // Slower outer planet
                size: 0.16,            // Clearly the largest
                type: .gasGiant,
                color: UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0),
                radiusCategory: "Large",
                distanceCategory: "Outer",
                orbitalPeriodCategory: "Slow",
                inclination: 0.04      // Subtle tilt
            )
            jupiter.name = "Jupiter"
            solarSystemScene.addChild(jupiter)
            
            // Create Saturn - Second largest, outermost
            let saturn = try createPlanetEntity(
                name: "Saturn",
                radius: 2.8,           // Outermost orbit, good spacing
                speed: 0.65,           // Slowest planet
                size: 0.14,            // Large but smaller than Jupiter
                type: .gasGiant,
                color: UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0),
                radiusCategory: "Large",
                distanceCategory: "Outer",
                orbitalPeriodCategory: "Slow",
                inclination: 0.18      // Most tilted for visual interest
            )
            saturn.name = "Saturn"
            solarSystemScene.addChild(saturn)
            
            // Add the complete solar system scene to the RealityView content
            content.add(solarSystemScene)
            
            print("Solar system scene loaded successfully")
        } catch {
            // Log error with descriptive message
            print("Failed to create solar system scene: \(error.localizedDescription)")
            
            // Set error state in AppModel
            appModel.sceneLoadError = error
        }
    }
    
    /// Handles entity tap for fallback gaze-based selection
    /// - Parameter entity: The tapped entity
    private func handleEntityTap(_ entity: Entity) {
        // Check if the tapped entity has a SelectionComponent
        guard var selectionComponent = entity.components[SelectionComponent.self] else {
            return
        }
        
        // Get all entities with SelectionComponent to clear other selections
        // We need to traverse the entity hierarchy to find all selectable entities
        // Start from the root entity (parent hierarchy)
        var rootEntity = entity
        while let parent = rootEntity.parent {
            rootEntity = parent
        }
        
        let allEntities = getAllSelectableEntities(from: rootEntity)
        
        // Clear selection on all other entities (single selection model)
        for otherEntity in allEntities where otherEntity != entity {
            if var otherSelection = otherEntity.components[SelectionComponent.self] {
                otherSelection.isSelected = false
                otherEntity.components[SelectionComponent.self] = otherSelection
            }
        }
        
        // Set the tapped entity as selected
        selectionComponent.isSelected = true
        entity.components[SelectionComponent.self] = selectionComponent
        
        // Update appModel.selectedPlanet with entity's PlanetDataComponent
        if let planetDataComponent = entity.components[PlanetDataComponent.self] {
            appModel.selectedPlanet = PlanetData(
                id: UUID(),
                name: planetDataComponent.name,
                type: planetDataComponent.type.rawValue,
                radiusCategory: planetDataComponent.radiusCategory,
                distanceCategory: planetDataComponent.distanceCategory,
                orbitalPeriodCategory: planetDataComponent.orbitalPeriodCategory
            )
        }
    }
    
    /// Recursively gets all entities with SelectionComponent from the scene
    /// - Parameter entity: Root entity to start search from
    /// - Returns: Array of entities with SelectionComponent
    private func getAllSelectableEntities(from entity: Entity) -> [Entity] {
        var result: [Entity] = []
        
        // Check if this entity has SelectionComponent
        if entity.components[SelectionComponent.self] != nil {
            result.append(entity)
        }
        
        // Recursively check children
        for child in entity.children {
            result.append(contentsOf: getAllSelectableEntities(from: child))
        }
        
        return result
    }
    
    /// Updates all systems each frame
    /// - Parameter content: RealityView content
    private func updateSystems<Content>(content: Content) where Content: RealityViewContentProtocol {
        // Get the root entity (solar system scene)
        guard let rootEntity = content.entities.first else {
            return
        }
        
        // Estimated delta time (assuming 60 FPS)
        let deltaTime: TimeInterval = 1.0 / 60.0
        
        // Update orbit positions
        updateOrbits(rootEntity: rootEntity, deltaTime: deltaTime)
        
        // Update selection and hover states
        updateSelection(rootEntity: rootEntity)
        
        // Update highlight effects
        updateHighlights(rootEntity: rootEntity, deltaTime: deltaTime)
    }
    
    /// Updates orbital positions for all planets
    private func updateOrbits(rootEntity: Entity, deltaTime: TimeInterval) {
        let timeScale = appModel.simulationTimeScale
        let deltaTimeFloat = Float(deltaTime)
        
        // Find all entities with OrbitComponent
        getAllEntitiesWithOrbit(from: rootEntity).forEach { entity in
            guard var orbitComponent = entity.components[OrbitComponent.self] else {
                return
            }
            
            // Calculate phase advancement
            orbitComponent.currentPhase += orbitComponent.speed * timeScale * deltaTimeFloat
            
            // Calculate position using circular orbit
            let x = orbitComponent.radius * cos(orbitComponent.currentPhase)
            let z = orbitComponent.radius * sin(orbitComponent.currentPhase)
            var position = SIMD3<Float>(x, 0, z)
            
            // Apply inclination rotation if non-zero
            if orbitComponent.inclination != 0 {
                let inclinationRotation = simd_quatf(angle: orbitComponent.inclination, axis: SIMD3<Float>(0, 0, 1))
                position = inclinationRotation.act(position)
            }
            
            // Update entity position
            entity.position = position
            
            // Update the component
            entity.components[OrbitComponent.self] = orbitComponent
        }
    }
    
    /// Updates selection and hover states
    private func updateSelection(rootEntity: Entity) {
        // For now, selection is handled by tap gesture
        // Hand tracking selection would be implemented here
    }
    
    /// Updates highlight visual effects
    private func updateHighlights(rootEntity: Entity, deltaTime: TimeInterval) {
        let deltaTimeFloat = Float(deltaTime)
        
        // Find all entities with HighlightComponent and SelectionComponent
        getAllEntitiesWithHighlight(from: rootEntity).forEach { entity in
            guard var highlightComponent = entity.components[HighlightComponent.self],
                  let selectionComponent = entity.components[SelectionComponent.self] else {
                return
            }
            
            // Set target intensity based on selection state
            if selectionComponent.isSelected {
                highlightComponent.targetIntensity = 1.0
            } else if selectionComponent.isHovered {
                highlightComponent.targetIntensity = 0.25
            } else {
                highlightComponent.targetIntensity = 0.0
            }
            
            // Interpolate current intensity toward target
            let intensityDelta = highlightComponent.targetIntensity - highlightComponent.currentIntensity
            highlightComponent.currentIntensity += intensityDelta * highlightComponent.animationSpeed * deltaTimeFloat
            highlightComponent.currentIntensity = max(0.0, min(1.0, highlightComponent.currentIntensity))
            
            // Update the component
            entity.components[HighlightComponent.self] = highlightComponent
            
            // Apply visual effect
            applyHighlightVisual(to: entity, intensity: highlightComponent.currentIntensity)
        }
    }
    
    /// Applies highlight visual effect to entity
    private func applyHighlightVisual(to entity: Entity, intensity: Float) {
        guard var modelComponent = entity.components[ModelComponent.self] else {
            return
        }
        
        var materials = modelComponent.materials
        
        for i in 0..<materials.count {
            if let simpleMaterial = materials[i] as? SimpleMaterial {
                let isSelected = intensity > 0.5
                
                if intensity > 0.01 {
                    var newMaterial = SimpleMaterial()
                    
                    // Apply glow by changing the tint color
                    if isSelected {
                        // Bright cyan/blue glow for selected state
                        let glowUIColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
                        newMaterial.color = .init(tint: glowUIColor)
                    } else {
                        // Subtle white glow for hover state
                        let glowUIColor = UIColor(white: 1.0, alpha: 1.0)
                        newMaterial.color = .init(tint: glowUIColor)
                    }
                    
                    materials[i] = newMaterial
                } else {
                    // No highlight, restore original color
                    var newMaterial = SimpleMaterial()
                    newMaterial.color = simpleMaterial.color
                    materials[i] = newMaterial
                }
            }
        }
        
        // Apply scale effect for selected planets
        if intensity > 0.5 {
            let baseScale = entity.scale
            let targetScale = SIMD3<Float>(repeating: 1.05)
            let mixFactor = SIMD3<Float>(repeating: intensity)
            entity.scale = simd_mix(baseScale, targetScale, mixFactor)
        } else {
            entity.scale = SIMD3<Float>(repeating: 1.0)
        }
        
        modelComponent.materials = materials
        entity.components[ModelComponent.self] = modelComponent
    }
    
    /// Gets all entities with OrbitComponent
    private func getAllEntitiesWithOrbit(from entity: Entity) -> [Entity] {
        var result: [Entity] = []
        
        if entity.components[OrbitComponent.self] != nil {
            result.append(entity)
        }
        
        for child in entity.children {
            result.append(contentsOf: getAllEntitiesWithOrbit(from: child))
        }
        
        return result
    }
    
    /// Gets all entities with HighlightComponent
    private func getAllEntitiesWithHighlight(from entity: Entity) -> [Entity] {
        var result: [Entity] = []
        
        if entity.components[HighlightComponent.self] != nil {
            result.append(entity)
        }
        
        for child in entity.children {
            result.append(contentsOf: getAllEntitiesWithHighlight(from: child))
        }
        
        return result
    }
    
    /// Starts a timer for continuous updates
    private func startUpdateTimer() {
        // Stop any existing timer
        updateTimer?.invalidate()
        
        // Initialize last update time
        lastUpdateTime = Date()
        
        // Create a timer that fires 60 times per second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            let currentTime = Date()
            let deltaTime = currentTime.timeIntervalSince(lastUpdateTime)
            lastUpdateTime = currentTime
            
            // Update systems with calculated delta time
            guard let root = rootEntity else { return }
            
            // Update orbit positions
            updateOrbitsWithDeltaTime(rootEntity: root, deltaTime: deltaTime)
            
            // Update selection and hover states
            updateSelection(rootEntity: root)
            
            // Update highlight effects
            updateHighlightsWithDeltaTime(rootEntity: root, deltaTime: deltaTime)
        }
    }
    
    /// Updates orbital positions with specific delta time
    private func updateOrbitsWithDeltaTime(rootEntity: Entity, deltaTime: TimeInterval) {
        let timeScale = appModel.simulationTimeScale
        let deltaTimeFloat = Float(deltaTime)
        
        // Find all entities with OrbitComponent
        getAllEntitiesWithOrbit(from: rootEntity).forEach { entity in
            guard var orbitComponent = entity.components[OrbitComponent.self] else {
                return
            }
            
            // Calculate phase advancement
            orbitComponent.currentPhase += orbitComponent.speed * timeScale * deltaTimeFloat
            
            // Calculate position using circular orbit
            let x = orbitComponent.radius * cos(orbitComponent.currentPhase)
            let z = orbitComponent.radius * sin(orbitComponent.currentPhase)
            var position = SIMD3<Float>(x, 0, z)
            
            // Apply inclination rotation if non-zero
            if orbitComponent.inclination != 0 {
                let inclinationRotation = simd_quatf(angle: orbitComponent.inclination, axis: SIMD3<Float>(0, 0, 1))
                position = inclinationRotation.act(position)
            }
            
            // Update entity position
            entity.position = position
            
            // Update the component
            entity.components[OrbitComponent.self] = orbitComponent
        }
    }
    
    /// Updates highlight effects with specific delta time
    private func updateHighlightsWithDeltaTime(rootEntity: Entity, deltaTime: TimeInterval) {
        let deltaTimeFloat = Float(deltaTime)
        
        // Find all entities with HighlightComponent and SelectionComponent
        getAllEntitiesWithHighlight(from: rootEntity).forEach { entity in
            guard var highlightComponent = entity.components[HighlightComponent.self],
                  let selectionComponent = entity.components[SelectionComponent.self] else {
                return
            }
            
            // Set target intensity based on selection state
            if selectionComponent.isSelected {
                highlightComponent.targetIntensity = 1.0
            } else if selectionComponent.isHovered {
                highlightComponent.targetIntensity = 0.25
            } else {
                highlightComponent.targetIntensity = 0.0
            }
            
            // Interpolate current intensity toward target
            let intensityDelta = highlightComponent.targetIntensity - highlightComponent.currentIntensity
            highlightComponent.currentIntensity += intensityDelta * highlightComponent.animationSpeed * deltaTimeFloat
            highlightComponent.currentIntensity = max(0.0, min(1.0, highlightComponent.currentIntensity))
            
            // Update the component
            entity.components[HighlightComponent.self] = highlightComponent
            
            // Apply visual effect
            applyHighlightVisual(to: entity, intensity: highlightComponent.currentIntensity)
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
