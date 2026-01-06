//
//  TimeControlOrnament.swift
//  iSolarSystem
//
//  Created by Kiro AI
//

import SwiftUI

/// Time Control window UI for adjusting simulation speed
struct TimeControlOrnament: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Play/Pause button
            Button(action: togglePlayPause) {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .hoverEffect()
            
            // Time scale slider and label
            VStack(spacing: 8) {
                Slider(value: Binding(
                    get: { appModel.simulationTimeScale },
                    set: { newValue in
                        appModel.simulationTimeScale = newValue
                        // Update lastNonZeroTimeScale if not zero
                        if newValue > 0 {
                            appModel.lastNonZeroTimeScale = newValue
                        }
                        // Update isPlaying based on whether scale is zero
                        appModel.isPlaying = newValue > 0
                    }
                ), in: 0.1...50.0)
                .frame(width: 200)
                
                Text(String(format: "%.1f×", appModel.simulationTimeScale))
                    .font(.caption)
                    .monospacedDigit()
            }
            
            // Orbit lines toggle button
            VStack(spacing: 4) {
                Button(action: {
                    appModel.showOrbitLines.toggle()
                }) {
                    Image(systemName: appModel.showOrbitLines ? "circle.circle.fill" : "circle.dotted")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .hoverEffect()
                
                Text("Orbits")
                    .font(.caption2)
            }
        }
        .padding(20)
        .glassBackgroundEffect()
    }
    
    /// Toggles between playing and paused states
    private func togglePlayPause() {
        if appModel.isPlaying {
            // Pause: save current scale and set to zero
            appModel.lastNonZeroTimeScale = appModel.simulationTimeScale
            appModel.simulationTimeScale = 0
            appModel.isPlaying = false
        } else {
            // Play: restore last non-zero scale
            appModel.simulationTimeScale = appModel.lastNonZeroTimeScale
            appModel.isPlaying = true
        }
    }
}

#Preview {
    TimeControlOrnament()
        .environment(AppModel())
}
