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

- [x] 12. Implement planet self-rotation
- [x] 12.1 Create RotationComponent struct conforming to Component protocol
  - Define rotationSpeed property (radians per second around Y-axis)
  - Define currentRotation property (current rotation angle in radians)
  - Add initializer with default values
  - _Requirements: 2.2_

- [x] 12.2 Update createPlanetEntity() to attach RotationComponent
  - Add rotationSpeed parameter to createPlanetEntity() function
  - Attach RotationComponent with provided rotation speed
  - Set realistic rotation speeds for each planet (Earth: ~6.28 rad/day, Jupiter: faster, Venus: very slow retrograde)
  - _Requirements: 1.3, 2.2_

- [x] 12.3 Implement rotation logic in update loop
  - In updateOrbits() or create separate updateRotations() method
  - Query all entities with RotationComponent
  - Calculate rotation advancement: currentRotation += rotationSpeed × timeScale × deltaTime
  - Apply rotation to entity transform using quaternion rotation around Y-axis
  - Ensure rotation is independent of orbital position
  - _Requirements: 2.3, 2.5, 3.5_

- [x] 12.4 Configure realistic rotation speeds for all planets
  - Mercury: moderate rotation (58.6 Earth days per rotation)
  - Venus: very slow retrograde rotation (243 Earth days, opposite direction)
  - Earth: baseline rotation (24 hours = 1 day)
  - Mars: similar to Earth (24.6 hours)
  - Jupiter: fast rotation (9.9 hours)
  - Saturn: fast rotation (10.7 hours)
  - Scale rotation speeds to be visible and engaging at 1× time scale
  - _Requirements: 1.4, 1.5_

- [x] 13. Position solar system for isometric viewing angle
- [x] 13.1 Update setupSolarSystem to position scene relative to user
  - Position solar system root entity in front of user (e.g., 2-3 meters forward on Z-axis)
  - Elevate solar system slightly below eye level (e.g., -0.5 to -0.8 meters on Y-axis)
  - Apply rotation to tilt the orbital plane for isometric perspective (e.g., 30-45 degrees around X-axis)
  - Ensure Sun and planets remain visible and centered in user's initial view
  - _Requirements: 1.2, 1.3, 6.3_

- [x] 13.2 Test and adjust viewing angle for optimal experience
  - Verify user can see the entire solar system without turning head
  - Ensure orbital motion is clearly visible from default position
  - Adjust height and distance based on comfort and visibility
  - Test that selection and interaction still work correctly
  - _Requirements: 4.5, 6.3_

- [x] 14. Enhance planet information display
- [x] 14.1 Expand PlanetDataComponent with additional properties
  - Add rotationPeriod property (string describing rotation period)
  - Add orbitalPeriod property (string describing orbital period)
  - Add diameter property (string describing planet diameter)
  - Add distanceFromSun property (string describing distance)
  - Add interestingFact property (string with educational fact)
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 14.2 Update InfoPanelOrnament to display enhanced information
  - Add row for rotation period
  - Add row for orbital period
  - Add row for diameter
  - Add row for distance from Sun
  - Add section for interesting fact with different styling
  - Ensure layout remains clean and readable
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [x] 14.3 Populate realistic data for all planets
  - Mercury: rotation 58.6d, orbit 88d, diameter 4,879km, distance 57.9M km
  - Venus: rotation 243d (retrograde), orbit 225d, diameter 12,104km, distance 108.2M km
  - Earth: rotation 24h, orbit 365.25d, diameter 12,742km, distance 149.6M km
  - Mars: rotation 24.6h, orbit 687d, diameter 6,779km, distance 227.9M km
  - Jupiter: rotation 9.9h, orbit 12y, diameter 139,820km, distance 778.5M km
  - Saturn: rotation 10.7h, orbit 29y, diameter 116,460km, distance 1.43B km
  - Add interesting facts for each planet
  - _Requirements: 5.2, 5.3, 5.4_

- [x] 15. Improve initial planet positioning
- [x] 15.1 Set realistic starting positions for planets
  - Calculate initial phase values to create visually interesting starting configuration
  - Ensure planets are distributed around the Sun (not all aligned)
  - Use astronomically inspired positions (e.g., based on a specific date)
  - Avoid overlapping planets in initial view
  - _Requirements: 1.4, 1.5_

- [x] 15.2 Add configuration for starting date/time
  - Add optional startDate property to AppModel
  - Calculate initial orbital phases based on start date
  - Default to a visually appealing configuration if no date specified
  - _Requirements: 3.2_

