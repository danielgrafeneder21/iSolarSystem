//
//  AppModel.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // MARK: - Simulation Control Properties
    
    /// Multiplier for orbital animation speed (0.1 to 50.0)
    var simulationTimeScale: Float = 1.0
    
    /// Whether the simulation is currently playing
    var isPlaying: Bool = true
    
    /// Last non-zero time scale value (for play/pause toggle)
    var lastNonZeroTimeScale: Float = 1.0
    
    /// Currently selected planet for Info Panel display
    var selectedPlanet: PlanetData? = nil
    
    /// Whether orbit lines should be visible for all planets
    var showOrbitLines: Bool = false
    
    // MARK: - System References
    
    /// Reference to OrbitSystem for update loop
    var orbitSystem: OrbitSystem?
    
    /// Reference to SelectionSystem for update loop
    var selectionSystem: SelectionSystem?
    
    /// Reference to HighlightSystem for update loop
    var highlightSystem: HighlightSystem?
    
    // MARK: - Error Handling
    
    /// Error that occurred during scene loading, if any
    var sceneLoadError: Error? = nil
    
    // MARK: - Initial Configuration
    
    /// Optional starting date for calculating initial planet positions
    /// If nil, uses a visually appealing default configuration
    var startDate: Date? = nil
    
    // MARK: - Debug Information
    
    /// Current frame rate for debugging
    var currentFPS: Double = 0.0
    
    /// Total frame count for debugging
    var totalFrameCount: Int = 0
}
