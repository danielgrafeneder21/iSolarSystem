//
//  HighlightSystem.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit
import SwiftUI
import simd
import Foundation

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
        guard var modelComponent = entity.components[ModelComponent.self],
              let originalMaterial = entity.components[OriginalMaterialComponent.self] else {
            return
        }
        
        // Get the current materials
        var materials = modelComponent.materials
        
        // Determine glow color based on intensity (selected vs hovered)
        let isSelected = intensity > 0.5
        
        // Apply glow effect by modifying the material
        for i in 0..<materials.count {
            if materials[i] is SimpleMaterial {
                // Apply effect if intensity is above threshold
                if intensity > 0.01 {
                    // Create a copy of the material with modified color
                    var newMaterial = SimpleMaterial()
                    
                    // Apply glow by blending original color with glow color
                    if isSelected {
                        // Bright cyan/blue glow for selected state - more intense
                        let glowColor = UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1.0)
                        // Blend original color with glow color based on intensity
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
        
        // Update the model component with modified materials
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
    /// - Parameters:
    ///   - color1: First color
    ///   - color2: Second color
    ///   - factor: Blend factor (0.0 = all color1, 1.0 = all color2)
    /// - Returns: Blended color
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
    /// - Parameters:
    ///   - entity: The entity to add the ring to
    ///   - intensity: The highlight intensity
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
        return

    }
    
    /// Removes the selection ring from the entity
    /// - Parameter entity: The entity to remove the ring from
    private func removeSelectionRing(from entity: Entity) {
        let ringName = "SelectionRing"
        if let ring = entity.children.first(where: { $0.name == ringName }) {
            ring.removeFromParent()
        }
    }
    
    /// Adds a floating 3D label above the entity
    /// - Parameter entity: The entity to add the label to
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
        // This will be updated each frame in the update method
        labelEntity.components[BillboardComponent.self] = BillboardComponent()
        
        // Add label as child of planet
        entity.addChild(labelEntity)
    }
    
    /// Removes the selection label from the entity
    /// - Parameter entity: The entity to remove the label from
    private func removeSelectionLabel(from entity: Entity) {
        let labelName = "SelectionLabel"
        if let label = entity.children.first(where: { $0.name == labelName }) {
            label.removeFromParent()
        }
    }
    
    // MARK: - Query
    
    /// Query for entities with both HighlightComponent and SelectionComponent
    private static let highlightQuery = EntityQuery(where: .has(HighlightComponent.self) && .has(SelectionComponent.self))
}
