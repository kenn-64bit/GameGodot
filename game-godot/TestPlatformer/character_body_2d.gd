extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

# Bobbing Settings
@export var bob_freq = 10.0  # How fast the bob happens
@export var bob_amp = 4.0    # How high/low the camera moves
var time = 0.0

@onready var camera = $Camera2D

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Apply Bobbing Logic
	handle_camera_bob(delta)

func handle_camera_bob(delta: float) -> void:
	# Only bob if we are on the floor and moving
	if is_on_floor() and abs(velocity.x) > 0.1:
		time += delta * bob_freq
		camera.offset.y = sin(time) * bob_amp
	else:
		# Smoothly return camera to center when stopped or in air
		time = 0
		camera.offset.y = move_toward(camera.offset.y, 0, bob_amp * delta * 2)
