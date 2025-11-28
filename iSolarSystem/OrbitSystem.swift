//
//  OrbitSystem.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit
import simd

/// System responsible for updating planetary orbital positions each frame
class OrbitSystem {
    
    /// Updates orbital positions for all entities with OrbitComponent
    /// - Parameters:
    ///   - context: Scene update context containing delta time
    ///   - appModel: Application model containing simulation time scale
    func update(context: SceneUpdateContext, appModel: AppModel) {
        let deltaTime = Float(context.deltaTime)
        let timeScale = appModel.simulationTimeScale
        
        // Query all entities with OrbitComponent
        context.scene.performQuery(Self.orbitQuery).forEach { entity in
            guard var orbitComponent = entity.components[OrbitComponent.self] else {
                return
            }
            
            // Calculate phase advancement: currentPhase += speed × timeScale × deltaTime
            orbitComponent.currentPhase += orbitComponent.speed * timeScale * deltaTime
            
            // Calculate position using circular orbit: (radius × cos(phase), 0, radius × sin(phase))
            let x = orbitComponent.radius * cos(orbitComponent.currentPhase)
            let z = orbitComponent.radius * sin(orbitComponent.currentPhase)
            var position = SIMD3<Float>(x, 0, z)
            
            // Apply inclination rotation if non-zero
            if orbitComponent.inclination != 0 {
                // Create rotation matrix around Z-axis for orbital inclination
                let inclinationRotation = simd_quatf(angle: orbitComponent.inclination, axis: SIMD3<Float>(0, 0, 1))
                position = inclinationRotation.act(position)
            }
            
            // Update entity transform position
            entity.position = position
            
            // Update the component with the new phase
            entity.components[OrbitComponent.self] = orbitComponent
        }
    }
    
    /// Query for entities with OrbitComponent
    private static let orbitQuery = EntityQuery(where: .has(OrbitComponent.self))
}
