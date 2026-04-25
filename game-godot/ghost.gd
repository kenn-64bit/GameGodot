extends Sprite2D

func _ready():
	var tween = get_tree().create_tween()
	# Increase the 0.4 to a higher number if you want the trail to stay longer
	tween.tween_property(self, "self_modulate:a", 0.0, 0.2) 
	tween.finished.connect(queue_free)
