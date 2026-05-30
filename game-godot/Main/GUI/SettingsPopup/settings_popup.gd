extends Control

## Settings popup — opened from the Main Menu "MENU" button.
## Controls the Master audio bus volume via a HSlider.

@onready var close_btn     : Button  = $Panel/VBox/CloseButton
@onready var master_slider : HSlider = $Panel/VBox/MasterRow/MasterSlider
@onready var master_label  : Label   = $Panel/VBox/MasterRow/MasterValueLabel
@onready var music_slider  : HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var music_label   : Label   = $Panel/VBox/MusicRow/MusicValueLabel
@onready var sfx_slider    : HSlider = $Panel/VBox/SFXRow/SFXSlider
@onready var sfx_label     : Label   = $Panel/VBox/SFXRow/SFXValueLabel

const MASTER_BUS := "Master"
const MUSIC_BUS  := "Music"
const SFX_BUS    := "SFX"

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	close_btn.button_down.connect(_on_button_down)
	close_btn.mouse_entered.connect(_on_button_hover)
	close_btn.mouse_exited.connect(_on_button_unhover)

	$Panel/VBox/MusicRow.queue_free()
	$Panel/VBox/SFXRow.queue_free()
	
	# Wait for the rows to be removed, then snap the panel size down to fit
	await get_tree().process_frame
	$Panel.custom_minimum_size.y = 220
	$Panel.size.y = 220
	$Panel.position.y += 80

	# Initialise sliders from current bus volumes
	master_slider.value = _bus_to_percent(MASTER_BUS)
	_update_label(master_label, master_slider.value)
	master_slider.value_changed.connect(func(v): _on_slider_changed(MASTER_BUS, master_label, v))

# ── helpers ───────────────────────────────────────────────────────────────────

func _bus_to_percent(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 100.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100.0

func _on_slider_changed(bus_name: String, lbl: Label, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))
	_update_label(lbl, value)

func _update_label(lbl: Label, value: float) -> void:
	lbl.text = "%d%%" % int(value)

func _on_close() -> void:
	queue_free()

func _on_button_down() -> void:
	SfxManager.play_sfx("ui_click")

func _on_button_hover() -> void:
	CursorManager.set_context(CursorManager.Ctx.GUI)
	SfxManager.play_sfx("ui_hover")

func _on_button_unhover() -> void:
	CursorManager.set_context(CursorManager.Ctx.DEFAULT)
