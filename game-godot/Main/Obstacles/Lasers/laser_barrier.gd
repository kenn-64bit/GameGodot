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

@onready var _collision : CollisionShape2D = $CollisionShape2D
## ColorRect beam — legacy fallback when no AnimatedSprite2D child is present.
@onready var _beam      : ColorRect        = $Beam if has_node("Beam") else null
## AnimatedSprite2D — preferred visual using the tilemap spritesheets.
@onready var _sprite    : AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null


func _ready() -> void:
	# Snap collision state to the exported flag — prevents editor/runtime desyncs.
	_apply_state(is_active)


## Called by FloorButton (or any external trigger) to activate/deactivate the laser.
## Pass true when a button is pressed, false when released.
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


## Direct toggle — used by timed variants or one-shot triggers.
func toggle_state() -> void:
	is_active = !is_active
	_apply_state(is_active)


func _apply_state(active: bool) -> void:
	# Defer collision changes so they happen safely outside the physics step.
	_collision.set_deferred("disabled", !active)

	if active:
		laser_enabled.emit()
		_play_anim(&"activate")
	else:
		laser_disabled.emit()
		_play_anim(&"deactivate")


## Plays a named animation on the AnimatedSprite2D if it exists and has the animation.
## Falls back to showing/hiding the legacy ColorRect beam.
func _play_anim(anim_name: StringName) -> void:
	if _sprite and _sprite.sprite_frames:
		if _sprite.sprite_frames.has_animation(anim_name):
			_sprite.play(anim_name)
			# After the one-shot transition, settle into the looping idle.
			if not _sprite.animation_finished.is_connected(_on_sprite_anim_finished):
				_sprite.animation_finished.connect(_on_sprite_anim_finished)
			return
	# Legacy ColorRect fallback.
	_set_beam_visible(anim_name == &"activate")


func _on_sprite_anim_finished() -> void:
	var current := _sprite.animation
	if current == &"activate" and _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")
	elif current == &"deactivate" and _sprite.sprite_frames.has_animation(&"idle_off"):
		_sprite.play(&"idle_off")


func _set_beam_visible(visible_state: bool) -> void:
	if _beam:
		_beam.visible = visible_state
		_beam.modulate = Color(0.2, 0.9, 1.0, 0.85) if visible_state else Color(1, 1, 1, 0)
