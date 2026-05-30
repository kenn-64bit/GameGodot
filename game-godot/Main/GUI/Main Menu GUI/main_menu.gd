extends Control

const LEVEL_1_PATH   := "res://Main/Levels/Level1/ONE.tscn"
const SETTINGS_SCENE := preload("res://Main/GUI/SettingsPopup/SettingsPopup.tscn")

@onready var play_button : Button = $CenterContainer/VBoxContainer/VBoxContainer/PlayButton
@onready var menu_button : Button = $CenterContainer/VBoxContainer/VBoxContainer/MenuButton
@onready var exit_button : Button = $CenterContainer/VBoxContainer/VBoxContainer/ExitButton

func _ready() -> void:
	# Show the mouse cursor in case it was hidden by the game
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Make sure the game is unpaused when returning to the main menu
	get_tree().paused = false
	
	SfxManager.play_music_shuffle()

	CursorManager.set_context(CursorManager.Ctx.GUI)

	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	play_button.button_down.connect(_on_button_down)
	menu_button.button_down.connect(_on_button_down)
	exit_button.button_down.connect(_on_button_down)
	
	play_button.mouse_entered.connect(_on_button_hover)
	play_button.mouse_exited.connect(_on_button_unhover)
	menu_button.mouse_entered.connect(_on_button_hover)
	menu_button.mouse_exited.connect(_on_button_unhover)
	exit_button.mouse_entered.connect(_on_button_hover)
	exit_button.mouse_exited.connect(_on_button_unhover)


## ── Button handlers ───────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(LEVEL_1_PATH)

func _on_menu_pressed() -> void:
	# Instantiate the settings popup and add it on top of this scene
	var popup : Control = SETTINGS_SCENE.instantiate()
	add_child(popup)

func _on_exit_pressed() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_button_down() -> void:
	SfxManager.play_sfx("ui_click")

func _on_button_hover() -> void:
	CursorManager.set_context(CursorManager.Ctx.GUI)
	SfxManager.play_sfx("ui_hover")

func _on_button_unhover() -> void:
	CursorManager.set_context(CursorManager.Ctx.DEFAULT)
