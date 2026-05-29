extends CanvasLayer

## ── Movement-reactive wobble for the level border CanvasLayer ─────────────
## Reads the player's velocity each frame and applies a spring-damper offset
## to every TextureRect child so the rock borders sway against movement,
## giving a parallax / screen-shake-lite feel.

@export var player_path : NodePath = NodePath("") ## Assign in Inspector

## Spring physics
@export_group("Spring")
@export var spring_k        : float = 280.0   # stiffness
@export var spring_damping  : float = 18.0    # damping (higher = less bounce)

## How far each element can drift
@export_group("Limits")
@export var max_x_offset    : float = 18.0    # px horizontal sway
@export var max_y_offset    : float = 10.0    # px vertical bob
@export var max_rot_deg     : float = 0.6    # degrees tilt

## Velocity-to-displacement scale factors
@export_group("Sensitivity")
@export var vel_x_scale     : float = 0.010   # horizontal velocity → X sway
@export var vel_y_scale     : float = 0.006   # vertical velocity   → Y bob
@export var vel_x_rot_scale : float = 0.0035  # horizontal velocity → rotation
@export var landing_impulse : float = 12.0    # downward thump on landing
## How fast the velocity input blends when direction changes (seconds to settle).
## Higher = smoother left↔right transitions, lower = snappier response.
@export var vel_smooth_time : float = 0.05


# ── Internal state ────────────────────────────────────────────────────────
var _player        : CharacterBody2D = null
var _rects         : Array[TextureRect] = []
var _spring_pos    : Vector2 = Vector2.ZERO
var _spring_vel    : Vector2 = Vector2.ZERO
var _spring_rot    : float   = 0.0
var _spring_rot_vel: float   = 0.0
var _base_pos      : Array[Vector2] = []
var _base_rot      : Array[float]   = []
var _was_on_floor  : bool           = true
var _smooth_vel    : Vector2        = Vector2.ZERO  # low-pass filtered velocity



func _ready() -> void:
	# Collect all TextureRect children
	for child in get_children():
		if child is TextureRect:
			_rects.append(child)
			_base_pos.append(child.position)
			_base_rot.append(child.rotation)

	# Resolve player reference (try NodePath first, then group fallback)
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	if not _player:
		var group := get_tree().get_nodes_in_group("player")
		for node in group:
			if node is CharacterBody2D:
				_player = node
				break


func _process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		return

	var on_floor : bool  = _player.is_on_floor()
	var vel      : Vector2 = _player.velocity

	# ── Landing impulse ───────────────────────────────────────────────────
	if on_floor and not _was_on_floor:
		_spring_vel.y += landing_impulse
	_was_on_floor = on_floor

	# ── Smooth the raw velocity (exponential low-pass) ───────────────────
	# Prevents an instant target flip when the player reverses direction.
	var smooth_factor : float = 1.0 - exp(-delta / max(vel_smooth_time, 0.001))
	_smooth_vel = _smooth_vel.lerp(vel, smooth_factor)

	# ── Target: opposite to smoothed movement (camera-lag feel) ───────────
	var target_x   : float  = -_smooth_vel.x * vel_x_scale
	var target_y   : float  = -_smooth_vel.y * vel_y_scale
	var target_rot : float  = -_smooth_vel.x * vel_x_rot_scale


	# ── Spring-damper integration (semi-implicit Euler) ───────────────────
	var acc_x   := -spring_k * (_spring_pos.x - target_x) - spring_damping * _spring_vel.x
	_spring_vel.x   += acc_x * delta
	_spring_pos.x    = clampf(_spring_pos.x + _spring_vel.x * delta, -max_x_offset, max_x_offset)

	var acc_y   := -spring_k * (_spring_pos.y - target_y) - spring_damping * _spring_vel.y
	_spring_vel.y   += acc_y * delta
	_spring_pos.y    = clampf(_spring_pos.y + _spring_vel.y * delta, -max_y_offset, max_y_offset)

	var acc_rot := -spring_k * (_spring_rot - target_rot) - spring_damping * _spring_rot_vel
	_spring_rot_vel += acc_rot * delta
	_spring_rot = clampf(
		_spring_rot + _spring_rot_vel * delta,
		deg_to_rad(-max_rot_deg),
		deg_to_rad(max_rot_deg)
	)

	# ── Apply to every rect relative to its original transform ───────────
	for i in _rects.size():
		_rects[i].position = _base_pos[i] + _spring_pos
		_rects[i].rotation = _base_rot[i] + _spring_rot
