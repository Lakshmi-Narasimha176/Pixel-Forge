extends CharacterBody3D
## First-person player controller: movement, mouse look, flashlight, interaction, combat, and resurrection.

signal interaction_prompt_changed(prompt_text: String)

@export var walk_speed: float = 4.8
@export var sprint_speed: float = 7.2
@export var crouch_speed: float = 2.6
@export var jump_velocity: float = 4.6
@export var gravity: float = 12.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var attack_ray: RayCast3D = $Head/Camera3D/AttackRay
@onready var weapon_mesh: Node3D = $Head/Camera3D/WeaponPivot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _pitch: float = 0.0
var _is_crouching: bool = false
var _flashlight_on: bool = true
var _attack_cooldown: float = 0.0
var _flicker_timer: float = 0.0
var _current_interactable: Node = null
var _spawn_position: Vector3 = Vector3.ZERO
var _footstep_timer: float = 0.0
var _was_on_floor: bool = false


func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if flashlight:
		flashlight.visible = _flashlight_on
	if weapon_mesh:
		weapon_mesh.visible = GameState.has_weapon
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.player_died.connect(_on_player_died)
	GameState.player_resurrected.connect(_on_player_resurrected)


func _on_inventory_changed() -> void:
	if weapon_mesh:
		weapon_mesh.visible = GameState.has_weapon


func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_player_resurrected(_count: int) -> void:
	if GameState.has_checkpoint:
		global_position = GameState.checkpoint_position
	else:
		global_position = _spawn_position
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_dead or get_tree().paused:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := GameState.mouse_sensitivity
		rotate_y(-event.relative.x * sens)
		_pitch = clampf(_pitch - event.relative.y * sens, -1.42, 1.42)
		head.rotation.x = _pitch

	if event.is_action_pressed("flashlight"):
		_toggle_flashlight()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("heal"):
		GameState.heal_with_blood_bag()
	elif event.is_action_pressed("crouch"):
		_is_crouching = not _is_crouching


func _physics_process(delta: float) -> void:
	if GameState.is_dead:
		return

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	# Crouch height smoothing
	var target_head_y := 1.05 if _is_crouching else 1.65
	head.position.y = lerpf(head.position.y, target_head_y, delta * 10.0)

	# Gravity & Jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not _is_crouching:
		velocity.y = jump_velocity
		AudioManager.play_sfx("jump")

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var is_sprint := Input.is_action_pressed("sprint") and input_dir.y < 0.0
	var speed := walk_speed
	if _is_crouching:
		speed = crouch_speed
	elif is_sprint:
		speed = sprint_speed

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 10.0)

	move_and_slide()

	# Landing audio
	if is_on_floor() and not _was_on_floor:
		AudioManager.play_sfx("land")
	_was_on_floor = is_on_floor()

	# Footstep audio with surface detection
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.5:
		var step_interval := 0.45
		if _is_crouching:
			step_interval = 0.65
		elif is_sprint:
			step_interval = 0.30
		_footstep_timer += delta
		if _footstep_timer >= step_interval:
			_footstep_timer = 0.0
			var surface := _detect_surface()
			AudioManager.play_footstep(surface, is_sprint, _is_crouching)
	else:
		_footstep_timer = 0.0

	_update_flashlight(delta)
	_update_interaction_ray()


func _detect_surface() -> String:
	if get_slide_collision_count() > 0:
		var col := get_slide_collision(0)
		var collider := col.get_collider()
		if collider:
			if collider.is_in_group("wood"): return "wood"
			if collider.is_in_group("grass"): return "grass"
			if collider.is_in_group("dirt"): return "dirt"
			if collider.is_in_group("carpet"): return "carpet"
			if collider.is_in_group("metal"): return "metal"
	return "concrete"


func _toggle_flashlight() -> void:
	_flashlight_on = not _flashlight_on
	if GameState.flashlight_battery <= 0.0:
		_flashlight_on = false
	if flashlight:
		flashlight.visible = _flashlight_on
	AudioManager.play_sfx("flashlight")


func _update_flashlight(delta: float) -> void:
	if not flashlight:
		return
	if _flashlight_on:
		GameState.flashlight_battery = maxf(0.0, GameState.flashlight_battery - delta * 0.45)
		if GameState.flashlight_battery <= 0.0:
			_flashlight_on = false
			flashlight.visible = false
			return
		# Subtle low-battery flicker without heavy processing
		if GameState.flashlight_battery < 25.0:
			_flicker_timer += delta
			if _flicker_timer > 0.12:
				_flicker_timer = 0.0
				flashlight.light_energy = 1.6 if randf() > 0.25 else 0.35
		else:
			flashlight.light_energy = 2.0


func _update_interaction_ray() -> void:
	var hit_node: Node = null
	if interact_ray and interact_ray.is_colliding():
		var collider := interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			hit_node = collider
		elif collider and collider.get_parent() and collider.get_parent().has_method("interact"):
			hit_node = collider.get_parent()

	if hit_node != _current_interactable:
		_current_interactable = hit_node
		if _current_interactable and _current_interactable.has_method("get_prompt"):
			interaction_prompt_changed.emit(_current_interactable.get_prompt())
		elif _current_interactable:
			interaction_prompt_changed.emit("[E] Interact")
		else:
			interaction_prompt_changed.emit("")


func _try_interact() -> void:
	if _current_interactable and _current_interactable.has_method("interact"):
		_current_interactable.interact(self)
		_update_interaction_ray()


func _try_attack() -> void:
	if not GameState.has_weapon or _attack_cooldown > 0.0:
		return
	_attack_cooldown = 0.45
	AudioManager.play_sfx("attack")

	if weapon_mesh:
		var tween := create_tween()
		tween.tween_property(weapon_mesh, "rotation:x", -0.65, 0.08)
		tween.tween_property(weapon_mesh, "rotation:x", 0.0, 0.16)

	if attack_ray and attack_ray.is_colliding():
		var target := attack_ray.get_collider()
		if target and target.has_method("take_damage"):
			target.take_damage(GameState.weapon_damage)
			AudioManager.play_sfx("hit")
