# Design Document

## Overview

The visionOS Solar System Simulator is built using a three-layer architecture: SwiftUI for UI and application state, RealityKit for 3D scene management and rendering, and a custom Entity-Component System (ECS) for celestial body behavior. The application leverages visionOS Full Space immersion to create an engaging educational experience where users can observe planetary motion, control simulation time, and interact with planets using hand tracking.

The design emphasizes modularity and clarity, making it suitable for a student project while demonstrating professional visionOS development patterns. The ECS architecture separates data (Components) from behavior (Systems), allowing for clean, testable code that can be easily extended with additional features.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SwiftUI Layer                            │
│  ┌──────────────┐  ┌─────────────────┐  ┌───────────────┐  │
│  │ ContentView  │  │ ImmersiveView   │  │  Ornaments    │  │
│  │              │  │                 │  │ - TimeControl │  │
│  │ - Launch UI  │  │ - RealityView   │  │ - InfoPanel   │  │
│  └──────────────┘  └─────────────────┘  └───────────────┘  │
│                            │                      │          │
│                            ▼                      ▼          │
│                    ┌──────────────────────────────────┐     │
│                    │       AppModel                   │     │
│                    │  - immersiveSpaceState           │     │
│                    │  - simulationTimeScale           │     │
│                    │  - selectedPlanet                │     │
│                    │  - isPlaying                     │     │
│                    └──────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    RealityKit Layer                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              SolarSystemScene                        │   │
│  │  ┌────────────┐  ┌──────────────────────────────┐   │   │
│  │  │ Sun Entity │  │  Planet Entities (4-8)       │   │   │
│  │  │            │  │  - Mercury, Venus, Earth...  │   │   │
│  │  └────────────┘  └──────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│                            ▼                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Entity-Component System                    │   │
│  │                                                       │   │
│  │  Components:                    Systems:             │   │
│  │  - OrbitComponent               - OrbitSystem        │   │
│  │  - SelectionComponent           - SelectionSystem    │   │
│  │  - PlanetDataComponent          - HighlightSystem    │   │
│  │  - HighlightComponent                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                  visionOS Platform Layer                     │
│  - Hand Tracking Provider                                    │
│  - Spatial Input (Gaze, Pinch)                              │
│  - Full Space Immersion                                      │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Input → AppModel**: User interactions (slider, button, hand gestures) update AppModel state
2. **AppModel → Systems**: Systems read AppModel state (timeScale, selectedPlanet) each frame
3. **Systems → Components**: Systems update Component data (positions, highlight state)
4. **Components → Entities**: Entity transforms and materials reflect Component state
5. **Entities → UI**: Selection state triggers SwiftUI ornament display via AppModel

### Integration Points

- **SwiftUI ↔ RealityKit**: RealityView hosts the 3D scene; gesture recognizers bridge input
- **AppModel ↔ Systems**: Observable AppModel properties drive system behavior
- **Hand Tracking ↔ Selection**: ARKit hand tracking data feeds into SelectionSystem for hit testing
- **Selection ↔ UI**: Selected planet ID in AppModel triggers Info Panel ornament display

## Components and Interfaces

### Core Components

#### OrbitComponent
```swift
struct OrbitComponent: Component {
    /// Distance from the Sun in meters (scene units)
    var radius: Float
    
    /// Angular velocity in radians per second at 1× time scale
    var speed: Float
    
    /// Current angle in radians (0 = positive X axis)
    var currentPhase: Float
    
    /// Orbital plane tilt in radians (for visual variety)
    var inclination: Float = 0
}
```

**Purpose**: Defines orbital parameters for planets. The OrbitSystem reads these values to calculate positions each frame.

**Design Decision**: Store currentPhase in the component rather than computing from elapsed time to allow smooth time scale transitions and potential pause/resume without phase jumps.

#### SelectionComponent
```swift
struct SelectionComponent: Component {
    /// Whether this entity is currently selected
    var isSelected: Bool = false
    
    /// Whether this entity is currently hovered (hand/gaze targeting it)
    var isHovered: Bool = false
    
    /// Collision shape for hit testing
    var collisionRadius: Float
}
```

