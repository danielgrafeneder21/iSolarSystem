# Implementation Plan

- [x] 1. Set up ECS foundation and component definitions
- [x] 1.1 Create OrbitComponent struct conforming to RealityKit Component protocol
  - Define radius, speed, currentPhase, and inclination properties
  - Add initializer with default values
  - _Requirements: 2.2_

- [x] 1.2 Create SelectionComponent struct conforming to Component protocol
  - Define isSelected, isHovered, and collisionRadius properties
  - _Requirements: 4.4_

- [x] 1.3 Create PlanetDataComponent struct conforming to Component protocol
  - Define name, type, radiusCategory, distanceCategory, orbitalPeriodCategory properties
  - Create PlanetType enum with terrestrial and gasGiant cases
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 1.4 Create HighlightComponent struct conforming to Component protocol
  - Define targetIntensity, currentIntensity, and animationSpeed properties
  - _Requirements: 5.6_

- [x] 2. Extend AppModel with simulation state
- [x] 2.1 Add simulation control properties to AppModel
  - Add simulationTimeScale property (Float, default 1.0)
  - Add isPlaying property (Bool, default true)
  - Add lastNonZeroTimeScale property (Float, default 1.0)
  - Add selectedPlanet property (PlanetData?, default nil)
  - _Requirements: 3.2, 3.4_

- [x] 2.2 Create PlanetData struct for UI display
  - Define id, name, type, radiusCategory, distanceCategory, orbitalPeriodCategory properties
  - Conform to Identifiable protocol
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 2.3 Add system references to AppModel
  - Add optional properties for OrbitSystem, SelectionSystem, HighlightSystem
  - _Requirements: 2.1_

- [x] 3. Implement OrbitSystem for planetary motion
- [x] 3.1 Create OrbitSystem class with update method
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

- [x] 4. Create solar system scene with Sun and planets
- [x] 4.1 Implement createSunEntity() function
  - Create Entity with ModelComponent (sphere mesh)
  - Apply emissive material with yellow/orange color
  - Set scale to ~0.3m diameter
  - Position at origin (0, 0, 0)
  - _Requirements: 1.2_

- [x] 4.2 Implement createPlanetEntity() function
  - Accept parameters: name, radius, speed, size, type, color
  - Create Entity with ModelComponent (sphere mesh)
  - Attach OrbitComponent with provided parameters
  - Attach SelectionComponent with collision radius matching size
  - Attach PlanetDataComponent with educational info
  - Attach HighlightComponent with default values
  - Apply material with provided color
  - Set scale based on size parameter
  - _Requirements: 1.3, 1.4, 1.5, 2.2, 4.4, 5.2, 5.3, 5.4_

- [x] 4.3 Create setupSolarSystem() function in ImmersiveView
  - Create root SolarSystemScene entity
  - Call createSunEntity() and add to scene
  - Create 6 planets (Mercury, Venus, Earth, Mars, Jupiter, Saturn) with createPlanetEntity()
  - Configure each planet with unique orbital parameters and data
  - Add all entities to RealityView content
  - _Requirements: 1.2, 1.3, 1.4, 1.5_

- [x] 5. Implement SelectionSystem for hand tracking and interaction
- [x] 5.1 Create SelectionSystem class with update method
  - Implement update(context:appModel:handTrackingProvider:) method signature
  - Query all entities with SelectionComponent
  - _Requirements: 4.1, 4.4_

- [x] 5.2 Implement ray casting and hit testing logic
  - Get hand anchor position and direction from HandTrackingProvider (if available)
  - Fallback to gaze-based ray from camera if hand tracking unavailable
  - Perform ray-sphere intersection test for each entity with SelectionComponent
  - Update isHovered property on entities based on intersection results
  - _Requirements: 4.2, 4.5_

- [x] 5.3 Implement pinch gesture detection and selection logic
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

- [x] 6. Implement HighlightSystem for visual feedback
- [x] 6.1 Create HighlightSystem class with update method
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

