//
//  ContentView.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showTestView = false

    var body: some View {
        VStack(spacing: 20) {
            // Display error message if scene failed to load
            if let error = appModel.sceneLoadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    
                    Text("Unable to load solar system scene")
                        .font(.title2)
                        .bold()
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        retrySceneLoad()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if !showTestView {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)

                Text("Hello, world!")
            } else {
                Text("Component Test Mode")
                    .font(.title)
                    .padding()
                
                Text("Check the console for component details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appModel.sceneLoadError == nil {
                ToggleImmersiveSpaceButton()
                
                // Time Controls
                if appModel.immersiveSpaceState == .open {
                    Divider()
                    
                    VStack(spacing: 12) {
                        Text("Simulation Controls")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            Button(action: togglePlayPause) {
                                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.bordered)
                            
                            VStack {
                                Slider(value: Binding(
                                    get: { appModel.simulationTimeScale },
                                    set: { newValue in
                                        appModel.simulationTimeScale = newValue
                                        if newValue > 0 {
                                            appModel.lastNonZeroTimeScale = newValue
                                        }
                                        appModel.isPlaying = newValue > 0
                                    }
                                ), in: 0.1...50.0)
                                .frame(width: 200)
                                
                                Text(String(format: "Speed: %.1f×", appModel.simulationTimeScale))
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Selected Planet Info
                    if let planet = appModel.selectedPlanet {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected: \(planet.name)")
                                .font(.headline)
                            Text("Type: \(planet.type)")
                                .font(.caption)
                            Text("Size: \(planet.radiusCategory)")
                                .font(.caption)
                            Text("Distance: \(planet.distanceCategory)")
                                .font(.caption)
                            Text("Orbit: \(planet.orbitalPeriodCategory)")
                                .font(.caption)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                }
                
                Button(showTestView ? "Show Original View" : "Test ECS Components") {
                    showTestView.toggle()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    /// Toggles between playing and paused states
    private func togglePlayPause() {
        if appModel.isPlaying {
            appModel.lastNonZeroTimeScale = appModel.simulationTimeScale
            appModel.simulationTimeScale = 0
            appModel.isPlaying = false
        } else {
            appModel.simulationTimeScale = appModel.lastNonZeroTimeScale
            appModel.isPlaying = true
        }
    }
    
    /// Attempts to retry loading the scene by closing and reopening the immersive space
    private func retrySceneLoad() {
        appModel.sceneLoadError = nil
        // The ToggleImmersiveSpaceButton will handle reopening
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
