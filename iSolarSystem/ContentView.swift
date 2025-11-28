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
    @Environment(\.openWindow) private var openWindow

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
            }

            if appModel.sceneLoadError == nil {
                ToggleImmersiveSpaceButton()
                
                // Floating window controls when immersive space is open
                if appModel.immersiveSpaceState == .open {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "macwindow.on.rectangle")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Floating Windows")
                                    .font(.headline)
                                Text("Open control panels in 3D space")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                openWindow(id: "TimeControlWindow")
                            } label: {
                                Label("Controls", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("Open time control window")
                            
                            Button {
                                openWindow(id: "DebugWindow")
                            } label: {
                                Label("Debug", systemImage: "gauge")
                            }
                            .buttonStyle(.bordered)
                            .help("Open debug info window")
                            
                            Button {
                                openWindow(id: "PlanetInfoWindow")
                            } label: {
                                Label("Planet Info", systemImage: "info.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .help("Open planet information window")
                        }
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
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