- [x] 16. Add orbit line visualization
- [x] 16.1 Create OrbitLineComponent struct conforming to Component protocol
  - Define isVisible property (Bool) to control orbit line visibility
  - Define lineColor property (UIColor) for customizing orbit line appearance
  - Define lineWidth property (Float) for line thickness
  - Add initializer with default values (visible: false, color: white with low opacity, width: 0.002)
  - _Requirements: 1.4, 1.5_

- [x] 16.2 Add orbit line toggle to AppModel
  - Add showOrbitLines property (Bool, default false) to AppModel
  - This will control global visibility of all orbit lines
  - _Requirements: 3.2, 6.1_

- [x] 16.3 Implement orbit line generation function
  - Create generateOrbitLine() function that takes radius and inclination parameters
  - Generate circular path using multiple points (e.g., 64-128 points for smooth circle)
  - Calculate 3D positions for each point: (radius × cos(angle), 0, radius × sin(angle))
  - Apply inclination rotation to all points if non-zero
  - Create line entity using custom mesh or multiple cylinder segments
  - Apply semi-transparent material (e.g., white with 0.3 alpha)
  - Return entity representing the orbit line
  - _Requirements: 1.4, 2.2_

- [x] 16.4 Update createPlanetEntity to attach orbit lines
  - Call generateOrbitLine() with planet's orbital radius and inclination
  - Add orbit line entity as child of solar system scene (not planet entity)
  - Attach OrbitLineComponent to orbit line entity
  - Store reference to planet name in orbit line for association
  - Set initial visibility based on AppModel.showOrbitLines
  - _Requirements: 1.3, 1.4_

- [x] 16.5 Add orbit line visibility toggle to UI
  - Add toggle switch to TimeControlOrnament or create separate view controls
  - Bind toggle to AppModel.showOrbitLines
  - Add label "Show Orbit Lines" or "Orbits" with SF Symbol icon (circle.dotted or similar)
  - Apply .hoverEffect() to toggle for better interaction
  - _Requirements: 3.2, 6.1, 6.2_

- [x] 16.6 Implement orbit line visibility update logic
  - Create updateOrbitLineVisibility() method in ImmersiveView
  - Query all entities with OrbitLineComponent
  - Show/hide orbit lines based on AppModel.showOrbitLines
  - Update ModelComponent opacity or isEnabled property
  - Call this method when showOrbitLines changes
  - _Requirements: 3.2, 6.3_

- [ ]* 16.7 Add per-planet orbit line color customization (optional enhancement)
  - Assign unique colors to each planet's orbit line for visual distinction
  - Inner planets: warmer colors (Mercury: gray, Venus: yellow, Earth: blue, Mars: red)
  - Outer planets: cooler colors (Jupiter: orange, Saturn: gold)
  - Update generateOrbitLine() to accept color parameter
  - _Requirements: 1.4, 1.5_

- [x] 17. Fix UI visibility and accessibility issues
- [x] 17.1 Verify ornaments are visible in immersive space
  - Test TimeControlOrnament visibility at bottom of scene
  - Test InfoPanelOrnament visibility when planet is selected
  - Add fallback UI if ornaments aren't visible in immersive mode
  - Consider adding controls to the main window instead of ornaments
  - _Requirements: 3.1, 6.3_

- [x] 17.2 Add visual debugging for simulation state
  - Add console logging for planet creation
  - Add console logging for update loop execution
  - Add visual indicator showing simulation is running (e.g., frame counter)
  - Verify planets are being created and positioned correctly
  - _Requirements: 7.1, 7.2_

- [x] 17.3 Create alternative control panel in main window
  - Add time control UI to ContentView as fallback
  - Display current simulation speed in main window
  - Add play/pause button in main window
  - Show selected planet info in main window
  - Ensure controls work whether in immersive space or not
  - _Requirements: 3.1, 3.2, 6.1, 6.2_

- [ ] 18. Replace sphere meshes with Reality Composer Pro models
- [ ] 18.1 Create Reality Composer Pro project for planet models
  - Open Reality Composer Pro
  - Create a new project or scene file
  - Import or create 3D models for each planet (Mercury, Venus, Earth, Mars, Jupiter, Saturn)
  - Add realistic textures for each planet
  - Export models to RealityKitContent bundle
  - _Requirements: 1.3, 1.4_

