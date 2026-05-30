extends CharacterBody2D


const SPEED          := 400.0
const JUMP_VELOCITY  := -700.0

const DASH_SPEED     := 1200.0
const DASH_DURATION  := 0.2
const DASH_COOLDOWN  := 0.5
var   is_dashing        := false
var   dash_timer        := 0.0
var   can_dash          := true
var   dash_cooldown_timer := 0.0

const COYOTE_TIME    := 0.15
var   coyote_timer   := 0.0

const FLIP_COOLDOWN  := 1.0
var   flip_timer     := 0.0
var   is_upside_down := false

const GHOST_SCENE  = preload("res://Main/MainPlayer-Updated/ghost.tscn")
const GHOST_DELAY  := 0.02
var   ghost_timer  := 0.0

@export var bob_freq := 10.0
@export var bob_amp  :=  5.0
var   _bob_time := 0.0

signal all_lives_lost
@export var starting_lives         : int   = 3
var   lives                        : int   = 3

## Drag the PlayerGui node here in the Inspector to wire up the heart HUD.
@export var gui                    : Control
var   _spawn_global                : Vector2 = Vector2.ZERO
@export var hazard_respawn_distance  := 220.0
@export var hazard_respawn_height    :=  96.0
@export var hazard_death_cooldown    :=   0.5
@export var hazard_respawn_scan_step :=  48.0
@export var hazard_respawn_scan_tries: int = 8
var   hazard_death_timer           := 0.0

@onready var sprite    : AnimatedSprite2D = $AnimatedSprite2D
@onready var camera    : Camera2D         = $Camera2D
@onready var gun_arm   : Node2D = $GunArm if has_node("GunArm") else null
@onready var _muzzle_flash : CPUParticles2D = \
	$GunArm/MuzzleFlash if has_node("GunArm/MuzzleFlash") else null
@onready var _portal_laser : Node2D = \
	$GunArm/BarrelPoint/PortalLaser if has_node("GunArm/BarrelPoint/PortalLaser") else null

var _crosshair : Node2D = null

const PORTAL_SCENE    = preload("res://Main/MainPlayer-Updated/Portal.tscn")
const PORTAL_RAY_LEN  := 2000.0
const HOLD_DISTANCE   :=   80.0
const MIN_PORTAL_DIST :=  50.0

var is_gun_equipped   := false
var portal_a          : Node2D = null
var portal_b          : Node2D = null

var held_object       : RigidBody2D = null
var is_holding_object := false

var _portal_shoot_cooldown : float = 0.0
const PORTAL_SHOOT_COOLDOWN : float = 0.40
const PORTAL_PLACE_DELAY    : float = 0.15

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	lives = starting_lives
	_spawn_global = global_position
	add_to_group("player")
	_sync_gui()  # Initialise hearts display on load.

	if gun_arm:
		gun_arm.visible = false

	# If the Inspector export didn't resolve, find the GUI at runtime.
	if not gui:
		gui = _find_gui()

	_crosshair = _find_crosshair()


## Walks the scene to find the PlayerGui Control node.
## Mirrors the _find_crosshair() pattern already in this script.
func _find_gui() -> Control:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is CanvasLayer:
				var pg := child.get_node_or_null("PlayerGui")
				if pg is Control:
					return pg as Control
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_fullscreen") or \
	   (event is InputEventKey and event.keycode == KEY_F and event.pressed):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	if event.is_action_pressed("equip_toggle"):
		toggle_gun_equip()

	if event.is_action_pressed("interact"):
		if is_holding_object:
			drop_held_object()
		else:
			try_pickup_object()

	if is_gun_equipped and not is_holding_object and _portal_shoot_cooldown <= 0.0:
		if event.is_action_pressed("shoot_portal_a"):
			shoot_portal(true)
		if event.is_action_pressed("shoot_portal_b"):
			shoot_portal(false)

