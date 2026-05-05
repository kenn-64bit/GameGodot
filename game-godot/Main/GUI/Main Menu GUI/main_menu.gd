extends Control

@onready var play_button = $CenterContainer/VBoxContainer/VBoxContainer/PlayButton
@onready var exit_button = $CenterContainer/VBoxContainer/VBoxContainer/ExitButton

func _ready() -> void:
	# Show the mouse cursor in case it was hidden by the game
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Load and set the custom pink cursor for the menu
	var cursor_img = preload("res://assets/Cursor-PNG/Basic/Default/cursor_menu.png")
	Input.set_custom_mouse_cursor(cursor_img, Input.CURSOR_ARROW)
	
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Main/Levels/Level1/Cave_Level_One_unfinished.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
