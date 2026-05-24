extends Node2D
class_name LaserDoor

signal door_opened

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: Area2D = $Hitbox

var _opened: bool = false


func _ready() -> void:
	add_to_group(&"puzzle_door")
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
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
	_hitbox.monitoring = true


func _open_async() -> void:
	_hitbox.monitoring = false
	_sprite.play(&"deactivate")
	await _sprite.animation_finished
	door_opened.emit()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if _opened:
		return
	if not body.has_method(&"handle_hazard_death"):
		return
	body.callv(&"handle_hazard_death", [global_position])
