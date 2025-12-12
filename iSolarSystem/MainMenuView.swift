//
//  MainMenuView.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 28.11.25.
//

import SwiftUI

struct MainMenuView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    @Environment(AppModel.self) var model
    
    var body: some View {
        VStack(spacing: 20) {
            Text("iSolarSystem")
                .font(.largeTitle)
        
            Button("Enter Solar System") {
                Task {
                    await openImmersiveSpace(id: "SolarSystemSpace")
                }
            }
        }
        .padding()
    }
}
