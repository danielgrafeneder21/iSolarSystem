//
//  DebugOrnament.swift
//  iSolarSystem
//
//  Created for visionOS Solar System Simulator
//

import SwiftUI

/// Debug window displaying simulation state and performance metrics
struct DebugOrnament: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(appModel.isPlaying ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(appModel.isPlaying ? "Running" : "Paused")
                    .font(.caption)
                    .bold()
            }
            
            Divider()
            
            // Performance metrics
            if appModel.currentFPS > 0 {
                HStack {
                    Text("FPS:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f", appModel.currentFPS))
                        .font(.caption2)
                        .bold()
                        .monospacedDigit()
                }
            }
            
            HStack {
                Text("Frame:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(appModel.totalFrameCount)")
                    .font(.caption2)
                    .bold()
                    .monospacedDigit()
            }
            
            HStack {
                Text("Speed:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f×", appModel.simulationTimeScale))
                    .font(.caption2)
                    .bold()
                    .monospacedDigit()
            }
        }
        .padding(16)
        .glassBackgroundEffect()
    }
}

#Preview {
    DebugOrnament()
        .environment(AppModel())
}
