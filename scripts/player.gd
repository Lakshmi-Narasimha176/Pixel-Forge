## player.gd
## First-person player controller for The Last Revenge.
## Attach to a CharacterBody3D node. Requires a Camera3D child named "Camera3D"
## and a RayCast3D child named "InteractionRay".
extends CharacterBody3D

signal interacted_with(node: Node)

# Movement
@export var move_speed: float = 4.0
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 0.0  # Set > 0 to allow jumping
@export var mouse_sensitivity: float = 0.002

# Interaction
@export var interaction_reach: float = 2.5

const GRAVITY: float = 9.8

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $InteractionRay
@onready var hud: Node = get_tree().get_first_node_in_group("hud")

var _mouse_captured: bool = false
var _interaction_target: Node = null


func _ready() -> void:
	_capture_mouse()


func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_mouse_captured = true


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_mouse_captured = false


func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	# Interaction
	if event.is_action_pressed("interact"):
		_try_interact()

	# Journal toggle
	if event.is_action_pressed("toggle_journal"):
		var journal := get_tree().get_first_node_in_group("journal")
		if journal and journal.has_method("toggle"):
			journal.toggle()

	# Escape — release mouse (useful during development / dialogue)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := move_speed * (sprint_multiplier if Input.is_action_pressed("ui_accept") else 1.0)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# Update interaction ray and HUD hint
	_update_interaction()


func _update_interaction() -> void:
	if not interaction_ray:
		return
	interaction_ray.target_position = Vector3(0.0, 0.0, -interaction_reach)
	var target: Node = null
	if interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		if collider and (collider.has_method("interact") or collider.is_in_group("interactable")):
			target = collider
	if target != _interaction_target:
		_interaction_target = target
		if hud and hud.has_method("set_interaction_hint"):
			hud.set_interaction_hint(_interaction_target != null)


func _try_interact() -> void:
	if _interaction_target == null:
		return
	emit_signal("interacted_with", _interaction_target)
	if _interaction_target.has_method("interact"):
		_interaction_target.interact()
