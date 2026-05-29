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
## Tracks which bodies are currently pressing the button.
var _pressing_bodies: Array[Node] = []

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()


func _on_body_entered(body: Node2D) -> void:
	# Only count physics bodies that are on the ground (not a held cube floating in air).
	if _is_valid_presser(body):
		if not _pressing_bodies.has(body):
			_pressing_bodies.append(body)
		_evaluate_state()


func _on_body_exited(body: Node2D) -> void:
	_pressing_bodies.erase(body)
	_evaluate_state()


## Returns true if this body should count as pressing the button.
func _is_valid_presser(body: Node2D) -> bool:
	# Player always counts.
	if body.is_in_group("player"):
		return true
	# GrabbableCube counts ONLY when not held (dropped/resting on button).
	if body is GrabbableCube:
		return not body.is_held
	# Any other physics body on the correct layers counts.
	return body is CharacterBody2D or body is RigidBody2D


func _evaluate_state() -> void:
	# Clean up any bodies that are now held (picked back up mid-press).
	_pressing_bodies = _pressing_bodies.filter(func(b): return is_instance_valid(b) and _is_valid_presser(b))

	var should_be_pressed := _pressing_bodies.size() > 0

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