- [ ] 18.2 Update createPlanetEntity to load models from Reality Composer
  - Replace MeshResource.generateSphere with Entity.load from RealityKitContent
  - Load planet-specific models by name (e.g., "Mercury", "Earth", etc.)
  - Maintain proper scaling based on size parameter
  - Ensure collision shapes match model geometry
  - Handle model loading errors gracefully
  - _Requirements: 1.3, 7.1, 7.2_

- [ ] 18.3 Update selection visual feedback for 3D models
  - Add outline shader or ring around selected planet instead of color change
  - Create a selection ring entity that orbits around selected planet
  - Or add a pulsing scale animation for selected planets
  - Ensure selection indicator works with textured models
  - Test visibility of selection indicator against various backgrounds
  - _Requirements: 4.2, 5.6_

- [ ] 19. Implement planet size normalization mode
- [ ] 19.1 Add size normalization toggle to AppModel
  - Add isNormalizedSize property (Bool, default false)
  - Add toggle control in ContentView simulation controls
  - Add button or switch to enable/disable normalized sizes
  - _Requirements: 3.2, 6.1_

- [ ] 19.2 Implement size normalization logic
  - Define normalized size range (e.g., 0.08 to 0.12 meters)
  - Calculate normalized sizes that compress large planets and enlarge small ones
  - Apply logarithmic or custom scaling to balance visibility
  - Store both realistic and normalized sizes in planet configuration
  - _Requirements: 1.4, 1.5_

- [ ] 19.3 Update planet rendering to respect size mode
  - Modify createPlanetEntity or add updatePlanetSizes method
  - Switch between realistic and normalized sizes based on AppModel.isNormalizedSize
  - Animate size transitions smoothly when toggling modes
  - Update collision shapes to match current size
  - Ensure orbital radii remain unchanged
  - _Requirements: 1.4, 1.5, 3.2_

- [ ] 19.4 Add visual indicator for normalization mode
  - Display "Normalized Sizes" or "Realistic Sizes" label in UI
  - Add tooltip explaining what normalization does
  - Consider adding icon or badge to indicate current mode
  - _Requirements: 6.1, 6.2_

- [ ] 20. Improve visualization of currently selected planet
- [ ] 20.1 Enhance selection visual feedback
  - Add more prominent selection ring or outline around selected planet
  - Increase glow intensity or add pulsing animation
  - Ensure selection marker is clearly visible from all angles
  - Differentiate selection marker from hover effect
  - Test visibility in various lighting conditions
  - _Requirements: 4.2, 5.6_

- [ ] 20.2 Add selection indicator in 3D space
  - Create floating label or icon above selected planet
  - Display planet name in 3D space near the planet
  - Add arrow or pointer connecting label to planet
  - Ensure label faces the user (billboard effect)
  - Make label optional via UI toggle
  - _Requirements: 5.2, 5.6_

- [ ] 20.3 Improve planet info window integration
  - Ensure Planet Info window updates immediately when selection changes
  - Add smooth transition animations when switching between planets
  - Consider adding thumbnail or icon of selected planet in window
  - Improve window layout and information hierarchy
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [ ] 20.4 Add camera focus option for selected planet
  - Implement smooth camera movement to focus on selected planet
  - Add "Focus on Planet" button in Planet Info window
  - Zoom to appropriate distance based on planet size
  - Maintain orbital motion visibility during focus
  - Add "Reset View" button to return to default position
  - _Requirements: 6.1, 6.3_

- [ ] 21. Implement realistic orbital plane inclinations
- [ ] 21.1 Research and document actual orbital inclinations
  - Document each planet's orbital inclination relative to ecliptic plane
  - Mercury: 7.0° (most inclined inner planet)
  - Venus: 3.4°
  - Earth: 0° (reference plane - ecliptic)
  - Mars: 1.9°
  - Jupiter: 1.3°
  - Saturn: 2.5°
  - Convert degrees to radians for implementation
  - _Requirements: 1.4, 1.5_

- [ ] 21.2 Update OrbitComponent to support 3D orbital plane orientation
  - Add longitudeOfAscendingNode property (Float) - angle where orbit crosses ecliptic plane
  - Keep existing inclination property for orbital tilt angle
  - Add helper method to calculate 3D rotation quaternion from inclination and node
  - Update initializer to accept both parameters
  - _Requirements: 2.2_

- [ ] 21.3 Implement 3D orbital plane rotation logic
  - Update orbit position calculation in OrbitSystem or updateOrbits method
  - First rotate orbit around Z-axis by longitudeOfAscendingNode
  - Then rotate around X-axis by inclination angle
  - Apply combined rotation to orbital position vector
  - Ensure rotation order is correct (node first, then inclination)
  - _Requirements: 2.3, 2.4, 2.5_