func _physics_process(delta: float) -> void:
	if flip_timer                > 0: flip_timer                -= delta
	if hazard_death_timer        > 0: hazard_death_timer        -= delta
	if _portal_shoot_cooldown    > 0: _portal_shoot_cooldown    -= delta

	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta

	_update_crosshair()

	if is_gun_equipped and gun_arm:
		_aim_gun_at_mouse()

	if is_holding_object and held_object and is_instance_valid(held_object):
		_update_held_object_position()

	if Input.is_key_pressed(KEY_R) and flip_timer <= 0:
		toggle_gravity()

	if is_on_floor():
		can_dash = true

	if Input.is_action_just_pressed("dash") and not is_dashing \
	   and can_dash and dash_cooldown_timer <= 0:
		if not is_on_floor():
			can_dash = false
		_start_dash()
		dash_cooldown_timer = DASH_COOLDOWN

	if is_dashing:
		dash_timer -= delta
		_handle_ghosting(delta)
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		_update_animations(0.0)
		return

	if _is_grounded():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		var grav := get_gravity() * delta
		if is_upside_down:
			velocity -= grav
		else:
			velocity += grav

	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		coyote_timer = 0.0
		velocity.y   = -JUMP_VELOCITY if is_upside_down else JUMP_VELOCITY

	var direction := 0.0
	if Input.is_action_pressed("left"):  direction -= 1.0
	if Input.is_action_pressed("right"): direction += 1.0

	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()
	_update_animations(direction)
	_handle_camera_bob(delta)


func toggle_gun_equip() -> void:
	is_gun_equipped = !is_gun_equipped
	_sync_gui()

	if not gun_arm:
		return

	if is_gun_equipped:
		gun_arm.visible = true
		gun_arm.scale   = Vector2(0.01, 0.01)
		var tw := create_tween()
		tw.tween_property(gun_arm, "scale", Vector2.ONE, 0.15) \
		  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		if is_holding_object:
			drop_held_object()
		var tw := create_tween()
		tw.tween_property(gun_arm, "scale", Vector2(0.01, 0.01), 0.12) \
		  .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tw.tween_callback(func(): gun_arm.visible = false)


func _aim_gun_at_mouse() -> void:
	var mouse_pos   : Vector2 = get_global_mouse_position()
	var aim_dir     : Vector2 = (mouse_pos - gun_arm.global_position).normalized()
	gun_arm.rotation = aim_dir.angle()

	if gun_arm.has_node("Sprite2D"):
		gun_arm.get_node("Sprite2D").flip_v = aim_dir.x < 0.0

	if _muzzle_flash and is_instance_valid(_muzzle_flash) and gun_arm.has_node("BarrelPoint"):
		var bp : Marker2D = gun_arm.get_node("BarrelPoint")
		_muzzle_flash.position = bp.position


func shoot_portal(is_portal_a: bool) -> void:
	var ray_origin  := _get_barrel_position()

	# ── Barrel-clip guard: don't fire if gun barrel is embedded in geometry ───
	if _is_barrel_clipping():
		_spawn_fizzle(ray_origin)
		_portal_shoot_cooldown = PORTAL_SHOOT_COOLDOWN
		return

	var space_state := get_world_2d().direct_space_state
	var mouse_pos   : Vector2 = get_global_mouse_position()
	var ray_dir     : Vector2 = (mouse_pos - ray_origin).normalized()
	var ray_end     : Vector2 = ray_origin + ray_dir * PORTAL_RAY_LEN

	var query := PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
	query.collide_with_areas  = false
	query.collide_with_bodies = true

	var exclusions : Array[RID] = [get_rid()]
	if held_object and is_instance_valid(held_object):
		exclusions.append(held_object.get_rid())
	query.exclude = exclusions

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return

	var hit_pos      : Vector2 = result["position"]
	var hit_normal   : Vector2 = result["normal"]
	var hit_collider           = result["collider"]

	# ── Pre-fire surface checks (fizzle before laser so feedback is instant) ──
	if not _is_portal_surface_valid(hit_normal) or \
	   not _is_portal_surface_large_enough(space_state, hit_pos, hit_normal):
		_spawn_fizzle(hit_pos)
		_portal_shoot_cooldown = PORTAL_SHOOT_COOLDOWN
		return

	if _muzzle_flash and is_instance_valid(_muzzle_flash):
		_muzzle_flash.restart()
	if _portal_laser and is_instance_valid(_portal_laser):
		_portal_laser.fire(hit_pos)

	_portal_shoot_cooldown = PORTAL_SHOOT_COOLDOWN
	await get_tree().create_timer(PORTAL_PLACE_DELAY).timeout

	if not is_instance_valid(self):
		return

	if hit_collider.is_in_group("NoPortal") or hit_collider is RigidBody2D or hit_collider.is_in_group("Grabbable"):
		_spawn_fizzle(hit_pos)
		return

	if is_portal_a and portal_b and is_instance_valid(portal_b):
		if hit_pos.distance_to(portal_b.global_position) < MIN_PORTAL_DIST:
			_spawn_fizzle(hit_pos)
			return
	if not is_portal_a and portal_a and is_instance_valid(portal_a):
		if hit_pos.distance_to(portal_a.global_position) < MIN_PORTAL_DIST:
			_spawn_fizzle(hit_pos)
			return

	if is_portal_a:
		_place_portal_a(hit_pos, hit_normal)
	else:
		_place_portal_b(hit_pos, hit_normal)


