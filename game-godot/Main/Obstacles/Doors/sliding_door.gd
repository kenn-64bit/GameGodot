class_name SlidingDoor
extends Node2D

# ── Door identity ──────────────────────────────────────────────────────────────
## Which door variant to use (1–5). Determines sprite frames and next scene.
@export_range(1, 5) var door_id: int = 1

## Override the target scene path. If left empty the door uses the built-in
## level-chain mapping (door 1→L2, 2→L3, 3→L4, 4→win, 5→configurable).
@export_file("*.tscn") var next_scene_override: String = ""

# ── Proximity / interaction ────────────────────────────────────────────────────
## How close the player must be before the [E] prompt appears (pixels).
@export var interaction_radius: float = 80.0

# ── Internal scene refs ───────────────────────────────────────────────────────
@onready var _body      : AnimatableBody2D  = $DoorBody
@onready var _sprite    : AnimatedSprite2D  = $DoorBody/AnimatedSprite2D
@onready var _col       : CollisionShape2D  = $DoorBody/CollisionShape2D
@onready var _zone      : Area2D            = $ProximityArea
@onready var _label     : Label             = $InteractLabel

# ── State ─────────────────────────────────────────────────────────────────────
var _player_nearby : bool = false
var _is_open       : bool = false
var _transitioning : bool = false

# ── Level-chain map ───────────────────────────────────────────────────────────
const LEVEL_MAP : Dictionary = {
	1: "res://Main/Levels/Level 2/TWO.tscn",
	2: "res://Main/Levels/Level 3/THREE.tscn",
	3: "res://Main/Levels/Level 4/FOUR.tscn",
	4: "res://Main/GUI/WinScreen.tscn",         # created alongside this script
	5: "",                                        # must set next_scene_override
}

# ── SpriteFrame path prefixes (doors are numbered Door 1.png … or 1.png …) ──
const FRAME_PATHS : Dictionary = {
	1: { "prefix": "res://assets/Doors/Door 1/",   "pattern": "%d.png",         "count": 27 },
	2: { "prefix": "res://assets/Doors/Door 2/",   "pattern": "Door %d.png",    "count": 12 },
	3: { "prefix": "res://assets/Doors/Door 3/Door Activated - Animation/",
		 "pattern": "Door %d.png", "count": 9 },
	4: { "prefix": "res://assets/Doors/Door 4/",   "pattern": "Door %d.png",    "count":  6 },
	5: { "prefix": "res://assets/Doors/Door 5/",   "pattern": "Door %d.png",    "count":  9 },
}


func _ready() -> void:
	# Build the SpriteFrames resource from PNG files on disk.
	_build_sprite_frames()

	# Start in idle / closed state (first frame).
	_sprite.stop()
	_sprite.frame = 0

	# Wire up proximity signals.
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)
	
	# Make the door body clickable for cursor hover
	_body.input_pickable = true
	_body.mouse_entered.connect(_on_mouse_entered)
	_body.mouse_exited.connect(_on_mouse_exited)

	# Resize the proximity area to match the export radius.
	var prox_shape := (_zone.get_node("CollisionShape2D") as CollisionShape2D)
	if prox_shape and prox_shape.shape is CircleShape2D:
		(prox_shape.shape as CircleShape2D).radius = interaction_radius

	# Hide the label initially.
	_label.visible = false
	_label.modulate.a = 0.0


func _build_sprite_frames() -> void:
	var info  : Dictionary = FRAME_PATHS[door_id]
	var sf    := SpriteFrames.new()

	# "open" animation — plays through all frames once, then stops.
	sf.add_animation(&"open")
	sf.set_animation_loop(&"open", false)
	sf.set_animation_speed(&"open", 12.0)   # ~12 fps feels snappy

	for i in range(1, int(info["count"]) + 1):
		var path : String = info["prefix"] + (info["pattern"] % i)
		var tex  : Texture2D = load(path)
		if tex:
			sf.add_frame(&"open", tex)

	# "idle" animation — just the first frame, looped (door closed).
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.set_animation_speed(&"idle", 1.0)
	if sf.get_frame_count(&"open") > 0:
		sf.add_frame(&"idle", sf.get_frame_texture(&"open", 0))

	_sprite.sprite_frames = sf
	_sprite.play(&"idle")


func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _is_open and not _transitioning:
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_open_and_transition()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_show_label(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if not _is_open:
			_show_label(false)


func _on_mouse_entered() -> void:
	CursorManager.set_context(CursorManager.Ctx.DOOR)


func _on_mouse_exited() -> void:
	CursorManager.set_context(CursorManager.Ctx.DEFAULT)


func _show_label(show: bool) -> void:
	_label.visible = true
	var tw := create_tween()
	tw.tween_property(_label, "modulate:a", 1.0 if show else 0.0, 0.25) \
	  .set_ease(Tween.EASE_OUT)
	if not show:
		tw.tween_callback(func(): _label.visible = false)


func _open_and_transition() -> void:
	_transitioning = true
	_show_label(false)
	SfxManager.play_sfx("door_open")

	# Play the opening animation.
	_sprite.play(&"open")
	await _sprite.animation_finished

	# Disable collision so player doesn't hit a ghost wall.
	_col.set_deferred("disabled", true)
	_is_open = true

	# Brief pause so the player can see the door fully open.
	await get_tree().create_timer(0.35).timeout

	# Screen-fade out before switching.
	await _fade_out()

	# Load next scene.
	var target : String = next_scene_override
	if target.is_empty():
		target = LEVEL_MAP.get(door_id, "")

	if not target.is_empty() and ResourceLoader.exists(target):
		get_tree().change_scene_to_file(target)
	else:
		# Graceful fallback — just re-open current scene.
		get_tree().reload_current_scene()


func _fade_out() -> void:
	# Use a full-screen ColorRect overlay to fade to black.
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)

	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)

	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
	await tw.finished
