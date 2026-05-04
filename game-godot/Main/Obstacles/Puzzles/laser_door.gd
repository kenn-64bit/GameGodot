extends Node2D
class_name LaserDoor

signal door_opened

@export var blocking_collision_layer: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _solid: StaticBody2D = $Laser_Hitbox

var _opened: bool = false


func _ready() -> void:
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


func _open_async() -> void:
	_sprite.play(&"deactivate")
	await _sprite.animation_finished
	_solid.set_deferred("collision_layer", 0)
	door_opened.emit()
