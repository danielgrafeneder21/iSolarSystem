//
//  SelectionSystem.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit
import ARKit
import simd

/// System responsible for handling hand tracking interactions and planet selection
class SelectionSystem {
    
    // MARK: - Properties
    
    /// Threshold distance for pinch detection (in meters)
    private let pinchThreshold: Float = 0.03
    
    /// Previous pinch state to detect pinch activation
    private var wasPinching = false
    
    // MARK: - Update Method
    
    /// Updates selection and hover states for all entities with SelectionComponent
    /// - Parameters:
    ///   - context: Scene update context
    ///   - appModel: Application model for updating selected planet
    ///   - handTrackingProvider: Optional hand tracking provider for hand-based input
    func update(context: SceneUpdateContext, appModel: AppModel, handTrackingProvider: HandTrackingProvider?) {
        // Query all entities with SelectionComponent
        let queryResult = context.scene.performQuery(Self.selectionQuery)
        let entities = Array(queryResult)
        
        // Get ray for hit testing (hand tracking or gaze-based fallback)
        guard let ray = getRay(from: handTrackingProvider, context: context) else {
            // No valid ray available, clear all hover states
            clearHoverStates(entities: entities)
            return
        }
        
        // Perform hit testing and update hover states
        updateHoverStates(entities: entities, ray: ray)
        
        // Handle pinch gesture detection and selection
        handlePinchGesture(entities: entities, handTrackingProvider: handTrackingProvider, appModel: appModel)
    }
    
    // MARK: - Ray Casting
    
    /// Gets a ray for hit testing from hand tracking or camera
    /// - Parameters:
    ///   - handTrackingProvider: Optional hand tracking provider
    ///   - context: Scene update context
    /// - Returns: Ray with origin and direction, or nil if unavailable
    private func getRay(from handTrackingProvider: HandTrackingProvider?, context: SceneUpdateContext) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        // Try to get hand tracking ray first
        if let handRay = getHandTrackingRay(from: handTrackingProvider) {
            return handRay
        }
        
