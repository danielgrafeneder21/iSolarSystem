//
//  OriginalMaterialComponent.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import RealityKit
import SwiftUI

/// Component to store the original material color for restoration after highlighting
struct OriginalMaterialComponent: Component {
    /// The original color of the entity's material
    var originalColor: UIColor
    
    init(originalColor: UIColor) {
        self.originalColor = originalColor
    }
}
