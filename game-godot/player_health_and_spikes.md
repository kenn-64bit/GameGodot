# Player Health System & Spike Damage — Implementation Guide

---

## Overview

The player has a **3-life system** displayed in the top-left HUD. Lives are hard-placed directly in the GUI scene (no dynamic instancing). When the player takes damage, the corresponding heart icon swaps to a greyed-out version. Spikes (under the `Hazards/` folder) are the first obstacle type wired to deal damage.

---

## 1. Player GUI — Heart Display

### Structure
The GUI scene contains exactly **3 heart nodes**, placed statically in the top-left. Each heart is a `TextureRect` (or `Sprite2D`) with two states:

| State | Texture |
|---|---|
| Full | `heart_full.png` (colored version) |
| Empty | `heart_grey.png` (greyed-out version) |

### Suggested Node Layout
```
CanvasLayer (PlayerGUI)
└── HBoxContainer
    ├── Heart1 (TextureRect)
    ├── Heart2 (TextureRect)
    └── Heart3 (TextureRect)
```

### GUI Script (`player_gui.gd`)
```gdscript
extends CanvasLayer

@onready var hearts: Array[TextureRect] = [
    $HBoxContainer/Heart1,
    $HBoxContainer/Heart2,
    $HBoxContainer/Heart3,
]

@export var texture_full: Texture2D
@export var texture_grey: Texture2D

func update_hearts(current_lives: int) -> void:
    for i in hearts.size():
        if i < current_lives:
            hearts[i].texture = texture_full
        else:
            hearts[i].texture = texture_grey
```

- Assign `texture_full` and `texture_grey` in the Inspector.
- Call `update_hearts(lives)` whenever the player's life count changes.

---

## 2. Player — Health & Damage Logic

### Player Variables
```gdscript
const MAX_LIVES = 3
var lives: int = MAX_LIVES

@onready var gui: CanvasLayer = $PlayerGUI  # or get via autoload
```

### Taking Damage
```gdscript
func take_damage() -> void:
    lives -= 1
    gui.update_hearts(lives)

    if lives <= 0:
        die()

func die() -> void:
    # Handle player death (respawn, game over screen, etc.)
    pass
```

> **Note:** Add invincibility frames (i-frames) here if needed to prevent multiple hits per contact.

---

## 3. Spike Obstacle — Dealing Damage

The `Hazards/spikes.tscn` scene must detect player entry and call `take_damage()`.

### Required Node Setup in `spikes.tscn`
- Add an **`Area2D`** node to the spike scene (if not already present).
- Add a **`CollisionShape2D`** child to the `Area2D` matching the spike hitbox.
- Set the `Area2D`'s **collision layer/mask** so it detects the Player layer.

### `spikes.gd`
```gdscript
extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage()
```

Connect the signal in the scene:
- Select the `Area2D` node → **Node** tab → `body_entered` signal → connect to `spikes.gd` → `_on_area_2d_body_entered`.

---

## 4. Collision Layers — Recommended Setup

| Layer | Name | Used By |
|---|---|---|
| 1 | `world` | Tilemaps, static geometry |
| 2 | `player` | Player body |
| 3 | `hazards` | Spikes, and future hazards |

- **Player `CharacterBody2D`:** Layer = `player`, Mask = `world` + `hazards`
- **Spike `Area2D`:** Layer = `hazards`, Mask = `player`

---

## 5. File Checklist

```
res://
├── GUI/
│   ├── player_gui.tscn        ← CanvasLayer with 3 static heart nodes
│   └── player_gui.gd          ← update_hearts(current_lives) method
├── Player/
│   └── player.gd              ← lives var, take_damage(), die()
└── Obstacles/
    └── Hazards/
        ├── spikes.tscn         ← Area2D + CollisionShape2D added
        └── spikes.gd           ← body_entered → take_damage()
```

---

## 6. Summary of Connections

```
Spike Area2D
  └── body_entered signal
        └── calls body.take_damage()
              └── player.lives -= 1
                    └── gui.update_hearts(lives)
                          └── swaps heart textures full → grey
```
