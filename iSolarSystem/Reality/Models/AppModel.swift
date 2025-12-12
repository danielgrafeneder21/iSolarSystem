//
//  AppModel.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 21.11.25.
//

import SwiftUI
import RealityKit

@MainActor
@Observable
class AppModel {
    init() {
        Scene.registerSystem(GravitySystem.self)
    }
}
