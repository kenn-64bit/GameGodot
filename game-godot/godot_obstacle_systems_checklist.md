# Godot 4.6.2 Obstacle Systems Development Checklist

## Global Architecture & Best Practices

Before building individual obstacles, establish a strict physics layer foundation. This prevents objects from interacting incorrectly (e.g., lasers blocking boxes instead of just the player).

| Layer ID | Layer Name | Description |
| :--- | :--- | :--- |
| 1 | `Player` | The player character's kinematic body. |
| 2 | `World` | Static environment (TileMaps, solid walls, floors). |
| 3 | `Interactables` | Movable boxes and physics objects. |
| 4 | `Triggers` | Floor buttons, pressure plates, and detection zones. |
| 5 | `Hazards` | Spikes and instant-kill zones. |
| 6 | `Obstacles` | Solid barriers like Doors and Lasers. |

**Godot 4.6.2 specific note:** Use the modern `TileMapLayer` node instead of the deprecated monolithic `TileMap` node. This allows you to separate your visual environment from your hazard triggers (e.g., placing static spikes on a dedicated `TileMapLayer` for easier collision management).

---

## System 1: Floor Buttons (The Trigger Mechanism)

Because Lasers and Doors share the same trigger logic (stepped on by player or movable box), you must build a reusable Button component first.

### Core Setup
* **Required Nodes:** `Area2D` (Root) -> `Sprite2D` (Visual) -> `CollisionShape2D` (Hitbox).
* **Collision Setup:** Area2D detects bodies entering/exiting.
* **Physics Layer/Mask:** Layer = `Triggers` (4). Mask = `Player` (1) AND `Interactables` (3).
* **Signals Needed:** `body_entered`, `body_exited`, custom signals: `activated`, `deactivated`.
* **Editor Organization:** Save as `res://obstacles/triggers/floor_button.tscn`.
* **Naming Conventions:** Root node `FloorButton`.

### Implementation Details
* **Trigger Logic:** Track the number of overlapping bodies using an internal counter integer. Increment on `body_entered`, decrement on `body_exited`. Activate when counter > 0, deactivate when counter == 0.
* **State Management:** Maintain a boolean `is_pressed`.
* **Reusability/Modularity:** Use Godot 4's `@export var target_obstacles: Array[Node]` to link one button to multiple doors/lasers in the editor.
* **Interactions:** When pressed, iterate through `target_obstacles` and call their `toggle_state()` or `set_active()` methods.

---

## System 2: Lasers (Movement Blockers)

These lasers strictly block player movement. They do not kill the player and do not block movable boxes.

### Core Setup
* **Required Nodes:** `StaticBody2D` (Root) -> `Line2D` or `Sprite2D` (Beam Visual) -> `CollisionShape2D` (Blocker) -> `Timer` (For timed variants) -> `AnimationPlayer` (Flicker/startup effects).
* **Collision Setup:** Must use a `RectangleShape2D` that exactly matches the visual beam.
* **Physics Layer/Mask:** Layer = `Obstacles` (6). Mask = None (It only exists to be collided *with* by the player).
* **Signals Needed:** Custom signals: `laser_enabled`, `laser_disabled`.
* **Editor Organization:** Save as `res://obstacles/lasers/laser_barrier.tscn`.
* **Naming Conventions:** Root node `LaserBarrier`. Scripts: `laser_barrier.gd`.

### Implementation Details
* **Trigger Logic:** Driven externally by connected Floor Buttons, or internally by the `Timer` node (for timed variants).
* **State Management:** `@export var is_active: bool = true`. When toggled, enable/disable the `CollisionShape2D` (using `set_deferred("disabled", true/false)`) and change visibility.
* **TileMap Integration:** Do not bake dynamic lasers into TileMaps. Place them as instanced scenes over the TileMap. You can use a dedicated `TileMapLayer` purely for visual "laser emitters" attached to the walls.
* **Interactions:** Because the player's mask includes `Obstacles` (6) but the box's mask does not, the laser will natively block the player while letting boxes slide right through.
* **Animation Requirements:** `activate` (beam expands/fades in), `deactivate` (beam shrinks/fades out), `idle` (pulsing glow).
* **Modularity Setup:** Create a base `laser_barrier.gd` script. Extend it for `timed_laser.gd` to handle interval toggling.
* **Multiple Triggers:** If one laser requires multiple buttons to turn off, give the laser an internal integer `activation_requirements` and a `current_activations` counter. Only disable the laser when `current_activations >= activation_requirements`.
* **Fail-safe/Reset Behavior:** In the `_ready()` function, strictly snap the initial collision state to the exported `is_active` boolean to prevent editor/runtime desyncs.

### Testing & Polish
* **Debug/Testing Checklist:**
    * [ ] Verify player cannot dash or clip through the laser at high speeds (enable Continuous CD on player if necessary).
    * [ ] Verify pushing a box through the active laser works smoothly.
    * [ ] Verify pressing multiple connected buttons correctly updates the laser's logic counter.
* **Edge Cases:** The player stands inside the disabled laser zone, and the box is removed from the button. The laser reactivates inside the player. *Solution:* Add an `Area2D` to the laser. Prevent reactivation if the player is overlapping, or immediately push the player out using a knockback vector.
* **Polish Features:** Add CPUParticles2D at the contact points of the laser emitter. Add a `PointLight2D` that matches the laser color and fades in/out with the beam.

---

