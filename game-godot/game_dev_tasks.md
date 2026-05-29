# Game Development Task Tracker

## 🧊 Grabbable Cube Mechanics
* **[Fix]** Adjust the interaction area size for the grabbable cube to make grabbing more intuitive.
* **[Fix]** Resolve general physics clipping issues with the grabbable cube against world geometry.
* **[Fix]** Fix the bug where the grabbable cube fails to enter or pass through portals.
* **[Fix]** Resolve clipping errors and physics glitches that occur specifically when the cube is in the process of entering/transitioning through a portal.
* **[Feature]** Update the rendering/Z-sorting logic so the held cube appears behind the player, while ensuring its collider still properly interacts with the world physics.

## 🌀 Portal & Gun Logic
* **[Fix]** Add clipping detection to the portal gun; prevent it from firing a portal if the weapon model or barrel is clipping into a wall/geometry.
* **[Fix]** Implement placement validation to ensure portals cannot be shot onto or through invalid obstacles.
* **[Fix]** Add a spatial/surface area check to prevent portals from being spawned in gaps or areas too small to fit the portal's dimensions.

## 🏃‍♂️ Player Movement & Physics
* **[Fix]** Refine the "coyote time" grounded check. Fix the issue where standing on sharp-cornered blocks causes the player to incorrectly enter a floating state (likely requires adjusting the edge-detection raycasts or collider sizes).

## 🎨 UI, Canvas & Polish
* **[Feature]** Implement a dynamic parallax/wobble effect on the Canvas layer so the HUD smoothly reacts to and follows the player's movement (similar to the UI sway in *Hollow Knight*).
* **[Refactor/Fix]** Debug the old GUI wobble implementation, fix its current issues, and upgrade its interpolation for a smoother, improved visual experience.
