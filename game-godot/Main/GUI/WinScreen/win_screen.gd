extends Control

## Simple "You Win" end screen shown when the player exits Door 4.

@onready var _label_win  : Label  = $VBox/WinLabel
@onready var _label_sub  : Label  = $VBox/SubLabel
@onready var _btn_menu   : Button = $VBox/RestartButton

func _ready() -> void:
	# Capture mouse so menu works.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Animate the title in.
	_label_win.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_btn_menu.modulate.a  = 0.0

	var tw := create_tween().set_parallel(false)
	tw.tween_property(_label_win, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label_sub, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(_btn_menu,  "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)

	_btn_menu.pressed.connect(_on_restart)


func _on_restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().change_scene_to_file("res://Main/Levels/Level1/ONE.tscn")
