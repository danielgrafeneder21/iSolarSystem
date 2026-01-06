//
//  iSolarSystemApp.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI

@main
struct iSolarSystemApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .defaultSize(width: 520, height: 320)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        
        // Time Control Window - floating window for simulation controls
        Window("Time Controls", id: "TimeControlWindow") {
            TimeControlOrnament()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 400, height: 150)
        
        // Debug Info Window - floating window for performance metrics
        Window("Debug Info", id: "DebugWindow") {
            DebugOrnament()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 200, height: 180)
        
        // Planet Info Window - floating window for selected planet details
        Window("Planet Information", id: "PlanetInfoWindow") {
            if let planet = appModel.selectedPlanet {
                InfoPanelOrnament(planetData: planet)
                    .environment(appModel)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Planet Selected")
                        .font(.headline)
                    Text("Tap a planet to see its information")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .windowStyle(.plain)
        .defaultSize(width: 320, height: 500)
    }
}
