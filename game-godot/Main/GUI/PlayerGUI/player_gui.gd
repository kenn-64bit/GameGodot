extends Control

@export var player: CharacterBody2D

@export var bob_amount : float = 2.0
@export var bob_speed  : float = 12.0

## Heart textures — assign both in the Inspector.
@export var texture_full : Texture2D
@export var texture_grey : Texture2D

@onready var hearts : Array[TextureRect] = [
	$HBoxContainer/Heart1,
	$HBoxContainer/Heart2,
	$HBoxContainer/Heart3,
]

var default_y      : float
var vertical_offset: float = 0.0

func _ready() -> void:
	default_y = position.y

func _process(delta: float) -> void:
	# HUD bob while the player is moving.
	if player and player.velocity.length() > 0:
		vertical_offset += delta * bob_speed
		var bob := sin(vertical_offset) * bob_amount
		position.y = default_y + bob
	else:
		position.y = lerp(position.y, default_y, 10 * delta)
		vertical_offset = 0

## Called by the player whenever lives change.
## current_lives = number of hearts still full (0–3).
func update_hearts(current_lives: int) -> void:
	for i in hearts.size():
		if i < current_lives:
			hearts[i].texture = texture_full
		else:
			hearts[i].texture = texture_grey
