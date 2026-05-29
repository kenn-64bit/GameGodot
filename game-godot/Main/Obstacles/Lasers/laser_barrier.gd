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
## AnimatedSprite2D — the obstacle's visual, always visible, never hidden.
@onready var _sprite    : AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## Tracks which state the laser is settling into so the finished signal knows what to do next.
var _pending_state: StringName = &""


func _ready() -> void:
	_collision.set_deferred("disabled", !is_active)

	if _sprite and _sprite.sprite_frames:
		_sprite.visible = true
		_sprite.animation_finished.connect(_on_sprite_anim_finished)

		if is_active:
			# Jump directly to the last frame of idle — no animation plays on startup.
			# Activation animation only plays when triggered at runtime.
			var anim := &"idle"
			if _sprite.sprite_frames.has_animation(anim):
				_sprite.animation = anim
				_sprite.frame = _sprite.sprite_frames.get_frame_count(anim) - 1
				_sprite.stop()
		else:
			# Jump to the last frame of deactivate — laser starts off, no animation.
			var anim := &"deactivate"
			if _sprite.sprite_frames.has_animation(anim):
				_sprite.animation = anim
				_sprite.frame = _sprite.sprite_frames.get_frame_count(anim) - 1
				_sprite.stop()
				_sprite.visible = false

	if _beam:
		_beam.visible = is_active
		_beam.modulate = Color(0.2, 0.9, 1.0, 0.85) if is_active else Color(1, 1, 1, 0)


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
	_collision.set_deferred("disabled", !active)

	if active:
		if _sprite:
			_sprite.visible = true
		laser_enabled.emit()
		# Turning ON: play activate once → then play idle once → freeze.
		_pending_state = &"activate_to_idle"
		_safe_play(&"activate")
		_set_beam_visible(true)
	else:
		laser_disabled.emit()
		# Turning OFF: play deactivate once → freeze on last frame.
		_pending_state = &"off_done"
		_safe_play(&"deactivate")
		_set_beam_visible(false)


## Plays an animation only if the SpriteFrames resource has it.
func _safe_play(anim_name: StringName) -> void:
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		_sprite.play(anim_name)


func _on_sprite_anim_finished() -> void:
	match _pending_state:
		&"activate_to_idle":
			# activate finished → play idle once → freeze.
			_pending_state = &"idle_done"
			_safe_play(&"idle")

		&"idle_done":
			# idle finished → freeze on last frame (laser stays ON, no more playing).
			_sprite.stop()

		&"off_done":
			# deactivate finished → freeze on last frame (laser stays OFF).
			_sprite.stop()
			_sprite.visible = false


func _set_beam_visible(visible_state: bool) -> void:
	if _beam:
		_beam.visible = visible_state
		_beam.modulate = Color(0.2, 0.9, 1.0, 0.85) if visible_state else Color(1, 1, 1, 0)
