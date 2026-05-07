extends Area2D

# Reference the sprite which is a sibling to this Area2D
@onready var door_sprite = $"../AnimatedSprite2D"

func _on_body_entered(body):
	# Check if the body entering is the player
	if body.name == "Player" or body.is_in_group("player"):
		door_sprite.play("open")

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		door_sprite.play_backwards("open")
