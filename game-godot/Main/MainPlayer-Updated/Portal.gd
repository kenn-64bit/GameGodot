extends Area2D
class_name Portal

var linked_portal  : Portal = null
var surface_normal : Vector2 = Vector2.UP
@export var portal_color : Color = Color.CYAN
var _cooldowns : Dictionary = {}
const TELEPORT_COOLDOWN : float = 0.5
var _pending_held : Array = []

@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _sprite:
		_sprite.modulate = portal_color

func _process(delta: float) -> void:
	# Drain cooldown timers.
	var finished : Array = []
	for body in _cooldowns:
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0:
			finished.append(body)
	for body in finished:
		_cooldowns.erase(body)

	# Drain stale pending entries.
	var still_pending : Array = []
	for body in _pending_held:
		if not is_instance_valid(body):
			continue
		if not body.get("is_held"):
			_try_teleport_body(body)
		else:
			still_pending.append(body)
	_pending_held = still_pending

	_poll_grabbable_overlap()

func place_at(pos: Vector2, normal: Vector2) -> void:
	global_position = pos + normal * 16.0
	surface_normal  = normal
	rotation = normal.angle() - PI / 2.0

func _on_body_entered(body: Node2D) -> void:
	# Defer so we modify physics bodies OUTSIDE the physics callback.
	call_deferred("_try_teleport_body", body)

func _on_body_exited(body: Node2D) -> void:
	_pending_held.erase(body)

func _try_teleport_body(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if _cooldowns.has(body):
		return
	if not linked_portal or not is_instance_valid(linked_portal):
		return
	if linked_portal._cooldowns.has(body):
		return

	if body is RigidBody2D:
		if body.get("is_held"):
			_teleport_held_rigidbody(body as RigidBody2D)
		else:
			_teleport_rigidbody(body as RigidBody2D)
	elif body is CharacterBody2D and body.is_in_group("player"):
		_teleport_player(body as CharacterBody2D)

## ── Core teleport helper ─────────────────────────────────────────────────────
## Uses PhysicsServer2D.body_set_state for IMMEDIATE physics body movement.
## body.freeze + global_position does NOT reliably move the physics collider in
## Godot 4's FREEZE_MODE_STATIC (only the visual node moves), causing the cube
## to disappear when the collider is still at the entry wall on unfreeze.
func _ps_move(body: RigidBody2D, pos: Vector2, vel: Vector2) -> void:
	var rid := body.get_rid()
	PhysicsServer2D.body_set_state(
			rid, PhysicsServer2D.BODY_STATE_TRANSFORM,
			Transform2D(body.rotation, pos))
	PhysicsServer2D.body_set_state(
			rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, vel)
	PhysicsServer2D.body_set_state(
			rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	# Sync the scene-tree node so it agrees with the physics server.
	body.global_position = pos
	body.linear_velocity = vel

## Free-cube teleport (player pushed it into the portal).
func _teleport_rigidbody(body: RigidBody2D) -> void:
	SfxManager.play_sfx("exit_portal")
	# 90 px clearance: cube physics half-size ≈ 50 px (shape 24 × scale 4.16).
	# Less than ~50 px embeds the cube in the exit wall → physics ejects it wildly.
	var exit_pos     : Vector2 = linked_portal.global_position \
								  + linked_portal.surface_normal * 90.0
	var incoming_vel : Vector2 = body.linear_velocity
	var angle_diff   : float   = linked_portal.surface_normal.angle() \
								  - surface_normal.angle()
	var exit_vel     : Vector2 = incoming_vel.rotated(angle_diff + PI)

	# Always exit with enough speed to clear the portal mouth.
	if exit_vel.length() < 150.0:
		exit_vel = linked_portal.surface_normal * 150.0

	# Cooldowns before move so _poll_grabbable_overlap can't re-fire this frame.
	_set_cooldown(body)
	linked_portal._set_cooldown(body)
	_pending_held.erase(body)
	linked_portal._pending_held.erase(body)

	_ps_move(body, exit_pos, exit_vel)

## Held-cube teleport (cube was dragged directly into portal while held).
func _teleport_held_rigidbody(body: RigidBody2D) -> void:
	SfxManager.play_sfx("exit_portal")
	var exit_pos : Vector2 = linked_portal.global_position \
							  + linked_portal.surface_normal * 90.0

	_set_cooldown(body)
	linked_portal._set_cooldown(body)
	_pending_held.erase(body)
	linked_portal._pending_held.erase(body)

	_ps_move(body, exit_pos, Vector2.ZERO)

	# Sync _hold_target so GrabbableCube._physics_process doesn't race the cube
	# back to the old (entry-side) anchor on the very next frame.
	if body.has_method("update_hold_position"):
		body.call("update_hold_position", exit_pos)

## Player teleport — also moves the held cube atomically.
func _teleport_player(player: CharacterBody2D) -> void:
	SfxManager.play_sfx("exit_portal")
	var exit_pos   : Vector2 = linked_portal.global_position \
							   + linked_portal.surface_normal * 40.0
	var angle_diff : float   = linked_portal.surface_normal.angle() \
							   - surface_normal.angle()
	var exit_vel   : Vector2 = player.velocity.rotated(angle_diff + PI)

	# Lock held-cube cooldowns on BOTH portals FIRST so the polling loop
	# cannot double-teleport the cube while we're repositioning everything.
	if player.get("is_holding_object") and player.get("held_object"):
		var held = player.held_object
		if held and is_instance_valid(held):
			_set_cooldown(held)
			linked_portal._set_cooldown(held)

	# Move player.
	player.global_position = exit_pos
	player.velocity        = exit_vel

	# Move held cube atomically with the player.
	if player.get("is_holding_object") and player.get("held_object"):
		var held = player.held_object
		if held and is_instance_valid(held):
			var cube_exit : Vector2 = exit_pos + linked_portal.surface_normal * 90.0
			if held is RigidBody2D:
				_ps_move(held as RigidBody2D, cube_exit, Vector2.ZERO)
			else:
				held.global_position = cube_exit
			# Sync _hold_target so the cube doesn't race back to the entry side.
			if held.has_method("update_hold_position"):
				held.call("update_hold_position", cube_exit)

	_set_cooldown(player)
	linked_portal._set_cooldown(player)

func _set_cooldown(body: Node2D) -> void:
	_cooldowns[body] = TELEPORT_COOLDOWN

func _poll_grabbable_overlap() -> void:
	if not linked_portal or not is_instance_valid(linked_portal):
		return

	var half_along : float = 28.0 * 1.2047 * scale.x * 0.5
	# 2× depth so fast-moving cubes aren't missed between _process ticks.
	var half_depth : float = 18.0 * 1.1929 * scale.y

	var right_axis : Vector2 = Vector2.RIGHT.rotated(rotation)
	var up_axis    : Vector2 = Vector2.UP.rotated(rotation)

	for body in get_tree().get_nodes_in_group("Grabbable"):
		if not is_instance_valid(body):
			continue
		if _cooldowns.has(body) or linked_portal._cooldowns.has(body):
			continue
		var to_body : Vector2 = (body as Node2D).global_position - global_position
		var along   : float   = abs(to_body.dot(right_axis))
		var depth   : float   = abs(to_body.dot(up_axis))
		if along <= half_along and depth <= half_depth:
			if body.get("is_held"):
				_teleport_held_rigidbody(body as RigidBody2D)
			else:
				_teleport_rigidbody(body as RigidBody2D)
