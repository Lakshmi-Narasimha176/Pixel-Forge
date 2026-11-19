extends Camera3D
## Walk / free-fly camera of the PSX Anomaly Horror Modular Kit showcase (bitkiln - https://bitkiln.itch.io): WASD or arrows
## move, the mouse looks (click to capture the mouse), Shift is faster, F switches walk / fly, E and Q (or Space and
## C) go up and down while flying, Esc frees the mouse. Movement keys are physical, so they sit in the same place on
## any keyboard layout.
##
## Walking stays inside walk_areas when there are some (x, z rectangles, the camera keeps clearance from their
## outer edges) and out of blockers. transport() moves the camera by a transform without a visible jump.

@export var walk_speed := 2.2
@export var fly_speed := 4.0
@export var fast_multiplier := 2.0
@export var mouse_sensitivity := 0.0025
@export var eye_height := 1.6
@export var flying := false
## F switches between walking and flying.
@export var can_fly := true
## The camera stays inside this box.
@export var bounds_min := Vector3(-1000, 0.2, -1000)
@export var bounds_max := Vector3(1000, 100, 1000)
## Walking stays inside the union of these areas (x, z rectangles). Empty: anywhere in the box above.
@export var walk_areas: Array[Rect2] = []
## Distance kept from the outer edges of the walk areas (the walls).
@export var clearance := 0.0
## Walking never enters these areas (x, z rectangles).
@export var blockers: Array[Rect2] = []
## Distance kept from the blockers.
@export var blocker_clearance := 0.15

var _yaw := 0.0
var _pitch := 0.0


func _ready() -> void:
	_yaw = rotation.y
	_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	var key := event as InputEventKey
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(motion.relative)
	elif key != null and key.pressed and not key.echo:
		if key.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif key.keycode == KEY_F and can_fly:
			flying = not flying
		else:
			return
		get_viewport().set_input_as_handled()


## Turns the view by a mouse movement in pixels.
func look(relative: Vector2) -> void:
	_yaw -= relative.x * mouse_sensitivity
	_pitch = clampf(_pitch - relative.y * mouse_sensitivity, deg_to_rad(-88.0), deg_to_rad(88.0))
	rotation = Vector3(_pitch, _yaw, 0.0)


## Points the camera at a world position (keeps walking and flying in step with the new view).
func face(target: Vector3) -> void:
	look_at(target)
	_yaw = rotation.y
	_pitch = rotation.x


## Moves and turns the camera by a transform (only its turn around the vertical axis is used for the view).
func transport(xf: Transform3D) -> void:
	position = xf * position
	var forward := xf.basis * Vector3.FORWARD
	_yaw += atan2(-forward.x, -forward.z)
	rotation = Vector3(_pitch, _yaw, 0.0)


func _key(a: Key, b: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0


func _process(delta: float) -> void:
	var dir := Vector3(_key(KEY_D, KEY_RIGHT) - _key(KEY_A, KEY_LEFT), 0.0, _key(KEY_S, KEY_DOWN) - _key(KEY_W, KEY_UP))
	var speed := fly_speed if flying else walk_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= fast_multiplier
	var move: Vector3
	if flying:
		move = global_transform.basis * dir
		move.y += _key(KEY_E, KEY_SPACE) - _key(KEY_Q, KEY_C)
	else:
		move = Basis(Vector3.UP, _yaw) * dir
	if move.length() > 1.0:
		move = move.normalized()
	step(move * speed * delta, delta)


## Moves the camera by an offset with the walking rules (areas, blockers, eye height). Tests drive it too.
func step(offset: Vector3, delta := 1.0 / 60.0) -> void:
	var p := position + offset
	if not flying:
		p.y = lerpf(p.y, eye_height, 1.0 - exp(-10.0 * delta))
		if not walkable(p):
			# slide along walls and around furniture: of the step along X only, along Z only, or turned by 30 / 60
			# degrees to either side, take the walkable one that goes furthest the wanted way
			var flat := Vector3(offset.x, 0.0, offset.z)
			var best := Vector3.ZERO
			var best_gain := 0.0
			for c in [Vector3(flat.x, 0.0, 0.0), Vector3(0.0, 0.0, flat.z),
					flat.rotated(Vector3.UP, deg_to_rad(30.0)) * 0.85, flat.rotated(Vector3.UP, deg_to_rad(-30.0)) * 0.85,
					flat.rotated(Vector3.UP, deg_to_rad(60.0)) * 0.6, flat.rotated(Vector3.UP, deg_to_rad(-60.0)) * 0.6]:
				var gain: float = (c as Vector3).dot(flat)
				if gain > best_gain + 1e-9 and walkable(Vector3(position.x + c.x, p.y, position.z + c.z)):
					best = c
					best_gain = gain
			p.x = position.x + best.x
			p.z = position.z + best.z
	position = p.clamp(bounds_min, bounds_max)


## True where the walking camera may stand.
func walkable(p: Vector3) -> bool:
	for r in blockers:
		if r.grow(blocker_clearance).has_point(Vector2(p.x, p.z)):
			return false
	if walk_areas.is_empty():
		return true
	for o in [Vector2(clearance, 0.0), Vector2(-clearance, 0.0), Vector2(0.0, clearance), Vector2(0.0, -clearance),
			Vector2(clearance, clearance), Vector2(-clearance, clearance), Vector2(clearance, -clearance),
			Vector2(-clearance, -clearance)]:
		if not _in_areas(Vector2(p.x, p.z) + o):
			return false
	return true


func _in_areas(q: Vector2) -> bool:
	for r in walk_areas:
		if q.x >= r.position.x and q.x <= r.end.x and q.y >= r.position.y and q.y <= r.end.y:
			return true
	return false
