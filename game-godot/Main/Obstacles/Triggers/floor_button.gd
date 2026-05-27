class_name FloorButton
extends Area2D

## Emitted when the button transitions from unpressed → pressed.
signal activated
## Emitted when the button transitions from pressed → unpressed.
signal deactivated

## Link one button to multiple doors / lasers in the editor.
@export var target_obstacles: Array[Node] = []

# --- State ---
var is_pressed: bool = false
var _body_count: int = 0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _on_body_entered(_body: Node2D) -> void:
	_body_count += 1
	_evaluate_state()


func _on_body_exited(_body: Node2D) -> void:
	_body_count = max(0, _body_count - 1)
	_evaluate_state()


func _evaluate_state() -> void:
	var should_be_pressed := _body_count > 0

	if should_be_pressed == is_pressed:
		return  # No change.

	is_pressed = should_be_pressed

	if is_pressed:
		activated.emit()
		_notify_obstacles(true)
	else:
		deactivated.emit()
		_notify_obstacles(false)

	_update_visuals()


func _notify_obstacles(active: bool) -> void:
	for obstacle in target_obstacles:
		if obstacle == null:
			continue
		if obstacle.has_method("set_active"):
			obstacle.set_active(active)


func _update_visuals() -> void:
	if _sprite == null:
		return
	# Pressed: yellow-gold tint. Released: white.
	_sprite.modulate = Color(1.0, 0.85, 0.1) if is_pressed else Color(1, 1, 1)
