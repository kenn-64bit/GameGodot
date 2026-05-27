extends CharacterBody2D

# Movement Constants
const SPEED = 400.0
const JUMP_VELOCITY = -700.0
const DASH_STARTUP_DELAY = 0.15 
var dash_startup_timer = 0.0
var is_waiting_to_dash = false
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5 
var dash_cooldown_timer = 0.0

# Gravity Flip Settings
const FLIP_COOLDOWN = 1
var flip_timer = 0.0
var is_upside_down = false

# After-Image (Ghost) Settings
const GHOST_SCENE = preload("res://Main/Player/ghost.tscn")
const GHOST_DELAY = 0.02
var ghost_timer = 0.0

# State variables
var is_dashing = false
var coyote_timer = 0.0
const COYOTE_TIME = 0.15 
var dash_timer = 0.0
var can_dash = true 

# Camera Bobbing Settings
@export var bob_freq = 10.0
@export var bob_amp = 5.0
var time = 0.0

signal all_lives_lost

@onready var camera = $Camera2D
@onready var sprite = $AnimatedSprite2D
@onready var crosshair = $Crosshair

@export var starting_lives: int = 3
var lives: int = 3
var _spawn_global: Vector2 = Vector2.ZERO

# Trap Death Components
@export var hazard_death_cooldown := 0.5
@export var path_history_max_points := 128
@export var path_sample_min_distance := 100.0
@export var path_respawn_lookback_points := 32
@export var path_respawn_min_distance_from_hazard := 100.0
var hazard_death_timer := 0.0
var _path_history: Array[Vector2] = []

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	lives = starting_lives
	_spawn_global = global_position
	_path_history.clear()
	_path_history.append(_spawn_global)

