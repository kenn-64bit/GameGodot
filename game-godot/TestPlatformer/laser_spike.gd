extends Node2D

@export var hidden_duration := 1.0
@export var emerged_duration := 1.2
@export var kill_start_frame := 0
@export var kill_end_frame := -1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var _active := true

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

	# Start in retracted state so touching early does not kill player.
	animated_sprite.play("Spike_Deactivate")
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("Spike_Deactivate") - 1
	animated_sprite.stop()
	_set_hazard_active(false)
	_start_cycle()

func _start_cycle() -> void:
	while true:
		await get_tree().create_timer(hidden_duration).timeout
		animated_sprite.play("Spike_Activate")
		await animated_sprite.animation_finished

		animated_sprite.play("Spike_Idle")
		_set_hazard_active(false)
		await get_tree().create_timer(emerged_duration).timeout

		_set_hazard_active(false)
		animated_sprite.play("Spike_Deactivate")
		await animated_sprite.animation_finished

func _set_hazard_active(value: bool) -> void:
	_active = value
	hitbox.monitoring = value
	hitbox.monitorable = value

func _on_hitbox_body_entered(body: Node) -> void:
	if not _active:
		return
	if body.has_method("handle_hazard_death"):
		body.handle_hazard_death(global_position)

func _on_animation_finished() -> void:
	# Keep last retract frame visible when hidden.
	if animated_sprite.animation == "Spike_Deactivate":
		animated_sprite.stop()

func _on_frame_changed() -> void:
	if animated_sprite.animation != "Spike_Idle":
		return

	var frame: int = animated_sprite.frame
	var end_frame: int = kill_end_frame
	if end_frame < 0:
		end_frame = animated_sprite.sprite_frames.get_frame_count("Spike_Idle") - 1

	var should_kill := frame >= kill_start_frame and frame <= end_frame
	if should_kill != _active:
		_set_hazard_active(should_kill)
