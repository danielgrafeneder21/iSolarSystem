# Implementation Plan

- [ ] 1. Set up ECS foundation and component definitions
- [ ] 1.1 Create OrbitComponent struct conforming to RealityKit Component protocol
  - Define radius, speed, currentPhase, and inclination properties
  - Add initializer with default values
  - _Requirements: 2.2_

- [ ] 1.2 Create SelectionComponent struct conforming to Component protocol
  - Define isSelected, isHovered, and collisionRadius properties
  - _Requirements: 4.4_

- [ ] 1.3 Create PlanetDataComponent struct conforming to Component protocol
  - Define name, type, radiusCategory, distanceCategory, orbitalPeriodCategory properties
  - Create PlanetType enum with terrestrial and gasGiant cases
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 1.4 Create HighlightComponent struct conforming to Component protocol
  - Define targetIntensity, currentIntensity, and animationSpeed properties
  - _Requirements: 5.6_

- [ ] 2. Extend AppModel with simulation state
- [ ] 2.1 Add simulation control properties to AppModel
  - Add simulationTimeScale property (Float, default 1.0)
  - Add isPlaying property (Bool, default true)
  - Add lastNonZeroTimeScale property (Float, default 1.0)
  - Add selectedPlanet property (PlanetData?, default nil)
  - _Requirements: 3.2, 3.4_

- [ ] 2.2 Create PlanetData struct for UI display
  - Define id, name, type, radiusCategory, distanceCategory, orbitalPeriodCategory properties
  - Conform to Identifiable protocol
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 2.3 Add system references to AppModel
  - Add optional properties for OrbitSystem, SelectionSystem, HighlightSystem
  - _Requirements: 2.1_

- [ ] 3. Implement OrbitSystem for planetary motion
- [ ] 3.1 Create OrbitSystem class with update method
  - Implement update(context:appModel:) method signature
  - Query all entities with OrbitComponent
  - Calculate phase advancement: currentPhase += speed × timeScale × deltaTime
  - Calculate position using circular orbit: (radius × cos(phase), 0, radius × sin(phase))
  - Apply inclination rotation if non-zero
  - Update entity transform position
  - _Requirements: 2.3, 2.4, 2.5, 3.5_

- [ ]* 3.2 Write unit tests for OrbitSystem calculations
  - Test phase advancement with various time scales
  - Test position calculation at key angles (0, π/2, π, 3π/2)
  - Test inclination application
  - _Requirements: 2.3, 2.4_

- [ ] 4. Create solar system scene with Sun and planets
- [ ] 4.1 Implement createSunEntity() function
  - Create Entity with ModelComponent (sphere mesh)
  - Apply emissive material with yellow/orange color
  - Set scale to ~0.3m diameter
  - Position at origin (0, 0, 0)
  - _Requirements: 1.2_

- [ ] 4.2 Implement createPlanetEntity() function
  - Accept parameters: name, radius, speed, size, type, color
  - Create Entity with ModelComponent (sphere mesh)
  - Attach OrbitComponent with provided parameters
  - Attach SelectionComponent with collision radius matching size
  - Attach PlanetDataComponent with educational info
  - Attach HighlightComponent with default values
  - Apply material with provided color
  - Set scale based on size parameter
  - _Requirements: 1.3, 1.4, 1.5, 2.2, 4.4, 5.2, 5.3, 5.4_

- [ ] 4.3 Create setupSolarSystem() function in ImmersiveView
  - Create root SolarSystemScene entity
  - Call createSunEntity() and add to scene
  - Create 6 planets (Mercury, Venus, Earth, Mars, Jupiter, Saturn) with createPlanetEntity()
  - Configure each planet with unique orbital parameters and data
  - Add all entities to RealityView content
  - _Requirements: 1.2, 1.3, 1.4, 1.5_

- [ ] 5. Implement SelectionSystem for hand tracking and interaction
- [ ] 5.1 Create SelectionSystem class with update method
  - Implement update(context:appModel:handTrackingProvider:) method signature
  - Query all entities with SelectionComponent
  - _Requirements: 4.1, 4.4_

- [ ] 5.2 Implement ray casting and hit testing logic
  - Get hand anchor position and direction from HandTrackingProvider (if available)
  - Fallback to gaze-based ray from camera if hand tracking unavailable
  - Perform ray-sphere intersection test for each entity with SelectionComponent
  - Update isHovered property on entities based on intersection results
  - _Requirements: 4.2, 4.5_

- [ ] 5.3 Implement pinch gesture detection and selection logic
  - Monitor pinch distance between thumb and index finger joints
  - Detect pinch activation when distance < threshold while hovering
  - Set isSelected = true on activated entity
  - Clear isSelected on all other entities (single selection model)
  - Extract PlanetDataComponent and update appModel.selectedPlanet
  - _Requirements: 4.3, 4.4, 5.1_

- [ ]* 5.4 Write integration tests for selection flow
  - Test hover state updates with simulated ray input
  - Test selection state changes on pinch gesture
  - Test single selection enforcement
  - _Requirements: 4.2, 4.3, 4.4_