func _place_portal_a(pos: Vector2, normal: Vector2) -> void:
	if portal_a and is_instance_valid(portal_a):
		portal_a.queue_free()
	portal_a = PORTAL_SCENE.instantiate()
	portal_a.portal_color = Color(0.2, 0.6, 1.0, 0.9)
	get_tree().current_scene.add_child(portal_a)
	portal_a.place_at(pos, normal)
	_link_portals()


func _place_portal_b(pos: Vector2, normal: Vector2) -> void:
	if portal_b and is_instance_valid(portal_b):
		portal_b.queue_free()
	portal_b = PORTAL_SCENE.instantiate()
	portal_b.portal_color = Color(1.0, 0.5, 0.1, 0.9)
	get_tree().current_scene.add_child(portal_b)
	portal_b.place_at(pos, normal)
	_link_portals()


func _link_portals() -> void:
	if portal_a and is_instance_valid(portal_a) \
	   and portal_b and is_instance_valid(portal_b):
		portal_a.linked_portal = portal_b
		portal_b.linked_portal = portal_a


func _spawn_fizzle(pos: Vector2) -> void:
	var fizzle := CPUParticles2D.new()
	fizzle.global_position   = pos
	fizzle.emitting           = true
	fizzle.one_shot           = true
	fizzle.amount             = 12
	fizzle.lifetime           = 0.4
	fizzle.emission_shape     = CPUParticles2D.EMISSION_SHAPE_SPHERE
	fizzle.emission_sphere_radius = 4.0
	fizzle.initial_velocity_min   = 60.0
	fizzle.initial_velocity_max   = 120.0
	fizzle.gravity            = Vector2.ZERO
	fizzle.color              = Color(1.0, 0.8, 0.2)
	get_tree().current_scene.add_child(fizzle)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(fizzle): fizzle.queue_free()
	)


## ── Portal-gun validation helpers ───────────────────────────────────────────

## Returns true if a short ray from the player body to the barrel hits geometry,
## meaning the gun model is clipping into a wall and a portal should not fire.
func _is_barrel_clipping() -> bool:
	if not gun_arm:
		return false
	var space_state := get_world_2d().direct_space_state
	var body_pos    : Vector2 = global_position
	var barrel_pos  : Vector2 = _get_barrel_position()
	var exclusions  : Array[RID] = [get_rid()]
	if held_object and is_instance_valid(held_object):
		exclusions.append(held_object.get_rid())
	var q := PhysicsRayQueryParameters2D.create(body_pos, barrel_pos)
	q.collide_with_areas  = false
	q.collide_with_bodies = true
	q.exclude             = exclusions
	return not space_state.intersect_ray(q).is_empty()


## Returns true if the surface normal is close enough to a cardinal axis (~20° tolerance).
## Rejects slanted faces where a portal would be skewed and visually wrong.
func _is_portal_surface_valid(hit_normal: Vector2) -> bool:
	return absf(hit_normal.x) > 0.94 or absf(hit_normal.y) > 0.94


## Shoots two short rays along the wall surface to check that there is enough
## unobstructed space on both sides to fit the portal's width (~58 px each side).
func _is_portal_surface_large_enough(space_state: PhysicsDirectSpaceState2D,
		hit_pos: Vector2, hit_normal: Vector2) -> bool:
	const HALF_PORTAL_W : float = 58.0
	var along          : Vector2 = Vector2(-hit_normal.y, hit_normal.x)
	var surface_offset : Vector2 = hit_normal * 2.0  # step slightly off the surface
	var exclusions     : Array[RID] = [get_rid()]
	if held_object and is_instance_valid(held_object):
		exclusions.append(held_object.get_rid())
	for side in [along, -along]:
		var ray_start : Vector2 = hit_pos + surface_offset
		var ray_end   : Vector2 = ray_start + side * HALF_PORTAL_W
		var q := PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		q.collide_with_areas  = false
		q.collide_with_bodies = true
		q.exclude             = exclusions
		if not space_state.intersect_ray(q).is_empty():
			return false  # obstruction within half-width → gap too small
	return true


