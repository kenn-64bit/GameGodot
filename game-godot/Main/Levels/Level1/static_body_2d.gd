extends StaticBody2D

@onready var sprite = $AnimatedSprite2D

func _on_area_2d_body_entered(body):
	# Only trigger if the entering body is the player
	if body.is_in_group("player"):
		# Play the 'open' animation forward
		sprite.play("open")

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		# Play the 'open' animation backwards to close it
		sprite.play("open", -1.0, true)