- [x] 7. Integrate systems into ImmersiveView update loop
- [x] 7.1 Set up RealityView update closure
  - Add update parameter to RealityView
  - Create update closure that receives SceneUpdateContext
  - _Requirements: 2.1_

- [x] 7.2 Initialize and call systems each frame
  - Initialize OrbitSystem, SelectionSystem, HighlightSystem in RealityView
  - Store system references in appModel
  - Call orbitSystem.update() in update closure
  - Call selectionSystem.update() in update closure
  - Call highlightSystem.update() in update closure
  - Pass appModel and handTrackingProvider to systems as needed
  - _Requirements: 2.1, 2.3, 2.5_

- [x] 8. Implement Time Control ornament UI
- [x] 8.1 Create TimeControlOrnament SwiftUI view
  - Create HStack layout with play/pause button and slider
  - Add play/pause button with SF Symbol icon (play.fill / pause.fill)
  - Implement togglePlayPause() action that updates appModel.isPlaying and simulationTimeScale
  - Add Slider bound to appModel.simulationTimeScale with range 0.1...50.0
  - Add Text label showing current time scale formatted as "X.X×"
  - Apply .glassBackgroundEffect() modifier
  - Apply .hoverEffect() to button
  - _Requirements: 3.1, 3.2, 3.4, 6.1, 6.2_

- [x] 8.2 Attach TimeControlOrnament to ImmersiveView
  - Add .ornament(attachmentAnchor: .scene(.bottom)) modifier to RealityView
  - Pass TimeControlOrnament as ornament content
  - Inject appModel environment
  - _Requirements: 3.1, 6.3_

- [x] 9. Implement Info Panel ornament UI
- [x] 9.1 Create InfoPanelOrnament SwiftUI view
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

- [x] 9.2 Conditionally attach InfoPanelOrnament to ImmersiveView
  - Add conditional .ornament(attachmentAnchor: .scene(.trailing)) modifier to RealityView
  - Show ornament only when appModel.selectedPlanet != nil
  - Pass selectedPlanet data to InfoPanelOrnament
  - Add fade-in/fade-out transition animation
  - _Requirements: 5.1, 5.5, 6.3_

- [x] 10. Integrate hand tracking provider
- [x] 10.1 Set up HandTrackingProvider in ImmersiveView
  - Create @State property for HandTrackingProvider
  - Initialize provider in RealityView content closure
  - Start hand tracking with Task { try? await handTrackingProvider.start() }
  - Pass provider to SelectionSystem in update loop
  - _Requirements: 4.1_

- [x] 10.2 Add fallback gesture recognizer for gaze-based selection
  - Add .gesture(SpatialTapGesture().targetedToAnyEntity()) modifier to RealityView
  - Implement .onEnded handler that extracts tapped entity
  - Update SelectionComponent on tapped entity
  - Update appModel.selectedPlanet with entity's PlanetDataComponent
  - _Requirements: 4.5_

- [x] 11. Polish and refinement
- [x] 11.1 Add error handling for scene loading
  - Wrap entity creation in do-catch blocks
  - Log errors with descriptive messages
  - Add sceneLoadError property to AppModel
  - Display error message in ContentView if scene fails to load
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 11.2 Optimize orbital parameters for visual appeal
  - Adjust planet sizes for clear visibility and differentiation
  - Tune orbital speeds for engaging motion at 1× time scale
  - Set orbital radii to avoid crowding while maintaining visibility
  - Test and adjust inclination values for visual variety
  - _Requirements: 1.4, 1.5_

- [x] 11.3 Refine highlight visual effects
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

- [ ] 12. Implement planet self-rotation
- [ ] 12.1 Create RotationComponent struct conforming to Component protocol
  - Define rotationSpeed property (radians per second around Y-axis)
  - Define currentRotation property (current rotation angle in radians)
  - Add initializer with default values
  - _Requirements: 2.2_

- [ ] 12.2 Update createPlanetEntity() to attach RotationComponent
  - Add rotationSpeed parameter to createPlanetEntity() function
  - Attach RotationComponent with provided rotation speed
  - Set realistic rotation speeds for each planet (Earth: ~6.28 rad/day, Jupiter: faster, Venus: very slow retrograde)
  - _Requirements: 1.3, 2.2_