        // Fallback to gaze-based ray from camera
        return getGazeRay(from: context)
    }
    
    /// Gets ray from hand tracking (index finger pointing direction)
    /// - Parameter handTrackingProvider: Hand tracking provider
    /// - Returns: Ray from hand, or nil if hand tracking unavailable
    private func getHandTrackingRay(from handTrackingProvider: HandTrackingProvider?) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        guard handTrackingProvider != nil else {
            return nil
        }
        
        // Try to get the right hand (primary pointing hand)
        // Note: In a real implementation, we would iterate through handAnchors
        // For now, we'll return nil to use gaze fallback
        // This will be properly implemented when hand tracking is fully integrated
        
        return nil
    }
    
    /// Gets ray from camera (gaze-based)
    /// - Parameter context: Scene update context
    /// - Returns: Ray from camera forward direction
    private func getGazeRay(from context: SceneUpdateContext) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
        // Get camera transform from the scene
        // In visionOS, the camera is typically at the origin looking forward
        // We'll use a default forward ray for gaze-based selection
        let origin = SIMD3<Float>(0, 0, 0)
        let direction = SIMD3<Float>(0, 0, -1) // Forward direction
        
        return (origin, direction)
    }
    
    // MARK: - Hit Testing
    
    /// Updates hover states based on ray-sphere intersection tests
    /// - Parameters:
    ///   - entities: Entities to test
    ///   - ray: Ray for hit testing
    private func updateHoverStates(entities: [Entity], ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        var closestEntity: Entity? = nil
        var closestDistance: Float = .infinity
        
        // Test each entity for intersection
        for entity in entities {
            guard let selectionComponent = entity.components[SelectionComponent.self] else {
                continue
            }
            
            // Perform ray-sphere intersection test
            if let distance = raySphereIntersection(
                rayOrigin: ray.origin,
                rayDirection: ray.direction,
                sphereCenter: entity.position(relativeTo: nil),
                sphereRadius: selectionComponent.collisionRadius
            ) {
                // Track the closest intersected entity
                if distance < closestDistance {
                    closestDistance = distance
                    closestEntity = entity
                }
            }
        }
        
        // Update hover states: only the closest entity is hovered
        for entity in entities {
            guard let selectionComponent = entity.components[SelectionComponent.self] else {
                continue
            }
            
            let shouldBeHovered = (entity == closestEntity)
            if selectionComponent.isHovered != shouldBeHovered {
                var updatedComponent = selectionComponent
                updatedComponent.isHovered = shouldBeHovered
                entity.components[SelectionComponent.self] = updatedComponent
            }
        }
    }
    
    /// Clears hover states on all entities
    /// - Parameter entities: Entities to clear hover states
    private func clearHoverStates(entities: [Entity]) {
        for entity in entities {
            guard var selectionComponent = entity.components[SelectionComponent.self] else {
                continue
            }
            
            if selectionComponent.isHovered {
                selectionComponent.isHovered = false
                entity.components[SelectionComponent.self] = selectionComponent
            }
        }
    }
    
    /// Performs ray-sphere intersection test
    /// - Parameters:
    ///   - rayOrigin: Origin point of the ray
    ///   - rayDirection: Direction vector of the ray (should be normalized)
    ///   - sphereCenter: Center position of the sphere
    ///   - sphereRadius: Radius of the sphere
    /// - Returns: Distance to intersection point, or nil if no intersection
    private func raySphereIntersection(
        rayOrigin: SIMD3<Float>,
        rayDirection: SIMD3<Float>,
        sphereCenter: SIMD3<Float>,
        sphereRadius: Float
    ) -> Float? {
        // Vector from ray origin to sphere center
        let oc = rayOrigin - sphereCenter
        
        // Quadratic equation coefficients for ray-sphere intersection
        let a = dot(rayDirection, rayDirection)
        let b = 2.0 * dot(oc, rayDirection)
        let c = dot(oc, oc) - sphereRadius * sphereRadius
        
        // Discriminant
        let discriminant = b * b - 4 * a * c
        
        // No intersection if discriminant is negative
        guard discriminant >= 0 else {
            return nil
        }
        
        // Calculate the nearest intersection point
        let t = (-b - sqrt(discriminant)) / (2.0 * a)
        
        // Only return positive distances (in front of ray origin)
        return t > 0 ? t : nil
    }
    
    // MARK: - Query
    
    /// Query for entities with SelectionComponent
    private static let selectionQuery = EntityQuery(where: .has(SelectionComponent.self))
    
    // MARK: - Pinch Gesture Detection
    
    /// Handles pinch gesture detection and selection logic
    /// - Parameters:
    ///   - entities: Entities with SelectionComponent
    ///   - handTrackingProvider: Optional hand tracking provider
    ///   - appModel: Application model for updating selected planet
    private func handlePinchGesture(entities: [Entity], handTrackingProvider: HandTrackingProvider?, appModel: AppModel) {
        // Detect if pinch is currently active
        let isPinching = detectPinch(from: handTrackingProvider)
        
        // Detect pinch activation (transition from not pinching to pinching)
        let pinchActivated = isPinching && !wasPinching
        
        // Update previous pinch state
        wasPinching = isPinching
        
        // If pinch was just activated, select the hovered entity
        if pinchActivated {
            selectHoveredEntity(entities: entities, appModel: appModel)
        }
    }
    
    /// Detects if a pinch gesture is currently active
    /// - Parameter handTrackingProvider: Optional hand tracking provider
    /// - Returns: True if pinching, false otherwise
    private func detectPinch(from handTrackingProvider: HandTrackingProvider?) -> Bool {
        guard handTrackingProvider != nil else {
            // No hand tracking available, return false
            // In a real implementation, we might check for indirect pinch gestures
            return false
        }
        
        // Note: In a real implementation, we would:
        // 1. Iterate through provider.anchorUpdates
        // 2. Get thumb tip and index finger tip positions
        // 3. Calculate distance between them
        // 4. Return true if distance < pinchThreshold
        
        // For now, return false to rely on fallback tap gesture
        // This will be properly implemented when hand tracking is fully integrated
        return false
    }
    
    /// Selects the currently hovered entity
    /// - Parameters:
    ///   - entities: Entities with SelectionComponent
    ///   - appModel: Application model for updating selected planet
    private func selectHoveredEntity(entities: [Entity], appModel: AppModel) {
        var selectedEntity: Entity? = nil
        
        // Find the hovered entity and set it as selected
        for entity in entities {
            guard var selectionComponent = entity.components[SelectionComponent.self] else {
                continue
            }
            
            if selectionComponent.isHovered {
                // This entity is hovered, select it
                selectionComponent.isSelected = true
                entity.components[SelectionComponent.self] = selectionComponent
                selectedEntity = entity
            } else if selectionComponent.isSelected {
                // Clear selection on other entities (single selection model)
                selectionComponent.isSelected = false
                entity.components[SelectionComponent.self] = selectionComponent
            }
        }
        
        // Update appModel with selected planet data
        if let entity = selectedEntity,
           let planetDataComponent = entity.components[PlanetDataComponent.self] {
            // Extract PlanetDataComponent and create PlanetData for UI
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
        } else {
            // No entity selected, clear selected planet
            appModel.selectedPlanet = nil
        }
    }
}
