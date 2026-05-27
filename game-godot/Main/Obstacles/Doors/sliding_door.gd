class_name SlidingDoor
extends AnimatableBody2D

## Emitted when the door finishes opening.
signal door_opened
## Emitted when the door finishes closing.
signal door_closed

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }

## If true, opening requires a key item in addition to button triggers.
@export var requires_key: bool = false

## AND gate logic: how many connected buttons must be active simultaneously.
@export var activation_requirements: int = 1
var _activation_count: int = 0

var _state: DoorState = DoorState.CLOSED

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if _anim:
		_anim.animation_finished.connect(_on_animation_finished)
	# Start in closed state.
	_state = DoorState.CLOSED


# --- Public API (called by FloorButton) ---

func set_active(value: bool) -> void:
	if value:
		_activation_count += 1
	else:
		_activation_count = max(0, _activation_count - 1)

	if _activation_count >= activation_requirements:
		open_door()
	else:
		close_door()


func toggle_state() -> void:
	if _state == DoorState.CLOSED or _state == DoorState.CLOSING:
		open_door()
	else:
		close_door()


func open_door() -> void:
	if requires_key:
		# Future: check inventory for key item here.
		pass

	if _state == DoorState.OPEN or _state == DoorState.OPENING:
		return

	_state = DoorState.OPENING
	if _anim and _anim.has_animation("open"):
		_anim.play("open")
	else:
		# Fallback: instantly disable collision and hide.
		_collision.set_deferred("disabled", true)
		visible = false
		_state = DoorState.OPEN
		door_opened.emit()


func close_door() -> void:
	if _state == DoorState.CLOSED or _state == DoorState.CLOSING:
		return

	_state = DoorState.CLOSING
	if _anim and _anim.has_animation("close"):
		_anim.play("close")
	else:
		# Fallback: instantly enable collision and show.
		_collision.set_deferred("disabled", false)
		visible = true
		_state = DoorState.CLOSED
		door_closed.emit()


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"open":
			_state = DoorState.OPEN
			_collision.set_deferred("disabled", true)
			door_opened.emit()
		&"close":
			_state = DoorState.CLOSED
			_collision.set_deferred("disabled", false)
			door_closed.emit()
