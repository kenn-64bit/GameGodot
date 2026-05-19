extends Node2D

@onready var _ray  : RayCast2D = $LaserRay
@onready var _beam : Line2D    = $LaserBeam

const TRAVEL_TIME    : float = 0.15 # Matches PORTAL_PLACE_DELAY in player
const BEAM_LENGTH    : float = 250.0 # How long the physical laser blast is
const ANIM_SPEED     : float = 0.05

var _is_firing     : bool  = false
var _fire_timer    : float = 0.0
var _anim_timer    : float = 0.0
var _current_frame : int   = 0
var _frame_origin  : float = 0.0

var _start_pos : Vector2 = Vector2.ZERO
var _end_pos   : Vector2 = Vector2.ZERO
var _travel_dir: Vector2 = Vector2.RIGHT
var _total_dist: float   = 0.0

func _ready() -> void:
	_ray.target_position = Vector2(2000.0, 0.0)
	_ray.collision_mask  = 1
	_ray.enabled         = true
	_beam.default_color  = Color.WHITE
	_beam.texture_mode   = Line2D.LINE_TEXTURE_TILE
	_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam.end_cap_mode   = Line2D.LINE_CAP_ROUND
	
	# Detach the beam from the gun's rotation so it flies straight in world space!
	_beam.top_level      = true 
	_beam.visible        = false
	if _beam.texture is AtlasTexture:
		_frame_origin = (_beam.texture as AtlasTexture).region.position.x

func _process(delta: float) -> void:
	if _is_firing:
		_fire_timer += delta
		var progress := minf(_fire_timer / TRAVEL_TIME, 1.0)
		
		# The laser must travel its own length + the distance to the wall to fully disappear into it
		var total_travel := _total_dist + BEAM_LENGTH
		var current_dist := progress * total_travel
		
		# Head flies forward and stops at the wall
		var head_dist := clampf(current_dist, 0.0, _total_dist)
		# Tail follows behind
		var tail_dist := clampf(current_dist - BEAM_LENGTH, 0.0, _total_dist)
		
		_beam.set_point_position(0, _start_pos + _travel_dir * tail_dist)
		_beam.set_point_position(1, _start_pos + _travel_dir * head_dist)
		
		if progress >= 1.0:
			_is_firing = false
			_beam.visible = false

	if _beam.visible and _beam.texture is AtlasTexture:
		_anim_timer += delta
		if _anim_timer >= ANIM_SPEED:
			_anim_timer      = 0.0
			_current_frame   = (_current_frame + 1) % 2
			var atlas        := _beam.texture as AtlasTexture
			atlas.region.position.x = _frame_origin + _current_frame * atlas.region.size.x

func fire(hit_world_pos: Vector2) -> void:
	if _beam.texture is AtlasTexture:
		_frame_origin = (_beam.texture as AtlasTexture).region.position.x
		(_beam.texture as AtlasTexture).region.position.x = _frame_origin
	_current_frame = 0
	_anim_timer    = 0.0
	
	_start_pos = global_position
	_end_pos   = hit_world_pos
	_travel_dir = (_end_pos - _start_pos).normalized()
	_total_dist = _start_pos.distance_to(_end_pos)
	
	_beam.set_point_position(0, _start_pos)
	_beam.set_point_position(1, _start_pos)
	_beam.visible = true
	
	_is_firing  = true
	_fire_timer = 0.0