- [ ] 12.3 Implement rotation logic in update loop
  - In updateOrbits() or create separate updateRotations() method
  - Query all entities with RotationComponent
  - Calculate rotation advancement: currentRotation += rotationSpeed × timeScale × deltaTime
  - Apply rotation to entity transform using quaternion rotation around Y-axis
  - Ensure rotation is independent of orbital position
  - _Requirements: 2.3, 2.5, 3.5_

- [ ] 12.4 Configure realistic rotation speeds for all planets
  - Mercury: moderate rotation (58.6 Earth days per rotation)
  - Venus: very slow retrograde rotation (243 Earth days, opposite direction)
  - Earth: baseline rotation (24 hours = 1 day)
  - Mars: similar to Earth (24.6 hours)
  - Jupiter: fast rotation (9.9 hours)
  - Saturn: fast rotation (10.7 hours)
  - Scale rotation speeds to be visible and engaging at 1× time scale
  - _Requirements: 1.4, 1.5_

- [ ] 13. Enhance planet information display
- [ ] 13.1 Expand PlanetDataComponent with additional properties
  - Add rotationPeriod property (string describing rotation period)
  - Add orbitalPeriod property (string describing orbital period)
  - Add diameter property (string describing planet diameter)
  - Add distanceFromSun property (string describing distance)
  - Add interestingFact property (string with educational fact)
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 13.2 Update InfoPanelOrnament to display enhanced information
  - Add row for rotation period
  - Add row for orbital period
  - Add row for diameter
  - Add row for distance from Sun
  - Add section for interesting fact with different styling
  - Ensure layout remains clean and readable
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [ ] 13.3 Populate realistic data for all planets
  - Mercury: rotation 58.6d, orbit 88d, diameter 4,879km, distance 57.9M km
  - Venus: rotation 243d (retrograde), orbit 225d, diameter 12,104km, distance 108.2M km
  - Earth: rotation 24h, orbit 365.25d, diameter 12,742km, distance 149.6M km
  - Mars: rotation 24.6h, orbit 687d, diameter 6,779km, distance 227.9M km
  - Jupiter: rotation 9.9h, orbit 12y, diameter 139,820km, distance 778.5M km
  - Saturn: rotation 10.7h, orbit 29y, diameter 116,460km, distance 1.43B km
  - Add interesting facts for each planet
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 14. Improve initial planet positioning
- [ ] 14.1 Set realistic starting positions for planets
  - Calculate initial phase values to create visually interesting starting configuration
  - Ensure planets are distributed around the Sun (not all aligned)
  - Use astronomically inspired positions (e.g., based on a specific date)
  - Avoid overlapping planets in initial view
  - _Requirements: 1.4, 1.5_

- [ ] 14.2 Add configuration for starting date/time
  - Add optional startDate property to AppModel
  - Calculate initial orbital phases based on start date
  - Default to a visually appealing configuration if no date specified
  - _Requirements: 3.2_

- [ ] 15. Fix UI visibility and accessibility issues
- [ ] 15.1 Verify ornaments are visible in immersive space
  - Test TimeControlOrnament visibility at bottom of scene
  - Test InfoPanelOrnament visibility when planet is selected
  - Add fallback UI if ornaments aren't visible in immersive mode
  - Consider adding controls to the main window instead of ornaments
  - _Requirements: 3.1, 6.3_

- [ ] 15.2 Add visual debugging for simulation state
  - Add console logging for planet creation
  - Add console logging for update loop execution
  - Add visual indicator showing simulation is running (e.g., frame counter)
  - Verify planets are being created and positioned correctly
  - _Requirements: 7.1, 7.2_

- [ ] 15.3 Create alternative control panel in main window
  - Add time control UI to ContentView as fallback
  - Display current simulation speed in main window
  - Add play/pause button in main window
  - Show selected planet info in main window
  - Ensure controls work whether in immersive space or not
  - _Requirements: 3.1, 3.2, 6.1, 6.2_