**Purpose**: Tracks selection and hover state for interactive entities. Used by SelectionSystem and HighlightSystem.

#### PlanetDataComponent
```swift
struct PlanetDataComponent: Component {
    var name: String
    var type: PlanetType
    var radiusCategory: String  // e.g., "Small", "Medium", "Large"
    var distanceCategory: String  // e.g., "Inner", "Outer"
    var orbitalPeriodCategory: String  // e.g., "Fast", "Moderate", "Slow"
    
    enum PlanetType: String {
        case terrestrial = "Terrestrial"
        case gasGiant = "Gas Giant"
    }
}
```

**Purpose**: Stores educational data displayed in the Info Panel. Kept separate from visual/behavior components for clarity.

#### HighlightComponent
```swift
struct HighlightComponent: Component {
    /// Target highlight intensity (0.0 to 1.0)
    var targetIntensity: Float = 0
    
    /// Current highlight intensity (animated toward target)
    var currentIntensity: Float = 0
    
    /// Animation speed
    var animationSpeed: Float = 5.0
}
```

**Purpose**: Manages smooth highlight animation when planets are hovered or selected. HighlightSystem interpolates currentIntensity toward targetIntensity.

### Systems

#### OrbitSystem
```swift
class OrbitSystem {
    func update(context: SceneUpdateContext, appModel: AppModel) {
        // For each entity with OrbitComponent:
        // 1. Read simulationTimeScale from appModel
        // 2. Advance currentPhase by speed × timeScale × deltaTime
        // 3. Calculate position: (radius × cos(phase), 0, radius × sin(phase))
        // 4. Apply inclination rotation if needed
        // 5. Update entity transform
    }
}
```

**Responsibilities**:
- Update orbital positions each frame based on time scale
- Handle circular orbit mathematics
- Apply orbital inclination for visual variety

**Design Decision**: Use simple circular orbits (not elliptical) to keep math straightforward for a student project while still demonstrating orbital mechanics.

#### SelectionSystem
```swift
class SelectionSystem {
    func update(context: SceneUpdateContext, appModel: AppModel, handTrackingProvider: HandTrackingProvider?) {
        // 1. Perform ray casting from hand/gaze position
        // 2. Update isHovered on entities based on ray intersection
        // 3. Detect pinch gesture or tap activation
        // 4. Update isSelected on activated entity
        // 5. Update appModel.selectedPlanet with selected entity's PlanetDataComponent
        // 6. Clear selection on other entities (single selection model)
    }
}
```

**Responsibilities**:
- Process hand tracking or gaze input
- Perform hit testing against entities with SelectionComponent
- Manage selection state (single selection at a time)
- Communicate selection to AppModel for UI updates

**Design Decision**: Support both hand tracking (primary) and gaze+pinch (fallback) to ensure functionality even if hand tracking is unavailable.

#### HighlightSystem
```swift
class HighlightSystem {
    func update(context: SceneUpdateContext) {
        // For each entity with HighlightComponent and SelectionComponent:
        // 1. Set targetIntensity based on isHovered (0.3) or isSelected (1.0)
        // 2. Interpolate currentIntensity toward targetIntensity
        // 3. Apply glow/outline material effect based on currentIntensity
    }
}
```

**Responsibilities**:
- Animate highlight effects smoothly
- Apply visual feedback for hover and selection states
- Manage material property updates

**Design Decision**: Use intensity-based animation rather than discrete on/off to create polished, professional-feeling interactions.

### Key Entities

#### SolarSystemScene (Root Entity)
- Container for all celestial bodies
- Positioned at origin (0, 0, 0) in the immersive space
- No components; purely organizational

#### SunEntity
- ModelComponent with emissive material (glowing sphere)
- No orbit or selection components (stationary, non-interactive)
- Scale: ~0.3m diameter (visible but not overwhelming)

#### PlanetEntity (4-8 instances)
- ModelComponent with distinct material per planet
- OrbitComponent with unique radius and speed
- SelectionComponent for interaction
- PlanetDataComponent with educational info
- HighlightComponent for visual feedback
- Scale: 0.05m - 0.15m diameter (smaller than Sun, varied sizes)