func _input(event):
	if event.is_action_pressed("ui_fullscreen") or (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _physics_process(delta: float) -> void:
	# Update timers
	if flip_timer > 0:
		flip_timer -= delta
	# Death Timer
	if hazard_death_timer > 0:
		hazard_death_timer -= delta
 
	update_crosshair()

	# 1. Handle Gravity Flip (R Key)
	if Input.is_key_pressed(KEY_R) and flip_timer <= 0:
		toggle_gravity()

	# 2. Handle Dash Logic
	# 1. Update the cooldown timer every frame
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# 2. Reset dash capability on floor
	if is_on_floor():
		can_dash = true 

	# 3. Trigger Dash (Only if cooldown is finished)
	if Input.is_action_just_pressed("dash") and not is_dashing and can_dash and dash_cooldown_timer <= 0:
		if not is_on_floor():
			can_dash = false 
		
		start_dash()
		dash_cooldown_timer = DASH_COOLDOWN # Lock the dash until timer hits 0

	if is_dashing:
		dash_timer -= delta
		handle_ghosting(delta)
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		_record_path_position()
		update_animations(0)
		return

	# 3. Add Gravity 
	if not is_on_floor():
		var gravity_strength = get_gravity() * delta
		if is_upside_down:
			velocity -= gravity_strength 
		else:
			velocity += gravity_strength 

	# 4. Handle Jump 
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_upside_down:
			velocity.y = -JUMP_VELOCITY # Pushes "down" toward the floor (ceiling jump)
		else:
			velocity.y = JUMP_VELOCITY 

	# 5. Handle Horizontal Movement
	var direction := 0.0
	if Input.is_action_pressed("left"):
		direction -= 1.0
	if Input.is_action_pressed("right"):
		direction += 1.0
	
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# 3. Add Gravity & Coyote Timer logic
	if is_on_floor():
		coyote_timer = COYOTE_TIME # Reset timer while on floor
	else:
		coyote_timer -= delta # Count down when in air (or sliding down slopes)
		
		var gravity_strength = get_gravity() * delta
		if is_upside_down:
			velocity -= gravity_strength 
		else:
			velocity += gravity_strength 

	# 4. Handle Jump (Now uses coyote_timer instead of is_on_floor)
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		coyote_timer = 0 # Prevent double jumping in mid-air
		if is_upside_down:
			velocity.y = -JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY
	
	move_and_slide()
	_record_path_position()
	update_animations(direction)
	handle_camera_bob(delta)

### --- New & Updated Functions --- ###

func toggle_gravity():
	is_upside_down = !is_upside_down
	flip_timer = FLIP_COOLDOWN 
	
	if is_upside_down:
		up_direction = Vector2.DOWN
		sprite.flip_v = true
		camera.rotation_degrees = 180 # Flip the perspective
	else:
		up_direction = Vector2.UP
		sprite.flip_v = false
		camera.rotation_degrees = 0   # Return to normal
	
	# Optional: You could add a Tween here to make the camera rotation smooth!

### --- Helper Functions --- ###

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	var dash_dir = -1 if sprite.flip_h else 1
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0 

func update_crosshair():
	if crosshair:
		# Godot's get_global_mouse_position() accounts for camera rotation automatically!
		crosshair.global_position = get_global_mouse_position()

func handle_ghosting(delta: float):
	ghost_timer -= delta
	if ghost_timer <= 0:
		spawn_ghost()
		ghost_timer = GHOST_DELAY

func spawn_ghost():
	var ghost = GHOST_SCENE.instantiate()
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = sprite.global_position
	ghost.global_scale = sprite.global_scale
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v 
	ghost.self_modulate = Color(1, 1, 1, 0.6)

func update_animations(direction: float) -> void:
	if is_dashing:
		sprite.play("dash")
		return

	if not is_on_floor():
		var falling = velocity.y > 0 if not is_upside_down else velocity.y < 0
		if falling:
			sprite.play("falling")
		else:
			sprite.play("jump")
	else:
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

func handle_camera_bob(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 0.1 and not is_dashing:
		time += delta * bob_freq
		# The camera bob will now move "up/down" relative to the camera's own rotation
		camera.offset.y = sin(time) * bob_amp
	else:
		time = 0
		camera.offset.y = move_toward(camera.offset.y, 0, bob_amp * delta * 2)
# Death Hazard
func handle_hazard_death(hazard_position: Vector2, wipe_all_lives: bool = false) -> void:
	if hazard_death_timer > 0:
		return

	hazard_death_timer = hazard_death_cooldown
	velocity = Vector2.ZERO
	is_dashing = false

	if wipe_all_lives:
		lives = 0
		_respawn_at_level_start()
		return

	lives -= 1
	if lives <= 0:
		_respawn_at_level_start()
		lives = 3
		return

	var respawn_position := _find_path_respawn_position(hazard_position)
	global_position = respawn_position
	_trim_path_history_after_respawn(respawn_position)


func _respawn_at_level_start() -> void:
	global_position = _spawn_global
	_path_history.clear()
	_path_history.append(_spawn_global)
	all_lives_lost.emit()


func _record_path_position() -> void:
	if _path_history.is_empty():
		_path_history.append(global_position)
		return
	if global_position.distance_to(_path_history[-1]) < path_sample_min_distance:
		return
	_path_history.append(global_position)
	while _path_history.size() > path_history_max_points:
		_path_history.pop_front()


func _find_path_respawn_position(hazard_position: Vector2) -> Vector2:
	if _path_history.size() < 2:
		return _spawn_global

	var lookback_start := maxi(0, _path_history.size() - path_respawn_lookback_points)
	var approach_side := signf(_path_history[lookback_start].x - hazard_position.x)
	if approach_side == 0.0:
		approach_side = signf(global_position.x - hazard_position.x)
	if approach_side == 0.0:
		approach_side = -1.0

	for i in range(_path_history.size() - 2, -1, -1):
		var candidate: Vector2 = _path_history[i]
		if candidate.distance_to(hazard_position) < path_respawn_min_distance_from_hazard:
			continue
		if signf(candidate.x - hazard_position.x) != approach_side:
			continue
		if _is_point_inside_solid(candidate):
			continue
		return candidate

	for i in range(_path_history.size() - 1, -1, -1):
		var candidate: Vector2 = _path_history[i]
		if not _is_point_inside_solid(candidate):
			return candidate

	return _spawn_global


func _is_point_inside_solid(point: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not space_state.intersect_point(query, 1).is_empty()


func _trim_path_history_after_respawn(respawn_position: Vector2) -> void:
	var cut_index := 0
	for i in range(_path_history.size()):
		if _path_history[i].distance_to(respawn_position) <= path_sample_min_distance:
			cut_index = i
			break
	_path_history = _path_history.slice(cut_index)
	_path_history.append(respawn_position)
