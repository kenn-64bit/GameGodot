# Godot 4.x: Smooth GUI Wobble Implementation Fix

When implementing a "wobble" or breathing effect on UI elements (like health icons) in a 2D pixel art game, the UI can often appear jittery, snap violently, or sway off-axis. 

This guide covers the three main culprits and provides a drop-in script for a buttery-smooth wobble.

## 1. The CanvasLayer (Fixing Camera Jitter)
If your UI jitters **only when the player/camera moves**, it is likely attached to the world space instead of the screen space.
* **Fix:** Ensure all your UI nodes (e.g., `Control`, `TextureRect`, `HBoxContainer`) are children of a `CanvasLayer` node. 
* Do **not** make the UI a child of the `Camera2D` or the `Player` node.

## 2. The Pivot Offset (Fixing the "Orbit" Sway)
By default, Godot `Control` nodes have their `pivot_offset` set to `(0, 0)` (the top-left corner). If you rotate the node, it will swing from the top-left, making it look like it's orbiting rather than wobbling in place.
* **Fix:** Set the pivot offset to the center of the UI element.
* You can do this in the Inspector under **Control > Transform > Pivot Offset**, or dynamically in your script (shown below).

## 3. The Script (Smooth Sine Wave)
Instead of using the AnimationPlayer (which can sometimes fight with pixel-snapping during sub-frames), use a simple sine wave in `_process()`.

Attach this script to your health icon (`TextureRect` or `Control` node):

```gdscript
extends Control

@export var wobble_speed: float = 5.0
@export var wobble_angle_degrees: float = 15.0

var _time_passed: float = 0.0
var _original_rotation: float

func _ready() -> void:
    # 1. Store the initial rotation in case it's not 0
    _original_rotation = rotation
    
    # 2. Automatically center the pivot point so it wobbles from the middle
    pivot_offset = size / 2.0

func _process(delta: float) -> void:
    _time_passed += delta
    
    # 3. Calculate the sine wave (returns a value between -1 and 1)
    var wave = sin(_time_passed * wobble_speed)
    
    # 4. Apply the rotation smoothly
    var angle_rad = deg_to_rad(wobble_angle_degrees)
    rotation = _original_rotation + (wave * angle_rad)