extends Area2D
class_name Portal

# =============================================================================
#  Portal.gd  –  Teleportation portal (Area2D)
#  Godot 4.6.2
#
#  Scene requirements:
#    - CollisionShape2D  (RectangleShape2D, e.g. 28 × 18)
#    - AnimatedSprite2D  (used for colour tinting / animation)
# =============================================================================

## The partner portal assigned at runtime by the player script.
var linked_portal : Portal = null

## Outward surface normal (set by place_at).
var surface_normal : Vector2 = Vector2.UP

## Portal colour – set by the player before place_at() is called.
@export var portal_color : Color = Color.CYAN

## Per-body cooldown map so the same body cannot instantly bounce back.
var _cooldowns : Dictionary = {}   # body -> remaining seconds
const TELEPORT_COOLDOWN : float = 0.5

## Bodies that entered while held; re-checked each frame until released.
var _pending_held : Array = []

# ---------------------------------------------------------------------------
@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("portal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _sprite:
		_sprite.modulate = portal_color


func _process(delta: float) -> void:
	# ── Tick down per-body cooldowns ─────────────────────────────────────
	var finished : Array = []
	for body in _cooldowns:
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0:
			finished.append(body)
	for body in finished:
		_cooldowns.erase(body)

	# ── Retry teleport for objects that entered while held ───────────────
	# Once the player releases them, we teleport on the next frame.
	var still_pending : Array = []
	for body in _pending_held:
		if not is_instance_valid(body):
			continue  # body was freed, discard
		# If body is no longer held, attempt teleport now.
		if not body.get("is_held"):
			_try_teleport_body(body)
		else:
			still_pending.append(body)  # still held, keep waiting
	_pending_held = still_pending


# ---------------------------------------------------------------------------
## Position and orient the portal so it faces out of the surface.
func place_at(pos: Vector2, normal: Vector2) -> void:
	# Offset off the wall so the detection zone extends into playable space.
	global_position = pos + normal * 16.0
	surface_normal  = normal
	# Portal "up" axis is -Y by default; rotate to align with the surface normal.
	rotation = normal.angle() - PI / 2.0


# ---------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	_try_teleport_body(body)


func _on_body_exited(body: Node2D) -> void:
	# Remove from pending if the body leaves the portal without being teleported.
	_pending_held.erase(body)


# ---------------------------------------------------------------------------
func _try_teleport_body(body: Node2D) -> void:
	# Ignore if body is still in cooldown
	if _cooldowns.has(body):
		return
	# Ignore if we have no partner
	if not linked_portal or not is_instance_valid(linked_portal):
		return
	# Ignore if the exit portal is also in cooldown for this body
	if linked_portal._cooldowns.has(body):
		return

	if body is RigidBody2D:
		# If the object is currently held, queue it for retry once released.
		if body.get("is_held"):
			if not _pending_held.has(body):
				_pending_held.append(body)
			return
		_teleport_rigidbody(body as RigidBody2D)
	elif body is CharacterBody2D and body.is_in_group("player"):
		_teleport_player(body as CharacterBody2D)


# ---------------------------------------------------------------------------
func _teleport_rigidbody(body: RigidBody2D) -> void:
	var exit_pos     : Vector2 = linked_portal.global_position \
								  + linked_portal.surface_normal * 40.0
	var incoming_vel : Vector2 = body.linear_velocity
	# Rotate velocity to exit direction; add PI to flip through the portal.
	var angle_diff   : float   = linked_portal.surface_normal.angle() \
								  - surface_normal.angle()
	var exit_vel     : Vector2 = incoming_vel.rotated(angle_diff + PI)

	# If the object is barely moving (dropped in-place), give it a small
	# outward push so it doesn't just sit inside the exit wall.
	if exit_vel.length() < 20.0:
		exit_vel = linked_portal.surface_normal * 60.0

	body.global_position = exit_pos
	body.linear_velocity = exit_vel

	_set_cooldown(body)
	linked_portal._set_cooldown(body)

	# Remove from pending list if it was queued.
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

	# Teleport held object alongside the player through the portal
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