## ── Coyote-time helper ───────────────────────────────────────────────────────

## Extended floor check: uses is_on_floor() first, then falls back to a short
## downward ray to catch sharp-corner blocks where the engine misses the contact.
func _is_grounded() -> bool:
	if is_on_floor():
		return true
	var space_state := get_world_2d().direct_space_state
	var down_dir    := -up_direction  # points toward the floor in both gravity modes
	var q := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + down_dir * 8.0
	)
	q.exclude             = [get_rid()]
	q.collide_with_bodies = true
	q.collide_with_areas  = false
	return not space_state.intersect_ray(q).is_empty()


func try_pickup_object() -> void:
	var space_state := get_world_2d().direct_space_state

	if is_gun_equipped:
		# ── Gun mode: long ray toward mouse cursor ──────────────────────────
		var ray_origin : Vector2 = _get_barrel_position()
		var mouse_pos  : Vector2 = get_global_mouse_position()
		var ray_dir    : Vector2 = (mouse_pos - ray_origin).normalized()
		var ray_end    : Vector2 = ray_origin + ray_dir * PORTAL_RAY_LEN

		var query := PhysicsRayQueryParameters2D.create(ray_origin, ray_end)
		query.collide_with_areas  = true
		query.collide_with_bodies = true
		query.exclude             = [get_rid()]

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			return

		var hit_collider = result["collider"]

		if hit_collider is Portal:
			var portal_hit : Portal = hit_collider as Portal
			if portal_hit.linked_portal and is_instance_valid(portal_hit.linked_portal):
				var dist_used := ray_origin.distance_to(result["position"])
				var remaining := PORTAL_RAY_LEN - dist_used
				_try_pickup_through_portal(portal_hit.linked_portal, remaining)
			return

		if hit_collider is RigidBody2D and hit_collider.is_in_group("Grabbable"):
			_grab_object(hit_collider)
		elif hit_collider is Area2D and hit_collider.is_in_group("GrabZone"):
			var parent : Node = hit_collider.get_parent()
			if parent is RigidBody2D and parent.is_in_group("Grabbable"):
				_grab_object(parent as RigidBody2D)
		return

	# ── No-gun mode: multi-ray + proximity fallback ─────────────────────────
	# Fix 4a: extended ray length (was HOLD_DISTANCE * 2 = 160 px).
	# Fix 4b: also cast a diagonal ray toward the waist-height hold anchor so
	#         a cube sitting at button height is reachable without crouching.
	var facing  : float   = -1.0 if sprite.flip_h else 1.0
	var down    : float   =  1.0 if not is_upside_down else -1.0
	var ray_len : float   = HOLD_DISTANCE * 3.0   # 240 px

	# Hold anchor position (where the cube will be held — waist in front).
	var hold_anchor : Vector2 = global_position + Vector2(facing * 32.0, down * 56.0)

	var rays : Array = [
		# Primary: horizontal ray forward
		{ "origin": global_position,
		  "dir":    Vector2(facing, 0.0) },
		# Diagonal: from player centre toward the hold anchor
		{ "origin": global_position,
		  "dir":    (hold_anchor - global_position).normalized() },
	]

	var exclusions : Array[RID] = [get_rid()]

	for ray_data in rays:
		var ray_end : Vector2 = ray_data["origin"] + ray_data["dir"] * ray_len
		var query := PhysicsRayQueryParameters2D.create(ray_data["origin"], ray_end)
		query.collide_with_areas  = true
		query.collide_with_bodies = true
		query.exclude             = exclusions

		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue

		var hit_collider = result["collider"]

		if hit_collider is RigidBody2D and hit_collider.is_in_group("Grabbable"):
			_grab_object(hit_collider)
			return
		elif hit_collider is Area2D and hit_collider.is_in_group("GrabZone"):
			var parent : Node = hit_collider.get_parent()
			if parent is RigidBody2D and parent.is_in_group("Grabbable"):
				_grab_object(parent as RigidBody2D)
				return

	# Fix 4c: proximity fallback — circle overlap at player centre (radius 72 px).
	# Catches cubes that are adjacent but behind a thin wall edge from the ray's POV.
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var circle      := CircleShape2D.new()
	circle.radius    = 72.0
	shape_query.shape      = circle
	shape_query.transform  = Transform2D(0.0, global_position)
	shape_query.collide_with_areas  = true
	shape_query.collide_with_bodies = true
	shape_query.exclude             = exclusions
	shape_query.collision_mask      = 0xFFFFFFFF   # check all layers

	var nearby := space_state.intersect_shape(shape_query, 8)
	var best_dist : float = INF
	var best_body : RigidBody2D = null

	for hit in nearby:
		var col : Object = hit["collider"]
		var candidate : RigidBody2D = null
		if col is RigidBody2D and (col as RigidBody2D).is_in_group("Grabbable"):
			candidate = col as RigidBody2D
		elif col is Area2D and (col as Area2D).is_in_group("GrabZone"):
			var p : Node = (col as Area2D).get_parent()
			if p is RigidBody2D and (p as RigidBody2D).is_in_group("Grabbable"):
				candidate = p as RigidBody2D
		if candidate:
			var d : float = global_position.distance_to(candidate.global_position)
			if d < best_dist:
				best_dist = d
				best_body = candidate

	if best_body:
		_grab_object(best_body)


