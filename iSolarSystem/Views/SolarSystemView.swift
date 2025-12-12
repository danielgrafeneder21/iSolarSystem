//
//  SolarSystemView.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI
import RealityKit

struct SolarSystemView: View {
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @State private var gravity = GravitySystem()
    
    var body: some View {
        RealityView { content in
            
            // (dark room)
            content.add(makeDarkBackground())
            
            // Load Sun.usdz WITHOUT escaping closure
            if let url = Bundle.main.url(forResource: "Sun", withExtension: "usdz") {
                if let sunEntity = try? await Entity(contentsOf: url) {
                    sunEntity.scale = [10, 10, 10]
                    sunEntity.position = [0, 1, 0] // center
                    content.add(sunEntity)
                    
                    gravity.addBody(entity: sunEntity, mass: 10000)
                } else {
                    print("Error: Could not load Sun.usdz")
                }
            } else {
                print("Sun.usdz not found!")
            }
            // LOAD Earth.usdz
            if let url = Bundle.main.url(forResource: "Earth", withExtension: "usdz") {
                if let earthEntity = try? await Entity(contentsOf: url) {
                    earthEntity.scale = [2, 2, 2]
                    earthEntity.position = [10, 1, 0] // x, y, z
                    content.add(earthEntity)
                    
                    gravity.addBody(entity: earthEntity, mass: 1, velocity: [0,0,1.5])
                } else {
                    print("Error: Could not load Earth.usdz")
                }
            } else {
                print("Earth.usdz not found!")
            }
        }
        
        update: { content in
            let dt = Float(content.deltaTime)
            gravity.update(dt: dt)
        }
        
        .overlay(alignment: .topLeading) {
            Button("Exit") {
                Task {
                    await dismissImmersiveSpace()
                }
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

func makeDarkBackground() -> Entity {
    let sphere = ModelEntity(
        mesh: .generateSphere(radius: 50),
        materials: [SimpleMaterial(color: .white, isMetallic: false)]
    )
    sphere.scale = [-1, 1, 1]
    return sphere
}