- [ ] 21.4 Configure realistic orbital plane parameters for all planets
  - Set inclination values based on astronomical data (converted to radians)
  - Set longitudeOfAscendingNode values for visual variety (can use simplified values)
  - Mercury: 7.0° inclination, 48.3° node
  - Venus: 3.4° inclination, 76.7° node
  - Earth: 0° inclination (reference), 0° node
  - Mars: 1.9° inclination, 49.6° node
  - Jupiter: 1.3° inclination, 100.5° node
  - Saturn: 2.5° inclination, 113.7° node
  - Test that planets no longer orbit in a flat plane
  - _Requirements: 1.4, 1.5_

- [ ] 21.5 Update orbit line generation to match 3D orbital planes
  - Modify generateOrbitLine() to apply same rotation as orbital motion
  - Apply longitudeOfAscendingNode rotation first
  - Apply inclination rotation second
  - Ensure orbit lines accurately represent 3D orbital paths
  - Test that orbit lines match planet trajectories
  - _Requirements: 1.4, 2.2_

- [ ] 21.6 Add toggle for realistic vs. simplified orbital planes
  - Add useRealisticOrbitalPlanes property to AppModel (Bool, default true)
  - When false, use simplified flat plane with minimal inclination (current behavior)
  - When true, use full 3D orbital plane orientation
  - Add toggle control in UI settings
  - Allow users to switch between modes for educational comparison
  - _Requirements: 3.2, 6.1_

- [ ] 22. Implement elliptical orbits
- [ ] 22.1 Research and document orbital eccentricity values
  - Document each planet's orbital eccentricity (0 = perfect circle, >0 = ellipse)
  - Mercury: 0.206 (most eccentric)
  - Venus: 0.007 (nearly circular)
  - Earth: 0.017 (nearly circular)
  - Mars: 0.093 (noticeably elliptical)
  - Jupiter: 0.048
  - Saturn: 0.056
  - Note: All planets have low eccentricity, so ellipses are subtle
  - _Requirements: 1.4, 1.5_

- [ ] 22.2 Update OrbitComponent to support elliptical parameters
  - Add eccentricity property (Float, 0.0 to 1.0) - shape of ellipse
  - Add semiMajorAxis property (Float) - half the longest diameter of ellipse
  - Add argumentOfPeriapsis property (Float) - rotation of ellipse in orbital plane
  - Keep radius as semiMajorAxis for backward compatibility
  - Update initializer with new parameters (default eccentricity = 0 for circular)
  - _Requirements: 2.2_

