//
//  HighlightSystem.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit
import SwiftUI
import simd

/// System responsible for managing visual highlight effects on entities
class HighlightSystem {
    
    // MARK: - Update Method
    
    /// Updates highlight effects for all entities with HighlightComponent and SelectionComponent
    /// - Parameter context: Scene update context containing delta time
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        // Query all entities with both HighlightComponent and SelectionComponent
        let entities = context.scene.performQuery(Self.highlightQuery)
        
        for entity in entities {
            guard var highlightComponent = entity.components[HighlightComponent.self],
                  let selectionComponent = entity.components[SelectionComponent.self] else {
                continue
            }
            
            // Set targetIntensity based on selection state
            // 1.0 if selected, 0.25 if hovered (subtle), 0.0 otherwise
            if selectionComponent.isSelected {
                highlightComponent.targetIntensity = 1.0
            } else if selectionComponent.isHovered {
                highlightComponent.targetIntensity = 0.25  // Reduced for subtlety
            } else {
                highlightComponent.targetIntensity = 0.0
            }
            
            // Interpolate currentIntensity toward targetIntensity using lerp
            // Formula: current = current + (target - current) * speed * deltaTime
            let intensityDelta = highlightComponent.targetIntensity - highlightComponent.currentIntensity
            highlightComponent.currentIntensity += intensityDelta * highlightComponent.animationSpeed * deltaTime
            
            // Clamp to valid range [0.0, 1.0]
            highlightComponent.currentIntensity = max(0.0, min(1.0, highlightComponent.currentIntensity))
            
            // Update the component
            entity.components[HighlightComponent.self] = highlightComponent
            
            // Apply glow effect to entity material based on currentIntensity
            applyHighlightEffect(to: entity, intensity: highlightComponent.currentIntensity)
        }
    }
    
    // MARK: - Visual Effect Application
    
    /// Applies a glow or outline effect to the entity's material based on intensity
    /// - Parameters:
    ///   - entity: The entity to apply the effect to
    ///   - intensity: The highlight intensity (0.0 to 1.0)
    private func applyHighlightEffect(to entity: Entity, intensity: Float) {
        guard var modelComponent = entity.components[ModelComponent.self] else {
            return
        }
        
        // Get the current materials
        var materials = modelComponent.materials
        
        // Apply glow effect by modifying the material
        for i in 0..<materials.count {
            if let simpleMaterial = materials[i] as? SimpleMaterial {
                // Determine glow color based on intensity (selected vs hovered)
                let isSelected = intensity > 0.5
                
                // Apply effect if intensity is above threshold
                if intensity > 0.01 {
                    // Create a copy of the material with modified color
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
        
        // Apply subtle scale effect for selected planets
        if intensity > 0.5 {
            // Scale up selected planet by 5% for emphasis
            let baseScale = entity.scale
            let targetScale = SIMD3<Float>(repeating: 1.05)
            let mixFactor = SIMD3<Float>(repeating: intensity)
            entity.scale = simd_mix(baseScale, targetScale, mixFactor)
        } else {
            // Return to normal scale
            entity.scale = SIMD3<Float>(repeating: 1.0)
        }
        
        // Update the model component with modified materials
        modelComponent.materials = materials
        entity.components[ModelComponent.self] = modelComponent
    }
    
    // MARK: - Query
    
    /// Query for entities with both HighlightComponent and SelectionComponent
    private static let highlightQuery = EntityQuery(where: .has(HighlightComponent.self) && .has(SelectionComponent.self))
}