- [ ] 6. Implement HighlightSystem for visual feedback
- [ ] 6.1 Create HighlightSystem class with update method
  - Implement update(context:) method signature
  - Query all entities with HighlightComponent and SelectionComponent
  - Set targetIntensity based on selection state: 1.0 if selected, 0.3 if hovered, 0.0 otherwise
  - Interpolate currentIntensity toward targetIntensity using lerp with animationSpeed
  - Apply glow or outline effect to entity material based on currentIntensity
  - _Requirements: 4.2, 5.6_

- [ ]* 6.2 Write unit tests for highlight animation
  - Test intensity interpolation over multiple frames
  - Test target intensity selection based on hover/selection state
  - _Requirements: 5.6_

- [ ] 7. Integrate systems into ImmersiveView update loop
- [ ] 7.1 Set up RealityView update closure
  - Add update parameter to RealityView
  - Create update closure that receives SceneUpdateContext
  - _Requirements: 2.1_

- [ ] 7.2 Initialize and call systems each frame
  - Initialize OrbitSystem, SelectionSystem, HighlightSystem in RealityView
  - Store system references in appModel
  - Call orbitSystem.update() in update closure
  - Call selectionSystem.update() in update closure
  - Call highlightSystem.update() in update closure
  - Pass appModel and handTrackingProvider to systems as needed
  - _Requirements: 2.1, 2.3, 2.5_

- [ ] 8. Implement Time Control ornament UI
- [ ] 8.1 Create TimeControlOrnament SwiftUI view
  - Create HStack layout with play/pause button and slider
  - Add play/pause button with SF Symbol icon (play.fill / pause.fill)
  - Implement togglePlayPause() action that updates appModel.isPlaying and simulationTimeScale
  - Add Slider bound to appModel.simulationTimeScale with range 0.1...50.0
  - Add Text label showing current time scale formatted as "X.X×"
  - Apply .glassBackgroundEffect() modifier
  - Apply .hoverEffect() to button
  - _Requirements: 3.1, 3.2, 3.4, 6.1, 6.2_

- [ ] 8.2 Attach TimeControlOrnament to ImmersiveView
  - Add .ornament(attachmentAnchor: .scene(.bottom)) modifier to RealityView
  - Pass TimeControlOrnament as ornament content
  - Inject appModel environment
  - _Requirements: 3.1, 6.3_

- [ ] 9. Implement Info Panel ornament UI
- [ ] 9.1 Create InfoPanelOrnament SwiftUI view
  - Accept PlanetData parameter
  - Create VStack layout with planet name, type badge, and attribute rows
  - Add planet name as title with .font(.title2) and .bold()
  - Add type badge with capsule background
  - Add Divider
  - Create InfoRow helper view for attribute display
  - Add three InfoRow instances for size, distance, and orbit speed
  - Apply .glassBackgroundEffect() modifier
  - Set fixed width of 250pt
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 9.2 Conditionally attach InfoPanelOrnament to ImmersiveView
  - Add conditional .ornament(attachmentAnchor: .scene(.trailing)) modifier to RealityView
  - Show ornament only when appModel.selectedPlanet != nil
  - Pass selectedPlanet data to InfoPanelOrnament
  - Add fade-in/fade-out transition animation
  - _Requirements: 5.1, 5.5, 6.3_

- [ ] 10. Integrate hand tracking provider
- [ ] 10.1 Set up HandTrackingProvider in ImmersiveView
  - Create @State property for HandTrackingProvider
  - Initialize provider in RealityView content closure
  - Start hand tracking with Task { try? await handTrackingProvider.start() }
  - Pass provider to SelectionSystem in update loop
  - _Requirements: 4.1_

- [ ] 10.2 Add fallback gesture recognizer for gaze-based selection
  - Add .gesture(SpatialTapGesture().targetedToAnyEntity()) modifier to RealityView
  - Implement .onEnded handler that extracts tapped entity
  - Update SelectionComponent on tapped entity
  - Update appModel.selectedPlanet with entity's PlanetDataComponent
  - _Requirements: 4.5_

- [ ] 11. Polish and refinement
- [ ] 11.1 Add error handling for scene loading
  - Wrap entity creation in do-catch blocks
  - Log errors with descriptive messages
  - Add sceneLoadError property to AppModel
  - Display error message in ContentView if scene fails to load
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 11.2 Optimize orbital parameters for visual appeal
  - Adjust planet sizes for clear visibility and differentiation
  - Tune orbital speeds for engaging motion at 1× time scale
  - Set orbital radii to avoid crowding while maintaining visibility
  - Test and adjust inclination values for visual variety
  - _Requirements: 1.4, 1.5_

- [ ] 11.3 Refine highlight visual effects
  - Experiment with glow intensity and color
  - Add outline or scale effect for selected planets
  - Ensure hover effect is subtle but noticeable
  - Test visibility against various backgrounds
  - _Requirements: 4.2, 5.6_

- [ ]* 11.4 Add code documentation
  - Document all public types and methods with Swift doc comments
  - Add inline comments for complex calculations (orbit math, ray casting)
  - Create README section explaining ECS architecture
  - _Requirements: 7.5_

- [ ]* 11.5 Perform manual testing on device
  - Test hand tracking selection on physical Apple Vision Pro
  - Verify orbital motion smoothness at various time scales
  - Check UI ornament positioning and readability
  - Test fallback gaze-based selection
  - Validate all acceptance criteria from requirements
  - _Requirements: All requirements_
