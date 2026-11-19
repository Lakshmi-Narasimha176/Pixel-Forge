extends CharacterBody3D
## First-person player of the PSX Anomaly Horror Modular Kit demo (bitkiln - https://bitkiln.itch.io).
##
## WASD or the arrow keys walk, the mouse looks around (click into the window to capture the mouse), Shift runs,
## F switches the flashlight and Esc frees the mouse. The keys are physical keys, so WASD stays in place on any
## keyboard layout. The kit's stairs carry a smooth ramp collider in the MeshLibraries and the anomaly scenes, so
## they need no stepping.
##
## transport() moves the player by a transform without a visible jump (the seamless teleport of the anomaly loop);
## drive_to() walks the player to a point by itself (used by the tests).

## Walking speed in meters per second.
@export var walk_speed := 2.4
## Speed while Shift is held.
@export var run_speed := 4.2
## How quickly the player reaches the wanted speed (higher = snappier).
@export var acceleration := 12.0
@export var mouse_sensitivity := 0.0025
## Height of the camera above the feet.
@export var eye_height := 1.6

## Off while the game moves the player itself.
var input_enabled := true
## drive_to(): the point the player walks to by itself (Vector3.INF: none).
var drive_target := Vector3.INF

var _pitch := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var flashlight: SpotLight3D = $Head/Camera/Flashlight


func _ready() -> void:
	add_to_group("player")
	head.position.y = eye_height
	_pitch = camera.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	var key := event as InputEventKey
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif motion != null:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		look(motion.relative)
	elif key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F:
		flashlight.visible = not flashlight.visible
	else:
		return
	get_viewport().set_input_as_handled()


## Turns the view by a mouse movement in pixels.
func look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	_pitch = clampf(_pitch - relative.y * mouse_sensitivity, deg_to_rad(-88.0), deg_to_rad(88.0))
	camera.rotation.x = _pitch


## Turns the player to a heading (degrees around Y: 0 looks north (-Z), 90 west, 180 south, 270 east).
func face(yaw_degrees: float, pitch_degrees := 0.0) -> void:
	rotation.y = deg_to_rad(yaw_degrees)
	_pitch = deg_to_rad(pitch_degrees)
	camera.rotation.x = _pitch


## Moves and turns the player by a transform (position, heading and speed), without a visible jump.
func transport(xf: Transform3D) -> void:
	global_transform = xf * global_transform
	velocity = xf.basis * velocity
	reset_physics_interpolation()


## Walks to a point by itself (Vector3.INF stops).
func drive_to(point: Vector3) -> void:
	drive_target = point


func _key(a: Key, b: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0


func _physics_process(delta: float) -> void:
	var wish := Vector3.ZERO
	var speed := walk_speed
	if drive_target != Vector3.INF:
		var d := drive_target - global_position
		d.y = 0.0
		if d.length() > 0.05:
			wish = d.normalized()
	elif input_enabled:
		var dir := Vector3(_key(KEY_D, KEY_RIGHT) - _key(KEY_A, KEY_LEFT), 0.0,
				_key(KEY_S, KEY_DOWN) - _key(KEY_W, KEY_UP))
		wish = (global_transform.basis * dir)
		wish.y = 0.0
		if wish.length() > 1.0:
			wish = wish.normalized()
		if Input.is_physical_key_pressed(KEY_SHIFT):
			speed = run_speed
	var target := wish * speed
	var k := 1.0 - exp(-acceleration * delta)
	velocity.x = lerpf(velocity.x, target.x, k)
	velocity.z = lerpf(velocity.z, target.z, k)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
