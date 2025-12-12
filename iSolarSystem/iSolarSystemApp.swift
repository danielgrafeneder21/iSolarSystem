//
//  iSolarSystemApp.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 14.11.25.
//

import SwiftUI

@main
struct iSolarSystemApp: App {
    @State private var model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environment(model)
        }
        
        // immersive 3D world
        ImmersiveSpace(id: "SolarSystemSpace") {
            SolarSystemView()
                .environment(model)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
