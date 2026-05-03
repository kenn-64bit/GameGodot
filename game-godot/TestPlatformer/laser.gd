extends Node2D

@export var hidden_duration := 1.0
@export var active_duration := 1.2
@export var kill_start_frame := 0
@export var kill_end_frame := -1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

var _active := false

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)

	animated_sprite.play("deactivate")
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("deactivate") - 1
	animated_sprite.stop()
	_set_hazard_active(false)
	_cycle()

func _cycle() -> void:
	while true:
		await get_tree().create_timer(hidden_duration).timeout
		animated_sprite.play("activate")
		await animated_sprite.animation_finished

		animated_sprite.play("idle")
		_set_hazard_active(false)
		await get_tree().create_timer(active_duration).timeout

		_set_hazard_active(false)
		animated_sprite.play("deactivate")
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
	if animated_sprite.animation == "deactivate":
		animated_sprite.stop()

func _on_frame_changed() -> void:
	if animated_sprite.animation != "idle":
		return

	var frame: int = animated_sprite.frame
	var end_frame: int = kill_end_frame
	if end_frame < 0:
		end_frame = animated_sprite.sprite_frames.get_frame_count("idle") - 1

	var should_kill := frame >= kill_start_frame and frame <= end_frame
	if should_kill != _active:
		_set_hazard_active(should_kill)
