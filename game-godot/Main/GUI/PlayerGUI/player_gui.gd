extends Control

# Fix: Line 4 from your screenshot
@export var player: CharacterBody2D 

@export var bob_amount : float = 2.0
@export var bob_speed : float = 12.0

var default_y : float
var vertical_offset : float = 0.0

func _ready():
	# Store the starting Y position
	default_y = position.y

func _process(delta):
	# The 'if player' check ensures the game doesn't crash if 
	# you forgot to drag the player into the Inspector slot.
	if player and player.velocity.length() > 0:
		vertical_offset += delta * bob_speed
		var bob = sin(vertical_offset) * bob_amount
		position.y = default_y + bob
	else:
		# Return to original position when standing still
		position.y = lerp(position.y, default_y, 10 * delta)
		vertical_offset = 0
