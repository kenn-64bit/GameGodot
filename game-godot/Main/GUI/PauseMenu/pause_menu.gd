extends CanvasLayer

## Pause Menu — press ESC in-game to toggle.
## Buttons: Resume  →  unpause
##          Restart  →  reload current scene
##          Exit     →  quit the game

const MAIN_MENU_FILE := "Main Menu.tscn"

@onready var backdrop     : ColorRect = $Backdrop
@onready var panel        : Control   = $Panel
@onready var resume_btn   : Button    = $Panel/VBox/ResumeButton
@onready var restart_btn  : Button    = $Panel/VBox/RestartButton
@onready var exit_btn     : Button    = $Panel/VBox/ExitButton

var _is_paused : bool = false

func _ready() -> void:
	# CanvasLayer must process even while the tree is paused so we can resume.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20

	# Hide everything on start — nothing visible until ESC is pressed.
	backdrop.visible = false
	panel.visible    = false

	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	exit_btn.pressed.connect(_on_exit)
	
	resume_btn.mouse_entered.connect(_on_button_hover)
	resume_btn.mouse_exited.connect(_on_button_unhover)
	restart_btn.mouse_entered.connect(_on_button_hover)
	restart_btn.mouse_exited.connect(_on_button_unhover)
	exit_btn.mouse_entered.connect(_on_button_hover)
	exit_btn.mouse_exited.connect(_on_button_unhover)

# Use _input (not _unhandled_input) so the player script can't eat the event first.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Skip on Main Menu
		var scene := get_tree().current_scene
		if scene and scene.scene_file_path.ends_with(MAIN_MENU_FILE):
			return
		if _is_paused:
			_do_resume()
		else:
			_do_open()
		get_viewport().set_input_as_handled()

# ── open / close ──────────────────────────────────────────────────────────────

func _do_open() -> void:
	_is_paused        = true
	get_tree().paused = true
	backdrop.visible  = true
	panel.visible     = true
	panel.modulate.a  = 0.0
	Input.mouse_mode  = Input.MOUSE_MODE_VISIBLE
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)

func _do_resume() -> void:
	_is_paused = false
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func():
		backdrop.visible  = false
		panel.visible     = false
		get_tree().paused = false
		Input.mouse_mode  = Input.MOUSE_MODE_HIDDEN
	)

# ── button handlers ───────────────────────────────────────────────────────────

func _on_resume() -> void:
	SfxManager.play_sfx("ui_click")
	_do_resume()

func _on_restart() -> void:
	SfxManager.play_sfx("ui_click")
	_is_paused        = false
	backdrop.visible  = false
	panel.visible     = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit() -> void:
	SfxManager.play_sfx("ui_click")
	_is_paused        = false
	backdrop.visible  = false
	panel.visible     = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main/GUI/Main Menu GUI/Main Menu.tscn")

func _on_button_hover() -> void:
	CursorManager.set_context(CursorManager.Ctx.GUI)

func _on_button_unhover() -> void:
	CursorManager.set_context(CursorManager.Ctx.DEFAULT)
