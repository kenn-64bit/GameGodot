class_name Spikes
extends Area2D

## For timed spikes: whether contact currently kills.
var is_lethal: bool = true

@onready var _timer: Timer = $Timer


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# If a Timer child exists, this is a timed spike — start cycling.
	if _timer:
		_timer.timeout.connect(_on_timer_timeout)
		_timer.start()


func _on_body_entered(body: Node2D) -> void:
	if not is_lethal:
		return

	# Only kill the player group.
	if not body.is_in_group("player"):
		return

	if body.has_method("die"):
		body.die()
	else:
		# Fallback: reload the scene.
		body.get_tree().reload_current_scene()


# --- Timed spike toggling ---

func _on_timer_timeout() -> void:
	is_lethal = !is_lethal
	# Disable/enable monitoring so area events pause while not lethal.
	monitoring = is_lethal