- [ ] 22.3 Implement elliptical orbit position calculation
  - Replace circular orbit formula with elliptical orbit calculation
  - Use parametric equations: r = a(1-e²)/(1+e·cos(θ))
  - Calculate x = r·cos(θ), z = r·sin(θ) where θ is true anomaly
  - Apply argumentOfPeriapsis rotation to orient ellipse in orbital plane
  - Then apply existing 3D orbital plane rotations
  - Ensure speed varies correctly (faster at perihelion, slower at aphelion - Kepler's 2nd law)
  - _Requirements: 2.3, 2.4, 2.5_

- [ ] 22.4 Adjust orbital speed for elliptical orbits (Kepler's 2nd Law)
  - Implement variable angular velocity based on distance from Sun
  - Use vis-viva equation or simplified approximation
  - Speed should increase as planet approaches perihelion (closest point)
  - Speed should decrease as planet approaches aphelion (farthest point)
  - Maintain constant orbital period despite variable speed
  - _Requirements: 2.3, 2.5, 3.5_

- [ ] 22.5 Configure realistic eccentricity values for all planets
  - Set eccentricity values based on astronomical data
  - Set argumentOfPeriapsis values for proper ellipse orientation
  - Mercury: e=0.206, ω=29.1°
  - Venus: e=0.007, ω=54.9°
  - Earth: e=0.017, ω=114.2°
  - Mars: e=0.093, ω=286.5° (most visible ellipse)
  - Jupiter: e=0.048, ω=273.9°
  - Saturn: e=0.056, ω=339.4°
  - Test that Mercury and Mars show visible elliptical paths
  - _Requirements: 1.4, 1.5_

- [ ] 22.6 Update orbit line generation for elliptical paths
  - Modify generateOrbitLine() to create elliptical paths instead of circles
  - Use same elliptical equations as orbital motion
  - Generate more points for smooth ellipse rendering (128-256 points)
  - Apply argumentOfPeriapsis and 3D orbital plane rotations
  - Ensure orbit lines accurately represent elliptical trajectories
  - _Requirements: 1.4, 2.2_

- [ ] 22.7 Add toggle for circular vs. elliptical orbits
  - Add useEllipticalOrbits property to AppModel (Bool, default true)
  - When false, use circular orbits (eccentricity = 0)
  - When true, use realistic elliptical orbits with actual eccentricity values
  - Add toggle control in UI settings
  - Allow users to switch between modes for educational comparison
  - Update orbit lines to match current mode
  - _Requirements: 3.2, 6.1_

- [ ]* 22.8 Add visual indicators for perihelion and aphelion
  - Add small marker entities at perihelion (closest) and aphelion (farthest) points
  - Use different colors or symbols (e.g., red for perihelion, blue for aphelion)
  - Show markers only when orbit lines are visible
  - Add labels or tooltips explaining these orbital points
  - Make markers optional via UI toggle
  - _Requirements: 1.4, 5.2_

- [ ] 23. Make the Sun selectable and display its information
- [ ] 23.1 Add selection components to the Sun entity
  - Attach SelectionComponent to Sun entity with appropriate collision radius
  - Attach HighlightComponent for visual feedback
  - Add CollisionComponent and InputTargetComponent for tap detection
  - Store original Sun material for restoration after highlighting
  - _Requirements: 4.4, 5.6_

- [ ] 23.2 Create SunData model and component
  - Create SunDataComponent similar to PlanetDataComponent
  - Include Sun-specific information (name, type, diameter, temperature, mass, etc.)
  - Add interesting facts about the Sun
  - Create SunData struct for UI display (similar to PlanetData)
  - _Requirements: 5.2, 5.3, 5.4_

- [ ] 23.3 Update selection logic to handle Sun selection
  - Modify handleEntityTap to recognize Sun entity
  - Extract SunDataComponent when Sun is selected
  - Update appModel.selectedPlanet to support both planets and Sun (or create selectedCelestialBody)
  - Clear selection from planets when Sun is selected
  - Ensure single selection model (only one celestial body selected at a time)
  - _Requirements: 4.3, 4.4, 5.1_

- [ ] 23.4 Update Planet Info window to display Sun information
  - Modify InfoPanelOrnament to handle both planet and Sun data
  - Adjust UI layout for Sun-specific information
  - Use appropriate icon/badge for the Sun (e.g., star icon)
  - Display Sun's unique properties (surface temperature, core temperature, composition)
  - Update window title to "Celestial Body Information" or similar
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [ ] 23.5 Add visual selection feedback for the Sun
  - Implement selection highlight that works with emissive Sun material
  - Add pulsing glow or corona effect when selected
  - Ensure selection marker is visible despite Sun's brightness
  - Test that highlight animation doesn't interfere with Sun's emissive properties
  - Consider adding selection ring around the Sun
  - _Requirements: 4.2, 5.6_

## Guide: Adding Reality Composer Pro Models

### Step 1: Create Models in Reality Composer Pro
1. Open **Reality Composer Pro** (included with Xcode)
2. Create a new project or open your existing RealityKitContent package
3. For each planet, either:
   - Import existing 3D models (.usdz, .obj, .fbx)
   - Create sphere primitives and apply planet textures
4. Name each model clearly: "Mercury", "Venus", "Earth", etc.
5. Apply realistic textures (you can find free planet textures online)
6. Set appropriate scales in Reality Composer Pro
7. Save the project

### Step 2: Reference Models in Code
Instead of:
```swift
let planetMesh = MeshResource.generateSphere(radius: size / 2)
```

Use:
```swift
let planetEntity = try await Entity(named: "Earth", in: realityKitContentBundle)
planetEntity.scale = SIMD3<Float>(repeating: size)
```

### Step 3: Update Selection Indicator
Since you can't easily change texture colors on complex models, use:
- **Option A**: Add a glowing ring around the planet
- **Option B**: Add a pulsing scale animation
- **Option C**: Add an outline shader effect

Example ring approach:
```swift
let ring = Entity()
let ringMesh = MeshResource.generatePlane(width: size * 2, depth: size * 2)
var ringMaterial = UnlitMaterial()
ringMaterial.color = .init(tint: .cyan)
ring.components[ModelComponent.self] = ModelComponent(mesh: ringMesh, materials: [ringMaterial])
ring.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
planetEntity.addChild(ring)
```
