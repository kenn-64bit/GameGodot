extends Node2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	_sprite.play(&"Activated")


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.has_method(&"handle_hazard_death"):
		return
	body.callv(&"handle_hazard_death", [global_position])
