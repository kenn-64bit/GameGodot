extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

# Camera Shake Settings
@export var shake_fade: float = 5.0
var shake_intensity: float = 0.0

@onready var camera = $Camera2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get direction
	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		# Apply shake intensity when moving on the floor
		if is_on_floor():
			shake_intensity = 2.0 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Apply and decay the shake
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, shake_fade * delta)
		camera.offset = Vector2(randf_range(-1, 1) * shake_intensity, randf_range(-1, 1) * shake_intensity)
	else:
		camera.offset = Vector2.ZERO

	move_and_slide()