func _try_pickup_through_portal(exit_portal: Portal, remaining: float) -> void:
	var space_state  := get_world_2d().direct_space_state
	var exit_origin  : Vector2 = exit_portal.global_position \
								 + exit_portal.surface_normal * 5.0
	var exit_end     : Vector2 = exit_origin \
								 + exit_portal.surface_normal * remaining

	var query := PhysicsRayQueryParameters2D.create(exit_origin, exit_end)
	query.collide_with_areas  = false
	query.collide_with_bodies = true
	query.exclude             = [get_rid()]

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return

	var hit = result["collider"]
	if hit is RigidBody2D and hit.is_in_group("Grabbable"):
		hit.global_position = global_position
		_grab_object(hit)


func _grab_object(obj: RigidBody2D) -> void:
	held_object       = obj
	is_holding_object = true
	if obj.has_method("grab"):
		obj.grab(self)


func drop_held_object() -> void:
	if held_object and is_instance_valid(held_object):
		if held_object.has_method("drop"):
			held_object.drop()
	held_object       = null
	is_holding_object = false


func _update_held_object_position() -> void:
	if not is_instance_valid(held_object):
		is_holding_object = false
		held_object       = null
		return

	var target_pos : Vector2
	if is_gun_equipped and gun_arm:
		var aim_dir : Vector2 = Vector2.RIGHT.rotated(gun_arm.rotation)
		var barrel  : Vector2 = _get_barrel_position()
		target_pos = barrel + aim_dir * HOLD_DISTANCE
	else:
		# Fix #5: hold the cube BELOW and slightly forward (waist/button-press height).
		# "down" flips with gravity so the cube always hangs toward the floor.
		var facing : float = -1.0 if sprite.flip_h else 1.0
		var down   : float =  1.0 if not is_upside_down else -1.0
		target_pos = global_position + Vector2(facing * 32.0, down * 56.0)

	if held_object.has_method("update_hold_position"):
		held_object.update_hold_position(target_pos)


func toggle_gravity() -> void:
	is_upside_down = !is_upside_down
	flip_timer     = FLIP_COOLDOWN

	if is_upside_down:
		up_direction          = Vector2.DOWN
		sprite.flip_v         = true
		camera.rotation_degrees = 180.0
	else:
		up_direction          = Vector2.UP
		sprite.flip_v         = false
		camera.rotation_degrees = 0.0


func _start_dash() -> void:
	is_dashing  = true
	dash_timer  = DASH_DURATION
	var dash_dir := -1.0 if sprite.flip_h else 1.0
	velocity    = Vector2(dash_dir * DASH_SPEED, 0.0)


## Reduce lives by 1, update the HUD, then either respawn near the hazard
## (lives remaining) or trigger a full game-over via die().
func take_damage(hazard_position: Vector2 = Vector2.ZERO) -> void:
	if hazard_death_timer > 0:
		return
	hazard_death_timer = hazard_death_cooldown
	lives = max(lives - 1, 0)
	_sync_gui()
	if lives <= 0:
		die()
		return
	# Respawn near the hazard, away from the spike that hit us.
	var preferred_dir := signf(global_position.x - hazard_position.x)
	if preferred_dir == 0.0:
		preferred_dir = -1.0
	global_position = _find_safe_respawn(hazard_position, preferred_dir)
	velocity   = Vector2.ZERO
	is_dashing = false


