extends CharacterBody2D

const SPEED = 1000.0
const JUMP_VELOCITY = -600.0

# Bobbing Settings
@export var bob_freq = 10.0
@export var bob_amp = 5.0
var time = 0.0

@onready var camera = $Camera2D
@onready var sprite = $AnimatedSprite2D # Make sure your AnimatedSprite2D is named exactly this

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	# Handle Movement and Directional Flipping
	if direction:
		velocity.x = direction * SPEED
		# Flip the sprite based on direction
		if direction > 0:
			sprite.flip_h = false # Facing Right
		else:
			sprite.flip_h = true  # Facing Left
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Update Animations
	update_animations(direction)
	
	# Apply Bobbing Logic
	handle_camera_bob(delta)

func update_animations(direction: float) -> void:
	if not is_on_floor():
		# Optional: If you add a "Jump" animation later, play it here
		pass 
	elif direction != 0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func handle_camera_bob(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 0.1:
		time += delta * bob_freq
		camera.offset.y = sin(time) * bob_amp
	else:
		time = 0
		camera.offset.y = move_toward(camera.offset.y, 0, bob_amp * delta * 2)
