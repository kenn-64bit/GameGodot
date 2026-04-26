extends CharacterBody2D

# Movement Constants
const SPEED = 400.0
const JUMP_VELOCITY = -700.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.2

# Gravity Flip Settings
const FLIP_COOLDOWN = 1
var flip_timer = 0.0
var is_upside_down = false

# After-Image (Ghost) Settings
const GHOST_SCENE = preload("res://TestPlatformer/ghost.tscn")
const GHOST_DELAY = 0.02
var ghost_timer = 0.0

# State variables
var is_dashing = false
var dash_timer = 0.0
var can_dash = true 

# Camera Bobbing Settings
@export var bob_freq = 10.0
@export var bob_amp = 5.0
var time = 0.0

@onready var camera = $Camera2D
@onready var sprite = $AnimatedSprite2D
@onready var crosshair = $Crosshair 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

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
 
	update_crosshair()

	# 1. Handle Gravity Flip (R Key)
	if Input.is_key_pressed(KEY_R) and flip_timer <= 0:
		toggle_gravity()

	# 2. Handle Dash Logic
	if is_on_floor():
		can_dash = true 

	if Input.is_action_just_pressed("dash") and not is_dashing and can_dash:
		if not is_on_floor():
			can_dash = false 
		start_dash()

	if is_dashing:
		dash_timer -= delta
		handle_ghosting(delta)
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
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
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
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
