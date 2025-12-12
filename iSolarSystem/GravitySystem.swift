//
//  GravitySystem.swift
//  iSolarSystem
//
//  Created by Grafeneder Daniel - s2310237026 on 28.11.25.
//

import RealityKit

class GravitySystem {
    
    let G: Float = 0.1
    var bodies: [GravityBody] = []
    
    func addBody(entity: Entity, mass: Float, velocity: SIMD3<Float> = .zero) {
        bodies.append(GravityBody(entity: entity, mass: mass, velocity: velocity))
    }
    
    func update(dt: Float) {
        // Pairwise gravitational force (N-body)
        for i in 0 ..< bodies.count {
            for j in (i + 1) ..< bodies.count {
                
                var a = bodies[i]
                var b = bodies[j]
                
                let delta = b.entity.position - a.entity.position
                let dist = max(length(delta), 0.1)
                let dir = normalize(delta)
                
                let f = G * a.mass * b.mass / (dist * dist)
                
                // accelerations
                let accelA = (f / a.mass) * dir
                let accelB = -(f / b.mass) * dir
                
                // update velocities
                a.velocity += accelA * dt
                b.velocity += accelB * dt
                
                bodies[i] = a
                bodies[j] = b
            }
        }
        
        // Move bodies using velocity
        for i in 0..<bodies.count {
            bodies[i].entity.position += bodies[i].velocity * dt
        }
    }
}
