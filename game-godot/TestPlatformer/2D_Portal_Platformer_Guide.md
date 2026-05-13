# 2D Portal Gun & Object Manipulation - Game Design & Implementation Blueprint

This document serves as a comprehensive Game Design Document (GDD) and technical blueprint for a 2D game focused entirely on Portal Gun mechanics and object manipulation. You can use the structured prompts at the end of this document to feed into an AI to generate specific scripts for Godot 4.6.2.

---

## 1. Core Concept & Overview
* **Genre:** 2D Physics & Puzzle Mechanics
* **Core Loop:** Solve environmental puzzles by manipulating physics objects (like cubes), utilizing interconnected portals, and retrieving/transporting items using the Portal Gun's zero-point energy field.
* **Primary Tools:** * **Portal Gun (Left/Right Click):** Shoots the "Entry" (Blue) and "Exit" (Orange) portals.
    * **Object Manipulation (Interact Key - e.g., 'E'):** Picks up, holds, and drops physics objects.
    * **Weapon Management (Toggle Key - e.g., 'Q'):** Equips and unequips the Portal Gun, shifting the player between unarmed and armed states.

---

## 2. Mechanics Breakdown

### A. Object Manipulation & Pickup
* **Standard Close-Range Pickup:** When pressing the Interact key, a short-distance overlap circle or raycast checks for objects in the "Grabbable" group (like a companion cube). If detected, the object is picked up.
* **Portal Gun Retrieval:** The Portal Gun acts as a gravity manipulator. 
    * **Holding State:** When an object is picked up, its physics state is temporarily altered (e.g., set to freeze rotation, or attached via a `PinJoint2D` or `DampedSpringJoint2D`) so it hovers at a fixed distance from the gun barrel, following the mouse's aiming rotation.
    * **Dropping/Throwing:** Pressing the Interact key again drops the object, restoring its standard physics (gravity and collision).

### B. Aiming and Shooting (Portals)
* **Mouse Tracking:** The player's arm/gun should continuously rotate to face the mouse cursor on the screen.
* **Raycasting:** When LMB or RMB is clicked, the game fires a 2D Raycast (`RayCast2D` or PhysicsServer space state query) from the gun barrel towards the mouse position.
* **Surface Validation:** The raycast checks the collision layer/mask of the hit object. 
    * *Valid Surface:* Spawns or moves the respective portal.
    * *Invalid Surface (e.g., metal, glass):* Spawns a fizzle particle effect; no portal is placed.

### C. Portal Placement Logic
* **Orientation:** The portal must align itself with the normal (the perpendicular direction) of the surface it hits. If it hits a floor, it faces up. If it hits a right wall, it faces left.
* **Overlap Prevention:** If Portal A is shot too close to Portal B, it should either nudge Portal B out of the way or fizzle out.
* **Bounds Checking:** Portals cannot overhang corners. The spawn logic must check if the flat surface is wide/tall enough to hold the portal sprite/collision shape.

### D. Picking Up Objects *Through* Portals (Advanced)
* **Cross-Portal Raycasting:** If the player targets an object through a portal, the Interact raycast must hit the Entrance Portal, calculate the remaining ray distance, and seamlessly fire a secondary ray out of the Exit Portal to detect the object.
* **Teleporting the Grabbed Object:** Once grabbed through a portal, the object is instantly teleported through the portal network and snapped to the player's holding position.

### E. Teleportation & Momentum Physics (For Objects)
When a `RigidBody2D` (like a dropped cube) touches a Portal:
1. **Check Link:** Does the other portal exist? If not, act as a solid wall.
2. **Calculate Exit Position:** Move the object to the center of the Exit Portal, plus a small offset in the direction of the Exit Portal's normal to prevent getting stuck in the wall.
3. **Calculate Exit Velocity:**
    * Calculate the object's incoming velocity (`linear_velocity`) magnitude.
    * Rotate the velocity vector based on the angle difference between the Entrance and Exit portal normals.
    * *Example:* A cube falling straight down into a floor portal (Velocity: `[0, 500]`). Exit portal is on a right wall (Normal faces Left). New velocity becomes `[-500, 0]` (Shooting out to the left).

