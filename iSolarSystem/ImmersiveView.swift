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
    @State private var handTrackingProvider = HandTrackingProvider()
    @State private var rootEntity: Entity?
    @State private var updateTimer: Timer?
    @State private var lastUpdateTime: Date = Date()

    var body: some View {
        RealityView { content in
                print("🚀 [ImmersiveView] RealityView content closure started")
                
                // Initialize systems
                let orbitSystem = OrbitSystem()
                let selectionSystem = SelectionSystem()
                let highlightSystem = HighlightSystem()
                
                print("✅ [ImmersiveView] Systems initialized: OrbitSystem, SelectionSystem, HighlightSystem")
                
                // Store system references in appModel
                appModel.orbitSystem = orbitSystem
                appModel.selectionSystem = selectionSystem
                appModel.highlightSystem = highlightSystem
                
                // Setup the solar system scene
                setupSolarSystem(content: content)
                
                // Store root entity reference for timer updates
                rootEntity = content.entities.first
                
                if let root = rootEntity {
                    print("✅ [ImmersiveView] Root entity stored: \(root.name)")
                } else {
                    print("⚠️ [ImmersiveView] Warning: Root entity is nil")
                }
                
                // Hand tracking is automatically available in visionOS
                // No explicit start needed for HandTrackingProvider
                
                // Start continuous update timer
                startUpdateTimer()
                print("✅ [ImmersiveView] Update timer started at 60 FPS")
            } update: { content in
                // This update closure is called when dependencies change
                // We use a timer for continuous updates instead
            }
            .onDisappear {
                // Stop timer when view disappears
                updateTimer?.invalidate()
                updateTimer = nil
                print("👋 [ImmersiveView] View disappeared, timer stopped")
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleEntityTap(value.entity)
                    }
            )
    }
    
    /// Generates an orbit line entity for visualizing a planet's orbital path
    /// - Parameters:
    ///   - radius: Orbital radius in meters
    ///   - inclination: Orbital plane tilt in radians
    ///   - lineWidth: Thickness of the line in meters (default: 0.002)
    ///   - lineColor: Color of the orbit line (default: white with 0.3 alpha)
    /// - Returns: Entity representing the orbit line
    private func generateOrbitLine(radius: Float, inclination: Float, lineWidth: Float = 0.002, lineColor: UIColor = UIColor(white: 1.0, alpha: 0.3)) -> Entity {
        let orbitLineEntity = Entity()
        
        // Number of points for smooth circle (128 points for high quality)
        let pointCount = 128
        let angleStep = (2.0 * Float.pi) / Float(pointCount)
        
        // Generate circular path points
        var positions: [SIMD3<Float>] = []
        for i in 0..<pointCount {
            let angle = Float(i) * angleStep
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            var position = SIMD3<Float>(x, 0, z)
            
            // Apply inclination rotation if non-zero
            if inclination != 0 {
                let inclinationRotation = simd_quatf(angle: inclination, axis: SIMD3<Float>(0, 0, 1))
                position = inclinationRotation.act(position)
            }
            
            positions.append(position)
        }
        
        // Create line segments using cylinder primitives
        for i in 0..<pointCount {
            let startPos = positions[i]
            let endPos = positions[(i + 1) % pointCount]
            
            // Calculate segment midpoint and length
            let midpoint = (startPos + endPos) / 2.0
            let segmentVector = endPos - startPos
            let segmentLength = simd_length(segmentVector)
            
            // Create cylinder for this segment
            let cylinderMesh = MeshResource.generateCylinder(height: segmentLength, radius: lineWidth / 2.0)
            
            // Create semi-transparent material
            var material = UnlitMaterial()
            material.color = .init(tint: lineColor)
            
            // Create segment entity
            let segmentEntity = Entity()
            segmentEntity.components[ModelComponent.self] = ModelComponent(
                mesh: cylinderMesh,
                materials: [material]
            )
            
            // Position at midpoint
            segmentEntity.position = midpoint
            
            // Orient cylinder along segment direction
            // Default cylinder is along Y-axis, we need to rotate it to align with segment
            let defaultDirection = SIMD3<Float>(0, 1, 0)
            let targetDirection = simd_normalize(segmentVector)
            
            // Calculate rotation quaternion to align cylinder with segment
            let rotationAxis = simd_cross(defaultDirection, targetDirection)
            let rotationAngle = acos(simd_dot(defaultDirection, targetDirection))
            
            if simd_length(rotationAxis) > 0.001 {
                let normalizedAxis = simd_normalize(rotationAxis)
                segmentEntity.orientation = simd_quatf(angle: rotationAngle, axis: normalizedAxis)
            }
            
            orbitLineEntity.addChild(segmentEntity)
        }
        
        return orbitLineEntity
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
    
    /// Creates a planet entity with all necessary components and its orbit line
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
    ///   - rotationPeriod: String describing the planet's rotation period
    ///   - orbitalPeriod: String describing the planet's orbital period
    ///   - diameter: String describing the planet's diameter
    ///   - distanceFromSun: String describing the planet's distance from the Sun
    ///   - interestingFact: Educational fact about the planet
    ///   - inclination: Orbital plane tilt in radians (default: 0)
    ///   - rotationSpeed: Rotation speed in radians per second around Y-axis (default: 1.0)
    ///   - initialPhase: Starting orbital angle in radians (default: 0)
    /// - Returns: Tuple containing the planet entity and its orbit line entity
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
        rotationPeriod: String,
        orbitalPeriod: String,
        diameter: String,
        distanceFromSun: String,
        interestingFact: String,
        inclination: Float = 0,
        rotationSpeed: Float = 1.0,
        initialPhase: Float = 0
    ) throws -> (planet: Entity, orbitLine: Entity) {
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
            currentPhase: initialPhase,
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
            orbitalPeriodCategory: orbitalPeriodCategory,
            rotationPeriod: rotationPeriod,
            orbitalPeriod: orbitalPeriod,
            diameter: diameter,
            distanceFromSun: distanceFromSun,
            interestingFact: interestingFact
        )
        
        // Attach HighlightComponent with default values
        planetEntity.components[HighlightComponent.self] = HighlightComponent()
        
        // Attach RotationComponent with provided rotation speed
        planetEntity.components[RotationComponent.self] = RotationComponent(
            rotationSpeed: rotationSpeed,
            currentRotation: 0
        )
        
        // Store original color for restoration after highlighting
        planetEntity.components[OriginalMaterialComponent.self] = OriginalMaterialComponent(originalColor: color)
        
        // Add collision shape for tap detection
        planetEntity.components[CollisionComponent.self] = CollisionComponent(
            shapes: [.generateSphere(radius: size / 2)],
            mode: .trigger,
            filter: .sensor
        )
        
        // Add input target component to make entity tappable
        planetEntity.components[InputTargetComponent.self] = InputTargetComponent()
        
        // Generate orbit line for this planet
        let orbitLineEntity = generateOrbitLine(radius: radius, inclination: inclination)
        orbitLineEntity.name = "\(name)_OrbitLine"
        
        // Attach OrbitLineComponent to orbit line entity
        orbitLineEntity.components[OrbitLineComponent.self] = OrbitLineComponent(
            isVisible: appModel.showOrbitLines,
            lineColor: UIColor(white: 1.0, alpha: 0.3),
            lineWidth: 0.002
        )
        
        // Set initial visibility based on AppModel.showOrbitLines
        orbitLineEntity.isEnabled = appModel.showOrbitLines
        
        return (planet: planetEntity, orbitLine: orbitLineEntity)
    }
    
    /// Calculates initial orbital phase for a planet based on a date
    /// - Parameters:
    ///   - date: The date to calculate the phase for (if nil, returns default phase)
    ///   - orbitalPeriodDays: The planet's orbital period in Earth days
    ///   - defaultPhase: The default phase to use if no date is provided
    /// - Returns: Initial phase in radians
    private func calculateInitialPhase(for date: Date?, orbitalPeriodDays: Double, defaultPhase: Float) -> Float {
        guard let date = date else {
            return defaultPhase
        }
        
        // Use J2000 epoch (January 1, 2000, 12:00 TT) as reference
        let j2000 = Date(timeIntervalSince1970: 946728000) // January 1, 2000, 12:00 UTC
        
        // Calculate days since J2000
        let daysSinceJ2000 = date.timeIntervalSince(j2000) / 86400.0
        
        // Calculate number of complete orbits
        let orbits = daysSinceJ2000 / orbitalPeriodDays
        
        // Get fractional part (current position in orbit)
        let fractionalOrbit = orbits.truncatingRemainder(dividingBy: 1.0)
        
        // Convert to radians (0 to 2π)
        let phase = Float(fractionalOrbit * 2.0 * .pi)
        
        return phase
    }
    
    /// Sets up the complete solar system scene with Sun and planets
    /// - Parameter content: RealityView content to add entities to
    private func setupSolarSystem<Content>(content: Content) where Content: RealityViewContentProtocol {
        do {
            print("🌌 [setupSolarSystem] Starting solar system scene creation")
            
            // Create root SolarSystemScene entity
            let solarSystemScene = Entity()
            solarSystemScene.name = "SolarSystemScene"
            
            // Position solar system for isometric viewing angle
            // Place 3.5 meters in front of user (negative Z in RealityKit) - moved back for better overview
            // Position at eye level (0.1 meters on Y-axis) - raised higher for comfortable viewing
            solarSystemScene.position = SIMD3<Float>(0, 0.1, -3.5)
            
            // Apply rotation to tilt the orbital plane for isometric perspective
            // Rotate 35 degrees around X-axis to tilt the plane toward the user
            let tiltAngle: Float = 35.0 * .pi / 180.0  // Convert degrees to radians
            let tiltRotation = simd_quatf(angle: tiltAngle, axis: SIMD3<Float>(1, 0, 0))
            solarSystemScene.orientation = tiltRotation
            
            // Create and add the Sun
            let sun = try createSunEntity()
            sun.name = "Sun"
            solarSystemScene.addChild(sun)
            print("☀️ [setupSolarSystem] Created Sun at position: \(sun.position)")
            
            // Create Mercury - Closest, fastest, smallest
            // Rotation: 58.6 Earth days per rotation = slow rotation
            // Initial phase: 45° (π/4 radians) default - positioned in first quadrant
            let mercuryPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 88.0,
                defaultPhase: .pi / 4
            )
            let (mercury, mercuryOrbitLine) = try createPlanetEntity(
                name: "Mercury",
                radius: 0.6,           // Slightly increased for better visibility
                speed: 0.175,          // Halved again for even slower base speed
                size: 0.055,           // Slightly larger for visibility
                type: .terrestrial,
                color: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
                radiusCategory: "Small",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Fast",
                rotationPeriod: "58.6 days",
                orbitalPeriod: "88 days",
                diameter: "4,879 km",
                distanceFromSun: "57.9 million km",
                interestingFact: "Mercury has the most extreme temperature variations of any planet, ranging from -173°C at night to 427°C during the day.",
                inclination: 0.03,     // Subtle tilt for variety
                rotationSpeed: 0.5 / 58.6,  // Scaled: Earth baseline (0.5) / 58.6 days
                initialPhase: mercuryPhase
            )
            mercury.name = "Mercury"
            solarSystemScene.addChild(mercury)
            solarSystemScene.addChild(mercuryOrbitLine)
            print("🪐 [setupSolarSystem] Created Mercury - radius: \(0.6)m, speed: \(0.175) rad/s, size: \(0.055)m")
            
            // Create Venus - Second planet, similar size to Earth
            // Rotation: 243 Earth days (retrograde - opposite direction)
            // Initial phase: 135° (3π/4 radians) default - positioned in second quadrant
            let venusPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 225.0,
                defaultPhase: 3 * .pi / 4
            )
            let (venus, venusOrbitLine) = try createPlanetEntity(
                name: "Venus",
                radius: 0.85,          // Better spacing from Mercury
                speed: 0.14,           // Halved again for even slower base speed
                size: 0.085,           // Slightly larger for differentiation
                type: .terrestrial,
                color: UIColor(red: 0.9, green: 0.8, blue: 0.5, alpha: 1.0),
                radiusCategory: "Medium",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Fast",
                rotationPeriod: "243 days (retrograde)",
                orbitalPeriod: "225 days",
                diameter: "12,104 km",
                distanceFromSun: "108.2 million km",
                interestingFact: "Venus rotates backwards compared to most planets and has the hottest surface temperature of any planet at 462°C.",
                inclination: 0.06,     // More noticeable tilt
                rotationSpeed: -0.5 / 243.0,  // Negative for retrograde rotation
                initialPhase: venusPhase
            )
            venus.name = "Venus"
            solarSystemScene.addChild(venus)
            solarSystemScene.addChild(venusOrbitLine)
            print("🪐 [setupSolarSystem] Created Venus - radius: \(0.85)m, speed: \(0.14) rad/s, size: \(0.085)m")
            
            // Create Earth - Reference planet with moderate values
            // Rotation: 24 hours = 1 day (baseline rotation speed)
            // Initial phase: 225° (5π/4 radians) default - positioned in third quadrant
            let earthPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 365.25,
                defaultPhase: 5 * .pi / 4
            )
            let (earth, earthOrbitLine) = try createPlanetEntity(
                name: "Earth",
                radius: 1.15,          // Increased spacing
                speed: 0.10,           // Halved again for even slower base speed
                size: 0.09,            // Clear visibility
                type: .terrestrial,
                color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
                radiusCategory: "Medium",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Moderate",
                rotationPeriod: "24 hours",
                orbitalPeriod: "365.25 days",
                diameter: "12,742 km",
                distanceFromSun: "149.6 million km",
                interestingFact: "Earth is the only known planet to support life and has liquid water covering 71% of its surface.",
                inclination: 0.12,     // Earth's actual tilt for realism
                rotationSpeed: 0.5,    // Baseline rotation speed (visible at 1× time scale)
                initialPhase: earthPhase
            )
            earth.name = "Earth"
            solarSystemScene.addChild(earth)
            solarSystemScene.addChild(earthOrbitLine)
            print("🪐 [setupSolarSystem] Created Earth - radius: \(1.15)m, speed: \(0.10) rad/s, size: \(0.09)m")
            
            // Create Mars - Smaller, reddish planet
            // Rotation: 24.6 hours (similar to Earth)
            // Initial phase: 315° (7π/4 radians) default - positioned in fourth quadrant
            let marsPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 687.0,
                defaultPhase: 7 * .pi / 4
            )
            let (mars, marsOrbitLine) = try createPlanetEntity(
                name: "Mars",
                radius: 1.5,           // Better spacing from Earth
                speed: 0.07,           // Halved again for even slower base speed
                size: 0.065,           // Smaller than Earth
                type: .terrestrial,
                color: UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1.0),
                radiusCategory: "Small",
                distanceCategory: "Inner",
                orbitalPeriodCategory: "Moderate",
                rotationPeriod: "24.6 hours",
                orbitalPeriod: "687 days",
                diameter: "6,779 km",
                distanceFromSun: "227.9 million km",
                interestingFact: "Mars has the largest volcano in the solar system, Olympus Mons, which is about 3 times the height of Mount Everest.",
                inclination: 0.08,     // Moderate tilt
                rotationSpeed: 0.5 * (24.0 / 24.6),  // Slightly slower than Earth
                initialPhase: marsPhase
            )
            mars.name = "Mars"
            solarSystemScene.addChild(mars)
            solarSystemScene.addChild(marsOrbitLine)
            print("🪐 [setupSolarSystem] Created Mars - radius: \(1.5)m, speed: \(0.07) rad/s, size: \(0.065)m")
            
            // Create Jupiter - Largest planet, outer orbit
            // Rotation: 9.9 hours (fast rotation)
            // Initial phase: 180° (π radians) default - positioned opposite to starting view
            let jupiterPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 4332.59,  // ~12 years
                defaultPhase: .pi
            )
            let (jupiter, jupiterOrbitLine) = try createPlanetEntity(
                name: "Jupiter",
                radius: 2.2,           // Significant gap to outer planets
                speed: 0.045,          // Halved again for even slower base speed
                size: 0.16,            // Clearly the largest
                type: .gasGiant,
                color: UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0),
                radiusCategory: "Large",
                distanceCategory: "Outer",
                orbitalPeriodCategory: "Slow",
                rotationPeriod: "9.9 hours",
                orbitalPeriod: "12 years",
                diameter: "139,820 km",
                distanceFromSun: "778.5 million km",
                interestingFact: "Jupiter is so massive that it could fit all the other planets inside it, and its Great Red Spot is a storm larger than Earth.",
                inclination: 0.04,     // Subtle tilt
                rotationSpeed: 0.5 * (24.0 / 9.9),  // Much faster than Earth
                initialPhase: jupiterPhase
            )
            jupiter.name = "Jupiter"
            solarSystemScene.addChild(jupiter)
            solarSystemScene.addChild(jupiterOrbitLine)
            print("🪐 [setupSolarSystem] Created Jupiter - radius: \(2.2)m, speed: \(0.045) rad/s, size: \(0.16)m")
            
            // Create Saturn - Second largest, outermost
            // Rotation: 10.7 hours (fast rotation)
            // Initial phase: 30° (π/6 radians) default - positioned for visual balance
            let saturnPhase = calculateInitialPhase(
                for: appModel.startDate,
                orbitalPeriodDays: 10759.22,  // ~29 years
                defaultPhase: .pi / 6
            )
            let (saturn, saturnOrbitLine) = try createPlanetEntity(
                name: "Saturn",
                radius: 2.8,           // Outermost orbit, good spacing
                speed: 0.0325,         // Halved again for even slower base speed
                size: 0.14,            // Large but smaller than Jupiter
                type: .gasGiant,
                color: UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0),
                radiusCategory: "Large",
                distanceCategory: "Outer",
                orbitalPeriodCategory: "Slow",
                rotationPeriod: "10.7 hours",
                orbitalPeriod: "29 years",
                diameter: "116,460 km",
                distanceFromSun: "1.43 billion km",
                interestingFact: "Saturn's iconic rings are made of billions of ice and rock particles, and the planet is light enough to float in water.",
                inclination: 0.18,     // Most tilted for visual interest
                rotationSpeed: 0.5 * (24.0 / 10.7),  // Fast rotation like Jupiter
                initialPhase: saturnPhase
            )
            saturn.name = "Saturn"
            solarSystemScene.addChild(saturn)
            solarSystemScene.addChild(saturnOrbitLine)
            print("🪐 [setupSolarSystem] Created Saturn - radius: \(2.8)m, speed: \(0.0325) rad/s, size: \(0.14)m")
            
            // Add the complete solar system scene to the RealityView content
            content.add(solarSystemScene)
            
            print("✅ [setupSolarSystem] Solar system scene loaded successfully")
            print("📊 [setupSolarSystem] Scene positioned at: \(solarSystemScene.position)")
            print("📊 [setupSolarSystem] Total planets created: 6 (Mercury, Venus, Earth, Mars, Jupiter, Saturn)")
        } catch {
            // Log error with descriptive message
            print("❌ [setupSolarSystem] Failed to create solar system scene: \(error.localizedDescription)")
            print("❌ [setupSolarSystem] Error details: \(error)")
            
            // Set error state in AppModel
            appModel.sceneLoadError = error
        }
    }
    
    /// Handles entity tap for fallback gaze-based selection
    /// - Parameter entity: The tapped entity
    private func handleEntityTap(_ entity: Entity) {
        print("👆 [handleEntityTap] Entity tapped: \(entity.name)")
        
        // Check if the tapped entity has a SelectionComponent
        guard var selectionComponent = entity.components[SelectionComponent.self] else {
            print("⚠️ [handleEntityTap] Entity '\(entity.name)' does not have SelectionComponent")
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
                orbitalPeriodCategory: planetDataComponent.orbitalPeriodCategory,
                rotationPeriod: planetDataComponent.rotationPeriod,
                orbitalPeriod: planetDataComponent.orbitalPeriod,
                diameter: planetDataComponent.diameter,
                distanceFromSun: planetDataComponent.distanceFromSun,
                interestingFact: planetDataComponent.interestingFact
            )
            print("✅ [handleEntityTap] Selected planet: \(planetDataComponent.name)")
            print("📋 [handleEntityTap] Planet info - Type: \(planetDataComponent.type.rawValue), Size: \(planetDataComponent.radiusCategory)")
        } else {
            print("⚠️ [handleEntityTap] Entity '\(entity.name)' does not have PlanetDataComponent")
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
        guard var modelComponent = entity.components[ModelComponent.self],
              let originalMaterial = entity.components[OriginalMaterialComponent.self] else {
            return
        }
        
        var materials = modelComponent.materials
        let isSelected = intensity > 0.5
        
        for i in 0..<materials.count {
            if materials[i] is SimpleMaterial {
                if intensity > 0.01 {
                    var newMaterial = SimpleMaterial()
                    
                    // Apply glow by blending original color with glow color
                    if isSelected {
                        // Bright cyan/blue glow for selected state - more intense
                        let glowColor = UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0)
                        let blendedColor = blendColors(originalMaterial.originalColor, glowColor, factor: intensity * 0.7)
                        newMaterial.color = .init(tint: blendedColor)
                    } else {
                        // Subtle white glow for hover state
                        let glowColor = UIColor(white: 1.0, alpha: 1.0)
                        let blendedColor = blendColors(originalMaterial.originalColor, glowColor, factor: intensity * 0.4)
                        newMaterial.color = .init(tint: blendedColor)
                    }
                    
                    materials[i] = newMaterial
                } else {
                    // No highlight, restore original color
                    var newMaterial = SimpleMaterial()
                    newMaterial.color = .init(tint: originalMaterial.originalColor)
                    materials[i] = newMaterial
                }
            }
        }
        
        // Apply pulsing scale effect for selected planets
        if isSelected {
            // Create pulsing animation by varying scale slightly
            let time = Float(Date().timeIntervalSince1970)
            let pulseAmount = sin(time * 3.0) * 0.03 + 1.08  // Pulse between 1.05 and 1.11
            entity.scale = SIMD3<Float>(repeating: pulseAmount)
        } else if intensity > 0.01 {
            // Subtle scale for hover
            entity.scale = SIMD3<Float>(repeating: 1.02)
        } else {
            // Return to normal scale
            entity.scale = SIMD3<Float>(repeating: 1.0)
        }
        
        modelComponent.materials = materials
        entity.components[ModelComponent.self] = modelComponent
        
        // Add selection ring for selected planets
        if isSelected {
            addSelectionRing(to: entity, intensity: intensity)
            addSelectionLabel(to: entity)
        } else {
            removeSelectionRing(from: entity)
            removeSelectionLabel(from: entity)
        }
    }
    
    /// Blends two UIColors together
    private func blendColors(_ color1: UIColor, _ color2: UIColor, factor: Float) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let f = CGFloat(factor)
        let r = r1 * (1 - f) + r2 * f
        let g = g1 * (1 - f) + g2 * f
        let b = b1 * (1 - f) + b2 * f
        let a = a1 * (1 - f) + a2 * f
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Adds a selection ring around the entity
    private func addSelectionRing(to entity: Entity, intensity: Float) {
        // Check if ring already exists
        let ringName = "SelectionRing"
        if entity.children.contains(where: { $0.name == ringName }) {
            // Update existing ring
            if let ring = entity.children.first(where: { $0.name == ringName }) {
                // Animate ring rotation
                let time = Float(Date().timeIntervalSince1970)
                ring.orientation = simd_quatf(angle: time * 2.0, axis: SIMD3<Float>(0, 1, 0))
            }
            return
        }
        
        // Get planet size from SelectionComponent
        guard let selectionComponent = entity.components[SelectionComponent.self] else {
            return
        }
        
        let planetRadius = selectionComponent.collisionRadius
        let ringRadius = planetRadius * 1.4  // Ring is 40% larger than planet
        let ringThickness: Float = 0.008
        
        // Create ring using multiple cylinders arranged in a circle
        // (generateTorus is not available in visionOS 1.0)
        let ringContainer = Entity()
        ringContainer.name = ringName
        
        let segmentCount = 32
        let angleStep = (2.0 * Float.pi) / Float(segmentCount)
        
        for i in 0..<segmentCount {
            let angle = Float(i) * angleStep
            let x = ringRadius * cos(angle)
            let z = ringRadius * sin(angle)
            
            let segmentMesh = MeshResource.generateBox(size: [ringThickness * 2, ringThickness, ringThickness * 2])
            var segmentMaterial = UnlitMaterial()
            segmentMaterial.color = .init(tint: UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 0.9))
            
            let segmentEntity = Entity()
            segmentEntity.components[ModelComponent.self] = ModelComponent(
                mesh: segmentMesh,
                materials: [segmentMaterial]
            )
            segmentEntity.position = SIMD3<Float>(x, 0, z)
            segmentEntity.orientation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
            
            ringContainer.addChild(segmentEntity)
        }
        
        // Tilt ring slightly for visual interest
        ringContainer.orientation = simd_quatf(angle: .pi / 6, axis: SIMD3<Float>(1, 0, 0))
        
        // Add ring as child of planet
        entity.addChild(ringContainer)
    }
    
    /// Removes the selection ring from the entity
    private func removeSelectionRing(from entity: Entity) {
        let ringName = "SelectionRing"
        if let ring = entity.children.first(where: { $0.name == ringName }) {
            ring.removeFromParent()
        }
    }
    
    /// Adds a floating 3D label above the entity
    private func addSelectionLabel(to entity: Entity) {
        // Check if label already exists
        let labelName = "SelectionLabel"
        if entity.children.contains(where: { $0.name == labelName }) {
            return
        }
        
        // Get planet name from PlanetDataComponent
        guard let planetData = entity.components[PlanetDataComponent.self],
              let selectionComponent = entity.components[SelectionComponent.self] else {
            return
        }
        
        // Create text mesh for the label
        let textMesh = MeshResource.generateText(
            planetData.name,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.08, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        // Create bright material for text
        var textMaterial = UnlitMaterial()
        textMaterial.color = .init(tint: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        
        // Create label entity
        let labelEntity = Entity()
        labelEntity.name = labelName
        labelEntity.components[ModelComponent.self] = ModelComponent(
            mesh: textMesh,
            materials: [textMaterial]
        )
        
        // Position label above the planet
        let planetRadius = selectionComponent.collisionRadius
        let labelOffset = planetRadius * 2.5  // Position well above the planet
        labelEntity.position = SIMD3<Float>(0, labelOffset, 0)
        
        // Make label always face the camera (billboard effect)
        labelEntity.components[BillboardComponent.self] = BillboardComponent()
        
        // Add label as child of planet
        entity.addChild(labelEntity)
    }
    
    /// Removes the selection label from the entity
    private func removeSelectionLabel(from entity: Entity) {
        let labelName = "SelectionLabel"
        if let label = entity.children.first(where: { $0.name == labelName }) {
            label.removeFromParent()
        }
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
    
    /// Gets all entities with RotationComponent
    private func getAllEntitiesWithRotation(from entity: Entity) -> [Entity] {
        var result: [Entity] = []
        
        if entity.components[RotationComponent.self] != nil {
            result.append(entity)
        }
        
        for child in entity.children {
            result.append(contentsOf: getAllEntitiesWithRotation(from: child))
        }
        
        return result
    }
    
    /// Gets all entities with OrbitLineComponent
    private func getAllEntitiesWithOrbitLine(from entity: Entity) -> [Entity] {
        var result: [Entity] = []
        
        if entity.components[OrbitLineComponent.self] != nil {
            result.append(entity)
        }
        
        for child in entity.children {
            result.append(contentsOf: getAllEntitiesWithOrbitLine(from: child))
        }
        
        return result
    }
    
    /// Updates orbit line visibility based on AppModel.showOrbitLines
    private func updateOrbitLineVisibility(rootEntity: Entity) {
        let shouldShow = appModel.showOrbitLines
        
        // Find all entities with OrbitLineComponent
        getAllEntitiesWithOrbitLine(from: rootEntity).forEach { entity in
            guard var orbitLineComponent = entity.components[OrbitLineComponent.self] else {
                return
            }
            
            // Update component visibility state
            orbitLineComponent.isVisible = shouldShow
            entity.components[OrbitLineComponent.self] = orbitLineComponent
            
            // Show/hide the entity
            entity.isEnabled = shouldShow
        }
    }
    
    /// Starts a timer for continuous updates
    private func startUpdateTimer() {
        // Stop any existing timer
        updateTimer?.invalidate()
        
        // Initialize last update time
        lastUpdateTime = Date()
        
        var frameCount = 0
        var lastLogTime = Date()
        
        // Create a timer that fires 60 times per second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [appModel, rootEntity, updateOrbitsWithDeltaTime, updateRotationsWithDeltaTime, updateSelection, updateHighlightsWithDeltaTime, updateOrbitLineVisibility] _ in
            Task { @MainActor in
                let currentTime = Date()
                let deltaTime = currentTime.timeIntervalSince(lastUpdateTime)
                lastUpdateTime = currentTime
                
                frameCount += 1
                
                // Update frame count in AppModel
                appModel.totalFrameCount += 1
                
                // Log frame rate every 5 seconds
                let timeSinceLastLog = currentTime.timeIntervalSince(lastLogTime)
                if timeSinceLastLog >= 5.0 {
                    let fps = Double(frameCount) / timeSinceLastLog
                    appModel.currentFPS = fps
                    print("📊 [UpdateLoop] Frame rate: \(String(format: "%.1f", fps)) FPS | Time scale: \(appModel.simulationTimeScale)× | Playing: \(appModel.isPlaying)")
                    frameCount = 0
                    lastLogTime = currentTime
                }
                
                // Update systems with calculated delta time
                guard let root = rootEntity else {
                    if frameCount == 1 {
                        print("⚠️ [UpdateLoop] Warning: Root entity is nil, cannot update systems")
                    }
                    return
                }
                
                // Update orbit positions
                updateOrbitsWithDeltaTime(root, deltaTime)
                
                // Update planet rotations
                updateRotationsWithDeltaTime(root, deltaTime)
                
                // Update selection and hover states
                updateSelection(root)
                
                // Update highlight effects
                updateHighlightsWithDeltaTime(root, deltaTime)
                
                // Update orbit line visibility
                updateOrbitLineVisibility(root)
            }
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
    
    /// Updates planet rotations with specific delta time
    private func updateRotationsWithDeltaTime(rootEntity: Entity, deltaTime: TimeInterval) {
        let timeScale = appModel.simulationTimeScale
        let deltaTimeFloat = Float(deltaTime)
        
        // Find all entities with RotationComponent
        getAllEntitiesWithRotation(from: rootEntity).forEach { entity in
            guard var rotationComponent = entity.components[RotationComponent.self] else {
                return
            }
            
            // Calculate rotation advancement: currentRotation += rotationSpeed × timeScale × deltaTime
            rotationComponent.currentRotation += rotationComponent.rotationSpeed * timeScale * deltaTimeFloat
            
            // Apply rotation to entity transform using quaternion rotation around Y-axis
            // This rotation is independent of orbital position
            let rotationQuaternion = simd_quatf(angle: rotationComponent.currentRotation, axis: SIMD3<Float>(0, 1, 0))
            entity.orientation = rotationQuaternion
            
            // Update the component
            entity.components[RotationComponent.self] = rotationComponent
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
