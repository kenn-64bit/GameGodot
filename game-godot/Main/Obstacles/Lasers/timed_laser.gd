class_name TimedLaser
extends LaserBarrier

## Time in seconds the laser stays ON.
@export var on_duration: float = 2.0
## Time in seconds the laser stays OFF.
@export var off_duration: float = 1.5
## If true, laser starts in the ON state and cycles from there.
@export var start_active: bool = true

@onready var _timer: Timer = $Timer


func _ready() -> void:
	super._ready()  # Snap initial state first.
	_timer.timeout.connect(_on_timer_timeout)
	_begin_cycle()


func _begin_cycle() -> void:
	is_active = start_active
	_apply_state(is_active)
	_timer.wait_time = on_duration if is_active else off_duration
	_timer.start()


func _on_timer_timeout() -> void:
	# Flip the state.
	is_active = !is_active
	_apply_state(is_active)
	_timer.wait_time = on_duration if is_active else off_duration
	_timer.start()