**Planet Configuration Example**:
```
Mercury: radius=0.5m, speed=4.0 rad/s, size=0.05m, type=terrestrial
Venus:   radius=0.7m, speed=3.0 rad/s, size=0.08m, type=terrestrial
Earth:   radius=1.0m, speed=2.0 rad/s, size=0.08m, type=terrestrial
Mars:    radius=1.3m, speed=1.5 rad/s, size=0.06m, type=terrestrial
Jupiter: radius=2.0m, speed=0.8 rad/s, size=0.15m, type=gasGiant
Saturn:  radius=2.5m, speed=0.6 rad/s, size=0.13m, type=gasGiant
```

## Data Models

### AppModel (Observable State)
```swift
@MainActor
@Observable
class AppModel {
    // Immersive space management
    let immersiveSpaceID = "ImmersiveSpace"
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    
    // Simulation control
    var simulationTimeScale: Float = 1.0  // 0.1 to 50.0
    var isPlaying: Bool = true
    var lastNonZeroTimeScale: Float = 1.0
    
    // Selection state
    var selectedPlanet: PlanetData? = nil
    
    // System references (for update loop)
    var orbitSystem: OrbitSystem?
    var selectionSystem: SelectionSystem?
    var highlightSystem: HighlightSystem?
    
    enum ImmersiveSpaceState {
        case closed, inTransition, open
    }
}
```

### PlanetData (UI Model)
```swift
struct PlanetData: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let radiusCategory: String
    let distanceCategory: String
    let orbitalPeriodCategory: String
}
```

**Purpose**: Simplified data structure for SwiftUI views. Extracted from PlanetDataComponent when a planet is selected.

## Hand Tracking Integration

### Hand Tracking Pipeline

1. **Provider Setup**: Initialize `HandTrackingProvider` in ImmersiveView when scene loads
2. **Frame Update**: Each frame, query hand anchor positions and joint data
3. **Ray Casting**: Compute ray from index finger tip (or hand center) in pointing direction
4. **Hit Testing**: SelectionSystem performs ray-entity intersection tests
5. **Gesture Detection**: Monitor pinch distance between thumb and index finger
6. **Activation**: When pinch distance < threshold while hovering, trigger selection

### Fallback Mechanism

If hand tracking is unavailable or fails:
- Use visionOS standard spatial input (gaze + indirect pinch)
- RealityView's built-in gesture recognizers handle tap events
- SelectionSystem checks for both hand tracking and gesture recognizer input

### Implementation Notes

```swift
// In ImmersiveView
@State private var handTrackingProvider = HandTrackingProvider()

RealityView { content in
    // Setup scene...
    
    // Start hand tracking
    Task {
        try? await handTrackingProvider.start()
    }
}
.gesture(
    SpatialTapGesture()
        .targetedToAnyEntity()
        .onEnded { value in
            // Fallback selection via tap
            handleEntityTap(value.entity)
        }
)
```

## User Interface Design

### Time Control Ornament

**Position**: Bottom center of user's view, ~1.5m away
**Components**:
- Slider: Horizontal, 200pt wide, range 0.1-50.0, logarithmic scale
- Label: Shows current time scale (e.g., "5.0×")
- Play/Pause Button: Toggle icon, 44pt tap target
- Layout: HStack with spacing

**Behavior**:
- Slider updates `appModel.simulationTimeScale` in real-time
- Play/Pause toggles between 0 and `lastNonZeroTimeScale`
- Hover effects: Scale up 1.05× and add subtle glow

```swift
struct TimeControlOrnament: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: togglePlayPause) {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.borderless)
            .hoverEffect()
            
            VStack {
                Slider(value: $appModel.simulationTimeScale, in: 0.1...50.0)
                    .frame(width: 200)
                Text("\(appModel.simulationTimeScale, specifier: "%.1f")×")
                    .font(.caption)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
```

### Info Panel Ornament

**Position**: Right side of selected planet, ~0.5m offset
**Components**:
- Planet name (title font)
- Type badge (capsule background)
- Attribute list (3 rows: radius, distance, period)
- Close button (optional, or auto-dismiss on deselect)

