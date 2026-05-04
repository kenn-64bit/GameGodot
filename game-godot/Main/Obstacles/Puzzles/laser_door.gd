extends Node2D
class_name LaserDoor

signal door_opened

@export var blocking_collision_layer: int = 1
@export var kill_drains_all_lives: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _solid: StaticBody2D = $Laser_Hitbox
@onready var _kill_zone: Area2D = $KillZone

var _opened: bool = false


func _ready() -> void:
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	if not _opened:
		_apply_closed_state()


var opened: bool:
	get:
		return _opened


func set_open(value: bool) -> void:
	if not value or _opened:
		return
	_opened = true
	_open_async()


func _apply_closed_state() -> void:
	_sprite.play(&"idle")
	_solid.collision_layer = blocking_collision_layer
	_kill_zone.monitoring = true


func _open_async() -> void:
	_kill_zone.monitoring = false
	_sprite.play(&"deactivate")
	await _sprite.animation_finished
	_solid.set_deferred("collision_layer", 0)
	door_opened.emit()


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if _opened:
		return
	if not body.has_method(&"handle_hazard_death"):
		return
	if kill_drains_all_lives:
		body.callv(&"handle_hazard_death", [global_position, true])
	else:
		body.callv(&"handle_hazard_death", [global_position])
