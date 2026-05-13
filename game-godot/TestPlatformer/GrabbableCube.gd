extends RigidBody2D
class_name GrabbableCube

# =============================================================================
#  GrabbableCube.gd  –  Physics object that can be grabbed / dropped / thrown
#  Godot 4.6.2
#
#  Scene requirements:
#    - RigidBody2D root (collision_layer = 2, collision_mask = 3)
#    - CollisionShape2D child
#    - Sprite2D child (optional, for visuals)
#  The node must be in the "Grabbable" group (set in the scene or in _ready).
# =============================================================================

## Whether this object is currently being held.
var is_held   : bool   = false

## The node that is holding this object (CharacterBody2D player).
var holder    : Node2D = null

## World-space target the object should hover toward when held.
var _hold_target : Vector2 = Vector2.ZERO

## How fast the cube tracks the hold point (higher = snappier).
const FOLLOW_SPEED : float = 18.0

## Throw impulse multiplier applied on drop when the holder is moving.
const THROW_MULTIPLIER : float = 1.5

# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("Grabbable")


func _physics_process(_delta: float) -> void:
	if is_held and holder:
		# Drive toward the hold point via velocity (avoids tunnelling).
		var to_target : Vector2 = _hold_target - global_position
		linear_velocity = to_target * FOLLOW_SPEED
		# Suppress rotation while held so it doesn't spin wildly.
		angular_velocity = move_toward(angular_velocity, 0.0, 30.0)


# ---------------------------------------------------------------------------
## Called by the player to grab this object.
func grab(by: Node2D) -> void:
	is_held    = true
	holder     = by
	# Keep physics active so velocity-steering works, but kill gravity.
	gravity_scale = 0.0
	freeze        = false
	# Stop any existing spin immediately.
	angular_velocity = 0.0
	# Disable collision with the player (layer 1) to avoid push-back.
	set_collision_mask_value(1, false)


## Called by the player when dropping or throwing.
func drop() -> void:
	# Give a small inherited throw velocity from the holder's movement.
	if holder and holder is CharacterBody2D:
		var holder_vel : Vector2 = (holder as CharacterBody2D).velocity
		linear_velocity = holder_vel * THROW_MULTIPLIER

	is_held       = false
	holder        = null
	gravity_scale = 1.0
	# Re-enable collision with the player.
	set_collision_mask_value(1, true)


## Called every frame by the holder to update where the cube should float.
func update_hold_position(target_pos: Vector2) -> void:
	_hold_target = target_pos
