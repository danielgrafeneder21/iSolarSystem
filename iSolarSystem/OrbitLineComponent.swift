//
//  OrbitLineComponent.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import RealityKit
import UIKit

/// Component that controls orbit line visualization for planets
struct OrbitLineComponent: Component {
    /// Whether the orbit line is currently visible
    var isVisible: Bool
    
    /// Color for the orbit line appearance
    var lineColor: UIColor
    
    /// Thickness of the orbit line in meters
    var lineWidth: Float
    
    /// Initializes an OrbitLineComponent with specified parameters
    /// - Parameters:
    ///   - isVisible: Whether the orbit line should be visible (default: false)
    ///   - lineColor: Color for the orbit line (default: white with 0.3 alpha)
    ///   - lineWidth: Thickness of the line in meters (default: 0.002)
    init(isVisible: Bool = false, lineColor: UIColor = UIColor(white: 1.0, alpha: 0.3), lineWidth: Float = 0.002) {
        self.isVisible = isVisible
        self.lineColor = lineColor
        self.lineWidth = lineWidth
    }
}
