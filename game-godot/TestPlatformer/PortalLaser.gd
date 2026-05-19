extends Node2D

@onready var _ray  : RayCast2D = $LaserRay
@onready var _beam : Line2D    = $LaserBeam

const RAY_LENGTH : float = 2000.0

func _ready() -> void:
	_ray.target_position = Vector2(RAY_LENGTH, 0.0)
	_ray.collision_mask  = 1
	_ray.enabled         = true
	_beam.points         = [Vector2.ZERO, Vector2(RAY_LENGTH, 0.0)]
	_beam.width          = 6.0
	_beam.default_color  = Color(0.72, 0.0, 1.0, 0.85)
	_beam.texture_mode   = Line2D.LINE_TEXTURE_STRETCH
	_beam.joint_mode     = Line2D.LINE_JOINT_ROUND
	_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam.end_cap_mode   = Line2D.LINE_CAP_ROUND

func _process(_delta: float) -> void:
	var player := _get_player()
	_beam.visible = player != null and player.get("is_gun_equipped") == true
	if not _beam.visible:
		return
	if _ray.is_colliding():
		_beam.set_point_position(1, to_local(_ray.get_collision_point()))
	else:
		_beam.set_point_position(1, Vector2(RAY_LENGTH, 0.0))

func _get_player() -> Node:
	var group := get_tree().get_nodes_in_group("player")
	if group.size() > 0:
		return group[0]
	return null
