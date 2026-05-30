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

	# Load and set the custom pink cursor for the menu
	var cursor_img = preload("res://assets/Cursor-PNG/Basic/Default/cursor_menu.png")
	Input.set_custom_mouse_cursor(cursor_img, Input.CURSOR_ARROW)

	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


## ── Button handlers ───────────────────────────────────────────────────────────

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_1_PATH)

func _on_menu_pressed() -> void:
	# Instantiate the settings popup and add it on top of this scene
	var popup : Control = SETTINGS_SCENE.instantiate()
	add_child(popup)

func _on_exit_pressed() -> void:
	get_tree().quit()
