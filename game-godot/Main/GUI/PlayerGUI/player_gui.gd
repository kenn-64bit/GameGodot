extends Control

@export var player: CharacterBody2D

## Heart textures — assign both in the Inspector.
@export var texture_full : Texture2D
@export var texture_grey : Texture2D

@onready var hearts : Array[TextureRect] = [
	$HBoxContainer/Heart1,
	$HBoxContainer/Heart2,
	$HBoxContainer/Heart3,
]

## Called by the player whenever lives change.
## current_lives = number of hearts still full (0–3).
func update_hearts(current_lives: int) -> void:
	for i in hearts.size():
		if i < current_lives:
			hearts[i].texture = texture_full
		else:
			hearts[i].texture = texture_grey

## Shows or hides the gun icon in the bottom right corner.
func set_gun_icon_visible(visible_state: bool) -> void:
	if has_node("HBoxContainer2"):
		$HBoxContainer2.visible = visible_state
