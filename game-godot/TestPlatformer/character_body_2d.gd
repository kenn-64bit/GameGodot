extends CharacterBody2D

# Movement Constants
const SPEED = 400.0
const JUMP_VELOCITY = -700.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.2

# After-Image (Ghost) Settings
const GHOST_SCENE = preload("res://ghost.tscn")
const GHOST_DELAY = 0.02
var ghost_timer = 0.0

# State variables
var is_dashing = false
var dash_timer = 0.0
var can_dash = true # Track if the player is allowed to dash

# Camera Bobbing Settings
@export var bob_freq = 10.0
@export var bob_amp = 5.0
var time = 0.0

@onready var camera = $Camera2D
@onready var sprite = $AnimatedSprite2D
@onready var crosshair = $Crosshair # Ensure you have a Sprite2D or Control node named 'Crosshair'

func _ready():
	# Hide the system mouse cursor so only the crosshair shows
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _physics_process(delta: float) -> void:
	# 1. Update Crosshair Position
	update_crosshair()

	# 2. Handle Dash Logic
	# Reset dash ability when on the floor
	if is_on_floor():
		can_dash = true

	if Input.is_action_just_pressed("dash") and not is_dashing and can_dash:
		start_dash()
		if not is_on_floor():
			can_dash = false # Consume the air dash

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
		velocity += get_gravity() * delta

	# 4. Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 5. Handle Horizontal Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)
	handle_camera_bob(delta)

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	var dash_dir = -1 if sprite.flip_h else 1
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0 

func update_crosshair():
	# Keeps the crosshair at the mouse position relative to the world
	if crosshair:
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
	ghost.self_modulate = Color(1, 1, 1, 1.0)

func update_animations(direction: float) -> void:
	if is_dashing:
		sprite.play("dash")
		return

	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("falling")
	else:
		if direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

func handle_camera_bob(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 0.1 and not is_dashing:
		time += delta * bob_freq
		camera.offset.y = sin(time) * bob_amp
	else:
		time = 0
		camera.offset.y = move_toward(camera.offset.y, 0, bob_amp * delta * 2)
