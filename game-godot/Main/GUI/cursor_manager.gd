extends Node

enum Ctx { DEFAULT, CUBE, DOOR, GUI }

var current_ctx : int = Ctx.DEFAULT

var cursor_default : Texture2D
var cursor_cube    : Texture2D
var cursor_door    : Texture2D
var cursor_gui     : Texture2D

func _ready() -> void:
	cursor_default = preload("res://assets/Cursor-PNG/Basic/Default/pointer_b_shaded.png")
	cursor_cube    = preload("res://assets/Cursor-PNG/Basic/Default/hand_open.png")
	cursor_door    = preload("res://assets/Cursor-PNG/Basic/Default/door_enter.png")
	cursor_gui     = preload("res://assets/Cursor-PNG/Basic/Default/hand_point.png")

func set_context(ctx: Ctx) -> void:
	current_ctx = ctx
	match ctx:
		Ctx.DEFAULT:
			Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW)
		Ctx.CUBE:
			Input.set_custom_mouse_cursor(cursor_cube, Input.CURSOR_ARROW)
		Ctx.DOOR:
			Input.set_custom_mouse_cursor(cursor_door, Input.CURSOR_ARROW)
		Ctx.GUI:
			Input.set_custom_mouse_cursor(cursor_gui, Input.CURSOR_ARROW)
