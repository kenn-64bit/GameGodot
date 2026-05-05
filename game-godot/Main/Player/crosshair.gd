extends Sprite2D

func _process(_delta):
	# This follows the mouse relative to the screen
	global_position = get_global_mouse_position()
