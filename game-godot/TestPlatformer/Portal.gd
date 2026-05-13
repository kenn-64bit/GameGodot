extends Area2D
class_name Portal

# =============================================================================
#  Portal.gd  –  Teleportation portal (Area2D)
#  Godot 4.6.2
#
#  Scene requirements:
#    - CollisionShape2D  (a thin RectangleShape2D, e.g. 12 × 48)
#    - Sprite2D          (used for colour tinting; no texture needed –
#                         a plain white rect from a ColorRect baked texture,
#                         or leave it without a texture and rely on the tint)
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

# ---------------------------------------------------------------------------
@onready var _sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _sprite:
		_sprite.modulate = portal_color


func _process(delta: float) -> void:
	# Tick down per-body cooldowns
	var finished : Array = []
	for body in _cooldowns:
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0:
			finished.append(body)
	for body in finished:
		_cooldowns.erase(body)


# ---------------------------------------------------------------------------
## Position and orient the portal so it faces out of the surface.
func place_at(pos: Vector2, normal: Vector2) -> void:
	global_position = pos
	surface_normal  = normal
	# Portal "up" axis is -Y by default; rotate to align with the surface normal.
	rotation = normal.angle() - PI / 2.0


# ---------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
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
		_teleport_rigidbody(body as RigidBody2D)
	elif body is CharacterBody2D and body.is_in_group("player"):
		_teleport_player(body as CharacterBody2D)


func _on_body_exited(body: Node2D) -> void:
	# Nothing needed – cooldowns handle re-entry prevention.
	pass


# ---------------------------------------------------------------------------
func _teleport_rigidbody(body: RigidBody2D) -> void:
	var exit_pos      : Vector2 = linked_portal.global_position \
								  + linked_portal.surface_normal * 40.0
	var incoming_vel  : Vector2 = body.linear_velocity
	var angle_diff    : float   = linked_portal.surface_normal.angle() \
								  - surface_normal.angle()
	var exit_vel      : Vector2 = incoming_vel.rotated(angle_diff + PI)

	body.global_position = exit_pos
	body.linear_velocity = exit_vel

	_set_cooldown(body)
	linked_portal._set_cooldown(body)


func _teleport_player(player: CharacterBody2D) -> void:
	var exit_pos   : Vector2 = linked_portal.global_position \
							   + linked_portal.surface_normal * 40.0
	var angle_diff : float   = linked_portal.surface_normal.angle() \
							   - surface_normal.angle()
	var exit_vel   : Vector2 = player.velocity.rotated(angle_diff + PI)

	player.global_position = exit_pos
	player.velocity        = exit_vel

	_set_cooldown(player)
	linked_portal._set_cooldown(player)


func _set_cooldown(body: Node2D) -> void:
	_cooldowns[body] = TELEPORT_COOLDOWN
