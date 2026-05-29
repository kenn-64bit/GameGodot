class_name TimedLaser
extends LaserBarrier

## Time in seconds the laser stays ON.
## Set to 0 to disable self-cycling (floor-button-only mode).
@export var on_duration: float = 0.0
## Time in seconds the laser stays OFF.
@export var off_duration: float = 0.0
## If true, laser starts in the ON state.
@export var start_active: bool = true

@onready var _timer: Timer = $Timer


func _ready() -> void:
	super._ready()  # Snap initial state first.
	# Only self-cycle if on_duration is set. Zero = floor-button-only.
	if on_duration > 0.0:
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