**Behavior**:
- Appears with fade-in animation when planet selected
- Follows planet position (attached to planet entity coordinate space)
- Dismisses with fade-out when selection cleared
- Glass background effect for visionOS aesthetic

```swift
struct InfoPanelOrnament: View {
    let planetData: PlanetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(planetData.name)
                .font(.title2)
                .bold()
            
            Text(planetData.type)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.3))
                .clipShape(Capsule())
            
            Divider()
            
            InfoRow(label: "Size", value: planetData.radiusCategory)
            InfoRow(label: "Distance", value: planetData.distanceCategory)
            InfoRow(label: "Orbit Speed", value: planetData.orbitalPeriodCategory)
        }
        .padding()
        .frame(width: 250)
        .glassBackgroundEffect()
    }
}
```

### Ornament Attachment Strategy

- **Time Control**: Use `.ornament(attachmentAnchor: .scene(.bottom))` on RealityView
- **Info Panel**: Use `.ornament(attachmentAnchor: .scene(.trailing))` conditionally when `selectedPlanet != nil`
- Both ornaments use `.glassBackgroundEffect()` for consistent visionOS styling

## Error Handling

### Scene Loading Failures

**Scenario**: RealityKit content bundle fails to load or entity creation fails

**Handling**:
- Wrap entity creation in `do-catch` blocks
- Log errors to console with descriptive messages
- Display fallback UI in ContentView: "Unable to load solar system scene"
- Provide retry button that attempts to reopen immersive space

```swift
do {
    let sunEntity = try await createSunEntity()
    content.add(sunEntity)
} catch {
    print("Failed to create sun entity: \(error)")
    // Set error state in AppModel
    appModel.sceneLoadError = error
}
```

### Hand Tracking Unavailable

**Scenario**: Device doesn't support hand tracking or user denied permission

**Handling**:
- Gracefully fall back to gaze + indirect pinch
- No error message needed (transparent fallback)
- SelectionSystem checks `handTrackingProvider.state` and adapts

### Invalid Time Scale Values

**Scenario**: User somehow sets time scale outside 0.1-50.0 range

**Handling**:
- Slider enforces range constraints in SwiftUI
- OrbitSystem clamps values: `timeScale = max(0.1, min(50.0, timeScale))`
- No user-facing error (defensive programming)

### Entity Not Found During Selection

**Scenario**: User taps/pinches but ray doesn't hit any entity

**Handling**:
- SelectionSystem clears current selection
- Info Panel dismisses
- No error state (expected behavior)

## Testing Strategy

### Unit Testing

**Target**: ECS Components and Systems logic

**Test Cases**:
1. **OrbitComponent**: Verify phase advancement calculation
   - Given: radius=1.0, speed=2.0, timeScale=1.0, deltaTime=0.1
   - Expected: phase advances by 0.2 radians
   
2. **OrbitSystem Position Calculation**: Verify circular orbit math
   - Given: radius=1.0, phase=0
   - Expected: position = (1.0, 0, 0)
   - Given: radius=1.0, phase=π/2
   - Expected: position ≈ (0, 0, 1.0)

3. **SelectionComponent State**: Verify single selection enforcement
   - Given: Planet A selected, user selects Planet B
   - Expected: Planet A.isSelected = false, Planet B.isSelected = true

4. **HighlightSystem Animation**: Verify intensity interpolation
   - Given: currentIntensity=0, targetIntensity=1.0, speed=5.0, deltaTime=0.1
   - Expected: currentIntensity ≈ 0.5 (exponential interpolation)

**Tools**: XCTest framework, mock AppModel and SceneUpdateContext

### Integration Testing

**Target**: SwiftUI ↔ RealityKit interaction

**Test Cases**:
1. **Time Scale Update**: Verify slider changes affect orbital speed
   - Action: Set slider to 10.0×
   - Verify: appModel.simulationTimeScale = 10.0
   - Verify: Planet positions advance 10× faster in next frame

2. **Selection → UI Update**: Verify planet selection shows Info Panel
   - Action: Simulate planet tap
   - Verify: appModel.selectedPlanet is set
   - Verify: Info Panel ornament appears

3. **Play/Pause Toggle**: Verify button stops/starts animation
   - Action: Tap pause button
   - Verify: appModel.isPlaying = false
   - Verify: simulationTimeScale = 0
   - Action: Tap play button
   - Verify: simulationTimeScale restored to previous value