### F. Equipping & Unequipping the Portal Gun
* **State Management:** The player controller utilizes a state variable (e.g., `is_gun_equipped`) to track whether the portal gun is currently active and drawn.
* **Visual Feedback:** When equipped, the gun sprite or player arm becomes visible and actively tracks the mouse cursor. When unequipped, the gun sprite is hidden or lowered to a resting position.
* **Input Handling:** Pressing the toggle key flips the equipped state. When unequipped, portal shooting inputs (LMB/RMB) and gun rotation logic are completely ignored. Object pickup (Interact) can still function independently of the gun for close-range items, but advanced features like picking up objects through portals are disabled.

---

## 3. Visual & Edge Case Challenges (To Keep in Mind)

* **Seamless Rendering:** In a true portal game, you can see through the portal. In 2D, this is usually achieved by using a secondary `Camera2D` at the Exit Portal's location that renders its view to a `SubViewport`, which is then applied as a texture to the Entrance Portal.
* **Clipping:** As an object enters a portal, half of its sprite is in one place, and half is in the other. You may need a "clone" sprite that renders at the exit portal while the main object is still moving through the entrance.
* **Mass & Physics Joints:** When holding an object with the portal gun, rapidly swinging the mouse can cause physics glitches if the object collides with a wall. Consider disabling object collision with the player while held, or using heavy damping.

---

## 4. Prompts for Code Generation

*Copy and paste these prompts individually into your AI assistant to build your mechanics step-by-step for Godot 4.6.2.*

### Prompt 1: Gun Aiming
> "Write a 2D script for Godot 4.6.2 using GDScript where a `Node2D` (a gun arm) rotates to point towards the global mouse position. It should work regardless of where the camera is positioned."

### Prompt 2: Portal Shooting & Validation
> "Write a 2D raycasting script for Godot 4.6.2. On Left Mouse Click, fire a ray towards the mouse using the PhysicsDirectSpaceState2D. If it hits a collider on the collision layer 'PortalWall', instantiate a 'PortalPrefabA' scene at the hit point, aligned with the hit surface's normal. Do the same for Right Click and 'PortalPrefabB'."

### Prompt 3: Basic Object Pickup System
> "Write a GDScript for Godot 4.6.2 to pick up and hold physics objects. When the player presses the 'interact' action, cast a ray towards the mouse. If it hits a `RigidBody2D` in the group 'Grabbable', attach it to a designated `Marker2D` (HoldPoint) in front of the gun. The object should smoothly follow the HoldPoint (perhaps using a `DampedSpringJoint2D` or velocity manipulation). Pressing 'interact' again should drop it and restore its normal physics state."

### Prompt 4: The Teleportation Math (Rigidbodies)
> "I need a 2D teleportation GDScript for Godot 4.6.2. When a `RigidBody2D` enters an `Area2D` (Portal A), teleport its `global_position` to the `global_position` of Portal B. Crucially, I need the math to preserve its incoming `linear_velocity` magnitude, but redirect its velocity vector based on the rotation difference between Portal A and Portal B."

### Prompt 5: Picking Up Objects Through Portals
> "I need to update my 2D interaction raycast in Godot 4.6.2. If the raycast from my gun hits a 'Portal' `Area2D` instead of a physics object, I need it to calculate the remaining distance of the ray, and fire a *new* space state raycast out of the linked Portal's position and rotation. If *that* secondary raycast hits a 'Grabbable' `RigidBody2D`, trigger the remote pickup and teleport logic."

### Prompt 6: Equip and Unequip System
> "Write a GDScript for Godot 4.6.2 to handle equipping and unequipping a weapon. Create a toggle system mapped to an 'equip_toggle' input action. When unequipped, hide the gun's `Sprite2D`, disable the aiming logic (mouse tracking), and ignore 'shoot_portal' inputs. When equipped, make the sprite visible and re-enable aiming and shooting. Include a quick tween for the gun scaling or sliding up/down to make the transition smooth."