## System 3: Doors (Physical Gates)

Doors act as physical barriers that open dynamically via triggers. 

### Core Setup
* **Required Nodes:** `AnimatableBody2D` (Root) -> `Sprite2D` (Visual) -> `CollisionShape2D` (Blocker) -> `AnimationPlayer` (Movement/Fading).
* **Why AnimatableBody2D?:** In Godot 4, `AnimatableBody2D` is the standard for moving platforms and sliding doors because it properly pushes/carries physics bodies (like the player) without physics jitter.
* **Collision Setup:** Matches the closed door sprite.
* **Physics Layer/Mask:** Layer = `Obstacles` (6). Mask = None.
* **Signals Needed:** `door_opened`, `door_closed`.
* **Editor Organization:** Save as `res://obstacles/doors/sliding_door.tscn`.
* **Naming Conventions:** Root node `Door`. Animations: `open`, `close`.

### Implementation Details
* **Trigger Logic:** Responds to a public `open_door()` and `close_door()` function called by Floor Buttons.
* **State Management:** Enum state: `CLOSED`, `OPENING`, `OPEN`, `CLOSING`. Track locked/unlocked logic via `@export var requires_key: bool`.
* **TileMap Integration:** Doors should be placed via the editor precisely between TileMap wall tiles. Ensure the door's collision perfectly aligns with the TileMap grid to prevent snagging.
* **Interactions:** Blocks both player and interactable boxes. 
* **Animation Requirements:** Use the `AnimationPlayer` to animate the `position` property of the Sprite and CollisionShape (for sliding doors) or the `modulate.a` (alpha) property (for disappearing doors).
* **Modularity Setup:** Create a master `DoorController` component (Node) that can be attached to different visual door scenes, keeping the logic separate from the visuals.
* **Multiple Triggers:** Similar to lasers, use an array of dependencies. If an AND logic gate is required (both buttons must be pressed), the door checks the status of all connected buttons before opening.

### Testing & Polish
* **Debug/Testing Checklist:**
    * [ ] Verify door fully blocks player and boxes when closed.
    * [ ] Verify the player is not crushed incorrectly if standing under a closing door (ensure safe push-out logic).
    * [ ] Verify rapid stepping on/off a button doesn't break the animation state machine.
* **Edge Cases:** Sliding doors pushing the player out of bounds. *Solution:* Ensure the `AnimatableBody2D` syncs with physics correctly, and world walls have thick collision shapes so the player cannot be squeezed through them.
* **Best Practices (Godot 4.6.2):** Drive sliding door movement strictly through `AnimationPlayer` using the `Physics` process mode setting, rather than modifying transforms in `_process`.
* **Polish Features:** Screen shake on heavy doors closing. Dust particles emitting from the floor when the door slams shut.

---

## System 4: Spikes (Fatal Hazards)

Spikes are static or timed objects that trigger a death state instantly upon player contact.

### Core Setup
* **Required Nodes:** `Area2D` (Root) -> `Sprite2D` (Visual) -> `CollisionPolygon2D` (Hitbox) -> `Timer` (For timed variants).
* **Collision Setup:** Use `CollisionPolygon2D` to trace the exact shape of the spikes. **Crucial:** Make the hitbox slightly smaller than the visual sprite to prevent frustrating "cheap" deaths where the player grazes the very edge.
* **Physics Layer/Mask:** Layer = `Hazards` (5). Mask = `Player` (1).
* **Signals Needed:** `body_entered` (from the Area2D).
* **Editor Organization:** Save as `res://obstacles/hazards/spikes.tscn`.
* **Naming Conventions:** Root node `Spikes` or `SpikeTrap`.

### Implementation Details
* **Trigger Logic:** The `body_entered` signal directly calls a `die()` or `take_fatal_damage()` method on the detected player body.
* **State Management:** For static spikes, no state is needed. For timed spikes, toggle an `is_lethal` boolean and disable/enable the monitoring property of the `Area2D`.
* **TileMap Integration:** * *Method A (Static):* Paint static spikes directly using a dedicated `TileMapLayer` (Hazards). Assign the `Hazards` physics layer in the TileSet physics properties.
    * *Method B (Timed/Dynamic):* Place them as instanced scenes.
* **Interactions:** Spikes should completely ignore interactable boxes. Boxes can safely rest on top of spikes.
* **Animation Requirements:** For timed spikes: `emerge` (thrust upward), `retract` (pull back). 

### Testing & Polish
* **Debug/Testing Checklist:**
    * [ ] Verify exact pixel collision (player doesn't die when walking strictly next to the spike).
    * [ ] Verify respawn logic triggers properly and does not leave the player stuck in a death loop inside the spike's Area2D.
    * [ ] Verify boxes do not trigger the spikes or get destroyed by them.
* **Edge Cases:** The player spawns directly on a spike. *Solution:* Implement a brief frame-invulnerability timer on the player upon respawn, or ensure checkpoint locations are validated against hazard coordinates.
* **Safe Collision Practices:** Never use standard static bodies for spikes. Always use Area2D. Static bodies will stop the player's momentum, whereas Area2D allows the death animation/momentum to carry through naturally.
* **Polish Features:** Visual telegraphing for timed spikes (e.g., small dust clouds or a mechanical clicking visual 0.5 seconds before they thrust upward). Add a subtle red glint animation to static spikes to draw the player's eye.

all implementations must be inside sorted inside one folder and must be located inside main.