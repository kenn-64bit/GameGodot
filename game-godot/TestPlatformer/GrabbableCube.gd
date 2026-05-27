extends RigidBody2D


var is_held   : bool   = false
var holder    : Node2D = null
var _hold_target : Vector2 = Vector2.ZERO
const FOLLOW_SPEED : float = 18.0
const MAX_HOLD_SPEED : float = 350.0

func _ready() -> void:
	add_to_group("Grabbable")

func _physics_process(_delta: float) -> void:
	if is_held and holder:
		var to_target : Vector2 = _hold_target - global_position
		var raw_vel   : Vector2 = to_target * FOLLOW_SPEED
		if raw_vel.length() > MAX_HOLD_SPEED:
			raw_vel = raw_vel.normalized() * MAX_HOLD_SPEED
		linear_velocity = raw_vel

func grab(by: Node2D) -> void:
	is_held    = true
	holder     = by
	gravity_scale = 0.0
	freeze        = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	set_collision_mask_value(1, false)

func drop(throw_vel: Vector2 = Vector2.ZERO) -> void:
	is_held       = false
	holder        = null
	gravity_scale = 2.5
	continuous_cd = RigidBody2D.CCD_MODE_DISABLED
	_check_portal_overlap()
	set_collision_mask_value(1, true)
	if throw_vel != Vector2.ZERO:
		linear_velocity = throw_vel
	else:
		linear_velocity = Vector2.ZERO

func update_hold_position(target_pos: Vector2) -> void:
	_hold_target = target_pos

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
		var to_cube : Vector2 = global_position - portal.global_position
		var along  : float = abs(to_cube.dot(Vector2.RIGHT.rotated(portal.rotation)))
		var depth  : float = abs(to_cube.dot(Vector2.UP.rotated(portal.rotation)))
		var half_along : float = 28.0 * 1.2047 * portal.scale.x * 0.5
		var half_depth : float = 18.0 * 1.1929 * portal.scale.y * 0.5
		if along <= half_along and depth <= half_depth:
			portal._teleport_rigidbody(self)
			return
