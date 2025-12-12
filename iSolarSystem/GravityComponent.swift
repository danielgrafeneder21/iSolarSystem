//
//  GravityComponent.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 28.11.25.
//

import RealityKit

struct GravityBody {
    var entity: Entity
    var mass: Float
    var velocity: SIMD3<Float> // meters per second
}
