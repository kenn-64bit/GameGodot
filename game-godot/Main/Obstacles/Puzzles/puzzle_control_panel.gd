extends Node2D
class_name PuzzleControlPanel

signal panel_activated

@onready var _touch: Area2D = $TouchArea
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _done: bool = false


func _ready() -> void:
	add_to_group(&"puzzle_panel")
	_touch.body_entered.connect(_on_body_entered)
	_sprite.play(&"idle")


func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body is CharacterBody2D:
		_done = true
		_sprite.play(&"deactivate")
		panel_activated.emit()
