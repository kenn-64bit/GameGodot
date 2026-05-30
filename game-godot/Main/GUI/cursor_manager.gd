extends CanvasLayer

enum Ctx { DEFAULT, CUBE, DOOR, GUI }

var current_ctx : int = Ctx.DEFAULT

var cursor_default : Texture2D
var cursor_cube    : Texture2D
var cursor_door    : Texture2D
var cursor_gui     : Texture2D

var sprite: Sprite2D

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	cursor_default = preload("res://assets/Cursor-PNG/Basic/Default/pointer_b_shaded.png")
	cursor_cube    = preload("res://assets/Cursor-PNG/Basic/Default/hand_open.png")
	cursor_door    = preload("res://assets/Cursor-PNG/Basic/Default/door_enter.png")
	cursor_gui     = preload("res://assets/Cursor-PNG/Basic/Default/hand_point.png")
	
	sprite = Sprite2D.new()
	sprite.texture = cursor_default
	sprite.centered = false
	add_child(sprite)
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
	if sprite:
		sprite.global_position = get_viewport().get_mouse_position()
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func set_context(ctx: Ctx) -> void:
	current_ctx = ctx
	if not sprite: return
	
	match ctx:
		Ctx.DEFAULT: sprite.texture = cursor_default
		Ctx.CUBE:    sprite.texture = cursor_cube
		Ctx.DOOR:    sprite.texture = cursor_door
		Ctx.GUI:     sprite.texture = cursor_gui
