extends Control

## Simple "You Win" end screen shown when the player exits Door 4.

@onready var _label_win  : Label  = $VBox/WinLabel
@onready var _label_sub  : Label  = $VBox/SubLabel
@onready var _btn_menu   : Button = $VBox/RestartButton

func _ready() -> void:
	# Ensure Godot hardware cursor is hidden for our Software Cursor
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Animate the title in.
	_label_win.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_btn_menu.modulate.a  = 0.0

	_btn_menu.text = "Restart Level"

	_btn_menu.text = "Restart Level"
	_btn_menu.pressed.connect(_on_restart)
	_btn_menu.button_down.connect(_on_button_down)
	_btn_menu.mouse_entered.connect(_on_button_hover)
	_btn_menu.mouse_exited.connect(_on_button_unhover)
	
	var btn_main = _btn_menu.duplicate()
	btn_main.text = "Main Menu"
	$VBox.add_child(btn_main)
	btn_main.pressed.connect(_on_main_menu)
	btn_main.button_down.connect(_on_button_down)
	btn_main.mouse_entered.connect(_on_button_hover)
	btn_main.mouse_exited.connect(_on_button_unhover)
	
	var btn_quit = _btn_menu.duplicate()
	btn_quit.text = "Quit Game"
	$VBox.add_child(btn_quit)
	btn_quit.pressed.connect(_on_quit)
	btn_quit.button_down.connect(_on_button_down)
	btn_quit.mouse_entered.connect(_on_button_hover)
	btn_quit.mouse_exited.connect(_on_button_unhover)

	var tw := create_tween().set_parallel(false)
	tw.tween_property(_label_win, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label_sub, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(_btn_menu,  "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn_main,   "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn_quit,   "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


func _on_restart() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Main/Levels/Level1/ONE.tscn")

func _on_main_menu() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://Main/GUI/Main Menu GUI/main_menu.tscn")

func _on_quit() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_button_down() -> void:
	SfxManager.play_sfx("ui_click")

func _on_button_hover() -> void:
	CursorManager.set_context(CursorManager.Ctx.GUI)
	SfxManager.play_sfx("ui_hover")

func _on_button_unhover() -> void:
	CursorManager.set_context(CursorManager.Ctx.DEFAULT)
