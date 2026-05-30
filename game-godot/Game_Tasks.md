# Game Development Task Board

## 🐛 Bug Fixes
- [x] **Pause Menu Routing:** Fix the in-game pause menu 'Exit' button. It must route to the Main Menu rather than triggering the endgame sequence.

## ✨ Visuals & Mechanics
- [x] **Damage Feedback:** Implement a red screen flash visual effect when the player takes damage.

## 🔊 Audio & SFX
- [x] **Locomotion:** Add walking/footstep SFX.
- [x] **Portal Mechanics:** Add SFX for firing the portal gun and the subsequent portal spawning.
- [x] **Hazards:** Add mechanical/energy SFX for timed lasers (distinct sounds for turning ON and turning OFF).
- [x] **Player State:** Add player damage/hurt SFX.
- [x] **Environment:** Add door opening SFX.
- [x] **UI/UX:** Add UI click SFX for GUI buttons (Main Menu, Pause Menu).
- [x] **Music:** Implement a background theme song system that automatically shuffles through tracks.
- [x] **Audio Systems Backend:**
    - [x] Add an SFX handler/manager to track active sounds, prevent overlapping/looping bugs, and ensure seamless playback.
    - [x] Normalize audio across all sound assets to ensure consistent volume levels throughout the game.
- [x] Refer to SFX inside assets for files

## 🖱️ GUI & Cursor Contexts
*Note: All cursor assets should be sourced from the `Cursor-PNG` directory.*
- [x] **Default Game Cursor:** Use `pointer_b_shaded` for the general game state.
- [x] **Interactable Cubes:** Switch to `hand_open` when hovering over puzzle cubes.
- [x] **Doors:** Switch to `door_enter` when hovering over doorways.
- [x] **GUI Buttons:** Switch to `hand_point` when hovering over clickable interface buttons.
