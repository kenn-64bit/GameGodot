extends Area2D
class_name Portal

var linked_portal : Portal = null
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
	var finished : Array = []
	for body in _cooldowns:
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0:
			finished.append(body)
	for body in finished:
		_cooldowns.erase(body)

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
	_try_teleport_body(body)

func _on_body_exited(body: Node2D) -> void:
	if not body.get("is_held"):
		_pending_held.erase(body)

func _try_teleport_body(body: Node2D) -> void:
	if _cooldowns.has(body):
		return
	if not linked_portal or not is_instance_valid(linked_portal):
		return
	if linked_portal._cooldowns.has(body):
		return

	if body is RigidBody2D:
		if body.get("is_held"):
			if not _pending_held.has(body):
				_pending_held.append(body)
			return
		_teleport_rigidbody(body as RigidBody2D)
	elif body is CharacterBody2D and body.is_in_group("player"):
		_teleport_player(body as CharacterBody2D)

func _teleport_rigidbody(body: RigidBody2D) -> void:
	var exit_pos     : Vector2 = linked_portal.global_position \
								  + linked_portal.surface_normal * 40.0
	var incoming_vel : Vector2 = body.linear_velocity
	var angle_diff   : float   = linked_portal.surface_normal.angle() \
								  - surface_normal.angle()
	var exit_vel     : Vector2 = incoming_vel.rotated(angle_diff + PI)

	if exit_vel.length() < 20.0:
		exit_vel = linked_portal.surface_normal * 60.0

	body.global_position = exit_pos
	body.linear_velocity = exit_vel

	_set_cooldown(body)
	linked_portal._set_cooldown(body)

	_pending_held.erase(body)
	linked_portal._pending_held.erase(body)

func _teleport_player(player: CharacterBody2D) -> void:
	var exit_pos   : Vector2 = linked_portal.global_position \
							   + linked_portal.surface_normal * 40.0
	var angle_diff : float   = linked_portal.surface_normal.angle() \
							   - surface_normal.angle()
	var exit_vel   : Vector2 = player.velocity.rotated(angle_diff + PI)

	player.global_position = exit_pos
	player.velocity        = exit_vel

	if player.get("is_holding_object") and player.get("held_object"):
		var held = player.held_object
		if held and is_instance_valid(held):
			held.global_position = exit_pos + linked_portal.surface_normal * 30.0
			if held is RigidBody2D:
				held.linear_velocity = exit_vel
			_set_cooldown(held)
			linked_portal._set_cooldown(held)

	_set_cooldown(player)
	linked_portal._set_cooldown(player)

func _set_cooldown(body: Node2D) -> void:
	_cooldowns[body] = TELEPORT_COOLDOWN

func _poll_grabbable_overlap() -> void:
	if not linked_portal or not is_instance_valid(linked_portal):
		return

	var half_along : float = 28.0 * 1.2047 * scale.x * 0.5
	var half_depth : float = 18.0 * 1.1929 * scale.y * 0.5

	var right_axis : Vector2 = Vector2.RIGHT.rotated(rotation)
	var up_axis    : Vector2 = Vector2.UP.rotated(rotation)

	for body in get_tree().get_nodes_in_group("Grabbable"):
		if not is_instance_valid(body):
			continue
		if _cooldowns.has(body) or linked_portal._cooldowns.has(body):
			continue
		if body.get("is_held"):
			continue
		var to_body : Vector2 = (body as Node2D).global_position - global_position
		var along   : float   = abs(to_body.dot(right_axis))
		var depth   : float   = abs(to_body.dot(up_axis))
		if along <= half_along and depth <= half_depth:
			_teleport_rigidbody(body as RigidBody2D)
