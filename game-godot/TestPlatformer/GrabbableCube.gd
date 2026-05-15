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

## Maximum speed the cube can travel while being held.
## Keeps it from tunnelling through thin walls / floors.
const MAX_HOLD_SPEED : float = 600.0

# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("Grabbable")


func _physics_process(_delta: float) -> void:
	if is_held and holder:
		# Drive toward the hold point via velocity (avoids tunnelling).
		var to_target : Vector2 = _hold_target - global_position
		var raw_vel   : Vector2 = to_target * FOLLOW_SPEED
		# Clamp so the cube never travels fast enough to tunnel through walls.
		if raw_vel.length() > MAX_HOLD_SPEED:
			raw_vel = raw_vel.normalized() * MAX_HOLD_SPEED
		linear_velocity = raw_vel
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
## throw_vel: optional explicit throw velocity (from aim direction).
func drop(throw_vel: Vector2 = Vector2.ZERO) -> void:
	if throw_vel != Vector2.ZERO:
		# Thrown in a specific direction (e.g. toward a portal)
		linear_velocity = throw_vel
	else:
		# Bare-hands drop: zero velocity so the cube simply falls.
		linear_velocity = Vector2.ZERO

	is_held       = false
	holder        = null
	gravity_scale = 1.0
	# Re-enable collision with walls/floor immediately so the cube
	# doesn't clip through.  Portal detection uses Area2D signals
	# which work independently of body-vs-body collision.
	set_collision_mask_value(1, true)

	# Deferred portal scan: check if this cube was dropped directly inside
	# a portal's detection zone and trigger teleportation if so.
	call_deferred("_check_portal_overlap")


## Called every frame by the holder to update where the cube should float.
func update_hold_position(target_pos: Vector2) -> void:
	_hold_target = target_pos


# ---------------------------------------------------------------------------
## Scans all portals in the scene after a drop to catch the case where the
## player places the cube directly inside a portal's detection zone.
## (Portals are on collision_layer=0 so point queries cannot find them;
##  we walk the scene tree instead and measure distance.)
func _check_portal_overlap() -> void:
	var portals := get_tree().get_nodes_in_group("portal")
	for node in portals:
		if not (node is Portal):
			continue
		var portal : Portal = node as Portal
		if not portal.linked_portal or not is_instance_valid(portal.linked_portal):
			continue
		if portal._cooldowns.has(self) or portal.linked_portal._cooldowns.has(self):
			continue
		# Check if our position is close enough to be "inside" this portal.
		# Use the portal's local x-axis (along the surface) as the half-width check.
		var to_cube : Vector2 = global_position - portal.global_position
		# Project onto portal axes.
		var along  : float = abs(to_cube.dot(Vector2.RIGHT.rotated(portal.rotation)))
		var depth  : float = abs(to_cube.dot(Vector2.UP.rotated(portal.rotation)))
		# Portal collision shape is 28×18 (world-space), scaled by portal scale.
		var half_along : float = 28.0 * portal.scale.x * 0.5
		var half_depth : float = 18.0 * portal.scale.y * 0.5
		if along <= half_along and depth <= half_depth:
			portal._teleport_rigidbody(self)
			return
