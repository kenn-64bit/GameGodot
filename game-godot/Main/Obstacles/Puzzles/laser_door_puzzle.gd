extends Node2D

@onready var _door: LaserDoor = $LaserDoor

var _panels: Array[PuzzleControlPanel] = []
var _activated: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is PuzzleControlPanel:
			_panels.append(child)
			_activated[child] = false
			child.panel_activated.connect(_on_panel_activated.bind(child))
	if _panels.is_empty():
		push_warning("LaserDoorPuzzle: add one or more PuzzleControlPanel instances as children.")
		return
	if _door == null:
		push_error("LaserDoorPuzzle: missing required child node named LaserDoor.")
		return


func _on_panel_activated(panel: PuzzleControlPanel) -> void:
	if _door.opened:
		return
	_activated[panel] = true
	for p in _panels:
		if not _activated.get(p, false):
			return
	_door.set_open(true)