## Called by Spike hazards — subtracts 1 life and always teleports the player
## back to the level start (_spawn_global) rather than near the hazard.
func take_spike_damage() -> void:
	if hazard_death_timer > 0:
		return
	hazard_death_timer = hazard_death_cooldown
	lives = max(lives - 1, 0)
	_sync_gui()
	if lives <= 0:
		die()
		return
	# Always return to the level start on a spike hit.
	global_position = _spawn_global
	velocity        = Vector2.ZERO
	is_dashing      = false



## Called when all lives are gone. Resets to spawn point and emits all_lives_lost.
func die() -> void:
	lives           = 0
	_sync_gui()
	global_position = _spawn_global
	velocity        = Vector2.ZERO
	is_dashing      = false
	all_lives_lost.emit()


## Safe wrapper — calls gui.update_hearts() if the GUI node is available.
func _sync_gui() -> void:
	if gui and is_instance_valid(gui):
		if gui.has_method("update_hearts"):
			gui.update_hearts(lives)
		if gui.has_method("set_gun_icon_visible"):
			gui.set_gun_icon_visible(is_gun_equipped)


func handle_hazard_death(hazard_position: Vector2, wipe_all_lives: bool = false) -> void:
	if hazard_death_timer > 0:
		return
	hazard_death_timer = hazard_death_cooldown

	if wipe_all_lives:
		lives            = 0
		global_position  = _spawn_global
		velocity         = Vector2.ZERO
		is_dashing       = false
		all_lives_lost.emit()
		return

	var preferred_dir : float = signf(global_position.x - hazard_position.x)
	if preferred_dir == 0.0:
		preferred_dir = -1.0

	global_position  = _find_safe_respawn(hazard_position, preferred_dir)
	velocity         = Vector2.ZERO
	is_dashing       = false


func _find_safe_respawn(hazard_pos: Vector2, pref_dir: float) -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var query       := PhysicsPointQueryParameters2D.new()
	query.collide_with_areas  = false
	query.collide_with_bodies = true

	for dir in [pref_dir, -pref_dir]:
		for step in range(hazard_respawn_scan_tries):
			var dist      := hazard_respawn_distance + float(step) * hazard_respawn_scan_step
			var candidate := Vector2(
				hazard_pos.x + dir * dist,
				hazard_pos.y - hazard_respawn_height
			)
			query.position = candidate
			if space_state.intersect_point(query, 1).is_empty():
				return candidate

	return Vector2(
		hazard_pos.x + pref_dir * hazard_respawn_distance,
		hazard_pos.y - hazard_respawn_height
	)



func _get_barrel_position() -> Vector2:
	if gun_arm:
		if gun_arm.has_node("BarrelPoint"):
			return gun_arm.get_node("BarrelPoint").global_position
		return gun_arm.global_position
	return global_position


func _update_crosshair() -> void:
	if _crosshair and is_instance_valid(_crosshair):
		_crosshair.global_position = get_global_mouse_position()


func _find_crosshair() -> Node2D:
	if has_node("Crosshair"):
		return get_node("Crosshair") as Node2D
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "CanvasLayer2":
				var ch := child.get_node_or_null("Crosshair")
				if ch:
					return ch as Node2D
	return null


func _update_animations(direction: float) -> void:
	if is_dashing:
		sprite.play("dash")
		return

	if not is_on_floor():
		var falling : bool = (velocity.y > 0.0) if not is_upside_down else (velocity.y < 0.0)
		sprite.play("falling" if falling else "jump")
	else:
		sprite.play("run" if direction != 0.0 else "idle")


func _handle_camera_bob(delta: float) -> void:
	if is_on_floor() and abs(velocity.x) > 0.1 and not is_dashing:
		_bob_time += delta * bob_freq
		camera.offset.y = sin(_bob_time) * bob_amp
	else:
		_bob_time = 0.0
		camera.offset.y = move_toward(camera.offset.y, 0.0, bob_amp * delta * 2.0)


func _handle_ghosting(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		_spawn_ghost()
		ghost_timer = GHOST_DELAY


func _spawn_ghost() -> void:
	var ghost = GHOST_SCENE.instantiate()
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = sprite.global_position
	ghost.global_scale    = sprite.global_scale
	ghost.texture         = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h          = sprite.flip_h
	ghost.flip_v          = sprite.flip_v
	ghost.self_modulate   = Color(1, 1, 1, 0.6)