**Tools**: XCTest with UI testing, visionOS Simulator

### Manual Testing

**Target**: Hand tracking, visual quality, user experience

**Test Scenarios**:
1. **Hand Tracking Selection**:
   - Point at planet with index finger
   - Verify hover glow appears
   - Perform pinch gesture
   - Verify planet highlights and Info Panel appears

2. **Orbital Motion Smoothness**:
   - Observe planets at 1× speed for 30 seconds
   - Verify smooth, continuous motion without stuttering
   - Change time scale to 10× and 0.1×
   - Verify no position jumps during transition

3. **UI Ergonomics**:
   - Verify Time Control ornament is comfortably readable
   - Verify Info Panel doesn't occlude planet view
   - Test hover effects on buttons and slider

4. **Fallback Input**:
   - Disable hand tracking (or test without hand tracking hardware)
   - Verify gaze + pinch selection works
   - Verify all interactions remain functional

**Tools**: Physical Apple Vision Pro device (preferred) or visionOS Simulator

### Performance Testing

**Metrics**:
- Frame rate: Target 90 FPS minimum in Full Space
- Memory usage: Monitor for leaks during extended use
- Startup time: Scene should load within 2 seconds

**Test Procedure**:
1. Run app with Instruments (Time Profiler, Allocations)
2. Monitor frame time during orbital updates
3. Verify no memory growth over 5 minutes of use
4. Profile entity creation and scene setup time

**Acceptance Criteria**:
- No frame drops below 90 FPS during normal operation
- Memory stable after initial scene load
- Scene loads and displays within 2 seconds

## Design Decisions and Rationales

### Circular Orbits
**Decision**: Use circular orbits instead of elliptical
**Rationale**: Simplifies mathematics for student project while still demonstrating orbital mechanics. Elliptical orbits would require Kepler's laws and variable speed calculations, adding complexity without significant educational benefit for this scope.

### Single Selection Model
**Decision**: Only one planet can be selected at a time
**Rationale**: Simplifies UI (one Info Panel) and interaction logic. Multi-selection would require more complex state management and UI layout without clear user benefit.

### Component-Based Highlight
**Decision**: Separate HighlightComponent from SelectionComponent
**Rationale**: Separates concerns (state vs. visual effect) and allows highlight animation to be reused for other purposes (e.g., hover-only effects on non-selectable entities in future).

### Observable AppModel
**Decision**: Use @Observable macro instead of ObservableObject
**Rationale**: Modern Swift pattern (iOS 17+/visionOS 1.0+) with better performance and cleaner syntax. Reduces boilerplate compared to @Published properties.

### Logarithmic Time Scale
**Decision**: Use logarithmic slider scale for time control
**Rationale**: Provides finer control at lower speeds (0.1× - 2×) where precision matters, while still allowing high speeds (10× - 50×) for quick observation. Linear scale would make low speeds hard to adjust.

### Ornament Positioning
**Decision**: Attach ornaments to scene rather than specific entities
**Rationale**: Scene-attached ornaments remain stable relative to user's view, improving readability. Entity-attached Info Panel follows planet but uses offset to avoid occlusion.

### Hand Tracking Fallback
**Decision**: Implement both hand tracking and gaze-based selection
**Rationale**: Ensures app works in simulator (no hand tracking) and for users who prefer indirect input. Demonstrates robust visionOS development practices.

## Future Extension Points

While out of scope for the initial student project, the architecture supports these extensions:

1. **Elliptical Orbits**: Add eccentricity parameter to OrbitComponent
2. **Moons**: Create child entities with relative orbits
3. **Camera Controls**: Allow user to zoom and pan around solar system
4. **More Planets**: Extend to full 8-planet system plus dwarf planets
5. **Asteroid Belt**: Particle system or instanced entities
6. **Educational Modes**: Guided tours, quiz mode, scale comparisons
7. **Persistence**: Save/load simulation state and time scale preferences
8. **Multi-User**: SharePlay support for collaborative exploration

The modular ECS design makes these additions straightforward without refactoring core systems.
