extends Node
class_name PuzzleController

## Wires laser doors to control panels for a self-contained puzzle group.
## Supports TileMapLayer-painted scenes and direct child instances (legacy prefabs).

const DOOR_SCENE_TILE_ID := 0
const PANEL_SCENE_TILE_ID := 1

@export var auto_place_demo_tiles: bool = false
@export var demo_door_cell: Vector2i = Vector2i(0, 0)
@export var demo_panel_cells: Array[Vector2i] = [Vector2i(4, 0)]

var _door: LaserDoor
var _panels: Array[PuzzleControlPanel] = []
var _activated: Dictionary = {}


func _ready() -> void:
	call_deferred(&"_setup_puzzle")


func _setup_puzzle() -> void:
	if auto_place_demo_tiles:
		_place_demo_tiles_if_empty()
	await _await_tilemap_scenes()
	_door = _find_door()
	_panels = _find_panels()
	if _door == null:
		push_error(
			"%s: no LaserDoor found. Check Door TileMapLayer has scene tile id %d."
			% [name, DOOR_SCENE_TILE_ID]
		)
		return
	if _panels.is_empty():
		push_warning("%s: no PuzzleControlPanel instances found." % name)
		return
	for panel in _panels:
		_activated[panel] = false
		panel.panel_activated.connect(_on_panel_activated.bind(panel))


func _puzzle_root() -> Node:
	return get_parent()


func _get_layer(layer_name: String) -> TileMapLayer:
	var root := _puzzle_root()
	if root == null:
		return null
	return root.get_node_or_null(NodePath(layer_name)) as TileMapLayer


func _await_tilemap_scenes() -> void:
	var door_layer := _get_layer("Door")
	var controller_layer := _get_layer("Controller")
	if door_layer:
		door_layer.update_internals()
	if controller_layer:
		controller_layer.update_internals()
	if door_layer or controller_layer:
		await get_tree().process_frame


func _find_door() -> LaserDoor:
	var door_layer := _get_layer("Door")
	if door_layer:
		var from_layer := _find_laser_door_in_tree(door_layer)
		if from_layer:
			return from_layer
	var direct := get_node_or_null(^"LaserDoor")
	if direct is LaserDoor:
		return direct as LaserDoor
	var root := _puzzle_root()
	if root:
		var from_root := _find_laser_door_in_tree(root)
		if from_root:
			return from_root
	for node in get_tree().get_nodes_in_group(&"puzzle_door"):
		if _owns_puzzle_node(node) and node is LaserDoor:
			return node as LaserDoor
	return null


func _find_panels() -> Array[PuzzleControlPanel]:
	var panels: Array[PuzzleControlPanel] = []
	var controller_layer := _get_layer("Controller")
	if controller_layer:
		_append_unique_panels(panels, _find_control_panels_in_tree(controller_layer))
	for child in get_children():
		if child is PuzzleControlPanel:
			_append_unique_panels(panels, [child])
	var root := _puzzle_root()
	if root and panels.is_empty():
		_append_unique_panels(panels, _find_control_panels_in_tree(root))
	if panels.is_empty():
		for node in get_tree().get_nodes_in_group(&"puzzle_panel"):
			if _owns_puzzle_node(node) and node is PuzzleControlPanel:
				_append_unique_panels(panels, [node as PuzzleControlPanel])
	return panels


func _owns_puzzle_node(node: Node) -> bool:
	var root := _puzzle_root()
	return root != null and root.is_ancestor_of(node)


func _find_laser_door_in_tree(root: Node) -> LaserDoor:
	for child in root.get_children():
		if child is LaserDoor:
			return child as LaserDoor
		var nested := _find_laser_door_in_tree(child)
		if nested:
			return nested
	return null


func _find_control_panels_in_tree(root: Node) -> Array[PuzzleControlPanel]:
	var found: Array[PuzzleControlPanel] = []
	for child in root.get_children():
		if child is PuzzleControlPanel:
			found.append(child as PuzzleControlPanel)
		found.append_array(_find_control_panels_in_tree(child))
	return found


func _append_unique_panels(target: Array[PuzzleControlPanel], candidates: Array[PuzzleControlPanel]) -> void:
	for panel in candidates:
		if not target.has(panel):
			target.append(panel)


func _place_demo_tiles_if_empty() -> void:
	var door_layer := _get_layer("Door")
	if door_layer and door_layer.get_used_cells().is_empty():
		door_layer.set_cell(demo_door_cell, 0, Vector2i.ZERO, DOOR_SCENE_TILE_ID)
		door_layer.update_internals()
	var controller_layer := _get_layer("Controller")
	if controller_layer and controller_layer.get_used_cells().is_empty():
		for cell in demo_panel_cells:
			controller_layer.set_cell(cell, 0, Vector2i.ZERO, PANEL_SCENE_TILE_ID)
		controller_layer.update_internals()


func _on_panel_activated(panel: PuzzleControlPanel) -> void:
	if _door == null or _door.opened:
		return
	_activated[panel] = true
	for p in _panels:
		if not _activated.get(p, false):
			return
	_door.set_open(true)
