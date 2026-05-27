class_name LaserBarrier
extends StaticBody2D

## Emitted when the laser becomes active (blocking).
signal laser_enabled
## Emitted when the laser becomes inactive (passable).
signal laser_disabled

## Initial state set in the editor.
@export var is_active: bool = true

## For multi-button logic: how many buttons must be pressed to disable the laser.
@export var activation_requirements: int = 1
var current_activations: int = 0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _beam: ColorRect = $Beam
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Snap collision state to the exported flag — prevents editor/runtime desyncs.
	_apply_state(is_active)


## Called by FloorButton (or any external trigger).
func set_active(value: bool) -> void:
	if value:
		current_activations += 1
	else:
		current_activations = max(0, current_activations - 1)

	var should_be_active := current_activations < activation_requirements
	if should_be_active == is_active:
		return

	is_active = should_be_active
	_apply_state(is_active)


## Toggle helper (for timed variants or direct calls).
func toggle_state() -> void:
	set_active(!is_active)


func _apply_state(active: bool) -> void:
	# Use set_deferred so collision changes happen safely mid-physics frame.
	_collision.set_deferred("disabled", !active)

	if active:
		laser_enabled.emit()
		if _anim and _anim.has_animation("activate"):
			_anim.play("activate")
		else:
			_set_beam_visible(true)
	else:
		laser_disabled.emit()
		if _anim and _anim.has_animation("deactivate"):
			_anim.play("deactivate")
		else:
			_set_beam_visible(false)


func _set_beam_visible(visible: bool) -> void:
	if _beam:
		_beam.visible = visible
		_beam.modulate = Color(0.2, 0.9, 1.0, 0.85) if visible else Color(1, 1, 1, 0)
