extends CharacterBody3D
## Third-person, camera-relative controller with a small offline weapon loop.

signal interaction_prompt_changed(prompt_text: String)

@export var walk_speed := 4.0
@export var run_speed := 5.4
@export var sprint_speed := 6.8
@export var jump_velocity := 4.2
@export var gravity := 14.0
@export var look_sensitivity := 0.0022

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var flashlight: SpotLight3D = $CameraPivot/SpringArm3D/Camera3D/Flashlight
@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var left_leg: MeshInstance3D = $Visual/LeftLeg
@onready var right_leg: MeshInstance3D = $Visual/RightLeg
@onready var weapon_root: Node3D = $Visual/WeaponRoot
@onready var weapon_model: Node3D = $Visual/WeaponRoot/WeaponModel
@onready var visual: Node3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _pitch := 0.16
var _crouched := false
var _flashlight_on := true
var _fire_timer := 0.0
var _reload_timer := 0.0
var _last_chance_timer := 0.0
var _last_chance_cooldown := 0.0
var _flicker_timer := 0.0
var _current_interactable: Node
var _last_chance_hint_shown := false


func _ready() -> void:
	_ensure_input_actions()
	var capsule := collision_shape.shape.duplicate() as CapsuleShape3D
	collision_shape.shape = capsule
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.health_changed.connect(_on_health_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.player_died.connect(_on_player_died)
	GameState.player_resurrected.connect(_on_player_resurrected)
	_update_weapon_view()
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_flashlight_on = GameState.flashlight_enabled and GameState.flashlight_battery > 0.0
	if flashlight:
		flashlight.visible = _flashlight_on


func _ensure_input_actions() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_backward", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("sprint", KEY_SHIFT)
	_bind_key("crouch", KEY_C)
	_bind_key("jump", KEY_SPACE)
	_bind_key("interact", KEY_E)
	_bind_key("flashlight", KEY_F)
	_bind_key("heal", KEY_Q)
	_bind_key("reload", KEY_R)
	_bind_key("weapon_next", KEY_TAB)
	_bind_key("weapon_1", KEY_1)
	_bind_key("weapon_2", KEY_2)
	_bind_key("weapon_3", KEY_3)
	_bind_key("last_chance", KEY_V)
	_bind_key("pause", KEY_ESCAPE)
	_bind_key("journal", KEY_J)
	_bind_mouse("fire", MOUSE_BUTTON_LEFT)
	_bind_mouse("aim", MOUSE_BUTTON_RIGHT)
	if not InputMap.has_action("run"):
		InputMap.add_action("run")
		InputMap.action_add_event("run", _key_event(KEY_CTRL))


func _bind_key(action: StringName, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		InputMap.action_add_event(action, _key_event(key))


func _key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	return event


func _bind_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_dead or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		GameState.select_next_weapon()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity: float = GameState.mouse_sensitivity if GameState.mouse_sensitivity > 0.0 else look_sensitivity
		rotate_y(-event.relative.x * sensitivity)
		_pitch = clampf(_pitch + event.relative.y * sensitivity, deg_to_rad(-50.0), deg_to_rad(52.0))
		camera_pivot.rotation.x = _pitch
	elif event.is_action_pressed("fire"):
		if GameState.current_weapon != "rifle":
			_fire_weapon()
	elif event.is_action_pressed("flashlight"):
		_toggle_flashlight()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("reload"):
		_start_reload()
	elif event.is_action_pressed("heal"):
		GameState.heal_with_blood_bag()
	elif event.is_action_pressed("crouch"):
		_crouched = not _crouched
	elif event.is_action_pressed("weapon_next"):
		GameState.select_next_weapon()
	elif event.is_action_pressed("weapon_1"):
		_select_weapon(0)
	elif event.is_action_pressed("weapon_2"):
		_select_weapon(1)
	elif event.is_action_pressed("weapon_3"):
		_select_weapon(2)
	elif event.is_action_pressed("last_chance"):
		_activate_last_chance()


func _physics_process(delta: float) -> void:
	if GameState.is_dead:
		return
	_fire_timer = maxf(0.0, _fire_timer - delta)
	_reload_timer = maxf(0.0, _reload_timer - delta)
	_last_chance_timer = maxf(0.0, _last_chance_timer - delta)
	_last_chance_cooldown = maxf(0.0, _last_chance_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not _crouched:
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (global_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := walk_speed
	if _crouched:
		speed = 2.2
	elif Input.is_action_pressed("sprint"):
		speed = sprint_speed
	elif Input.is_action_pressed("run"):
		speed = run_speed
	if _last_chance_timer > 0.0:
		speed *= 1.3
	velocity.x = direction.x * speed if input_dir.length_squared() > 0.01 else move_toward(velocity.x, 0.0, speed * delta * 8.0)
	velocity.z = direction.z * speed if input_dir.length_squared() > 0.01 else move_toward(velocity.z, 0.0, speed * delta * 8.0)
	move_and_slide()
	_update_flashlight(delta)
	_update_interaction_ray()
	_update_camera_and_pose(delta, input_dir.length())
	if Input.is_action_pressed("fire") and GameState.current_weapon == "rifle" and _fire_timer <= 0.0:
		_fire_weapon()


func _update_camera_and_pose(delta: float, movement: float) -> void:
	var target_camera_height := 1.02 if _crouched else 1.38
	camera_pivot.position.y = lerpf(camera_pivot.position.y, target_camera_height, delta * 10.0)
	var target_height := 1.25 if _crouched else 1.8
	(collision_shape.shape as CapsuleShape3D).height = target_height
	collision_shape.position.y = target_height * 0.5
	visual.scale.y = lerpf(visual.scale.y, 0.7 if _crouched else 1.0, delta * 10.0)
	visual.position.y = lerpf(visual.position.y, 0.08 if _crouched else 0.0, delta * 10.0)
	if camera:
		camera.fov = lerpf(camera.fov, 58.0 if Input.is_action_pressed("aim") else 72.0, delta * 8.0)
	if spring_arm:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, 3.0 if Input.is_action_pressed("aim") else 4.2, delta * 6.0)
	var pace := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var swing := sin(Time.get_ticks_msec() * 0.012 * (pace / walk_speed)) * minf(0.55, movement * 0.2)
	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing
	weapon_root.position.y = 1.18 + absf(swing) * 0.035


func _update_interaction_ray() -> void:
	var hit := _raycast(3.2)
	var hit_node: Node = hit.get("collider") as Node if not hit.is_empty() else null
	if hit_node and not hit_node.has_method("interact") and hit_node.get_parent() and hit_node.get_parent().has_method("interact"):
		hit_node = hit_node.get_parent()
	if hit_node and not hit_node.has_method("interact"):
		hit_node = null
	if hit_node != _current_interactable:
		_current_interactable = hit_node
		if _current_interactable and _current_interactable.has_method("get_prompt"):
			interaction_prompt_changed.emit(_current_interactable.get_prompt())
		elif _current_interactable:
			interaction_prompt_changed.emit("[E] Interact")
		else:
			interaction_prompt_changed.emit("")


func _raycast(ray_range: float, include_areas: bool = true) -> Dictionary:
	var start := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - camera.global_basis.z * ray_range)
	query.exclude = [get_rid()]
	query.collide_with_areas = include_areas
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)


func _try_interact() -> void:
	if is_instance_valid(_current_interactable) and _current_interactable.has_method("interact"):
		_current_interactable.interact(self)
		AudioManager.play_sfx("interact")
		_update_interaction_ray()


func _fire_weapon() -> void:
	if GameState.current_weapon.is_empty():
		return
	var data: Dictionary = GameState.WEAPONS[GameState.current_weapon]
	_fire_timer = float(data["rate"])
	if GameState.current_weapon == "bat":
		AudioManager.play_sfx("attack")
		_weapon_swing()
	else:
		if _reload_timer > 0.0:
			return
		if not GameState.spend_ammo():
			AudioManager.play_sfx("error")
			return
		AudioManager.play_sfx("fire")
		_recoil()
		var ray_range := float(data["range"])
		var hit := _raycast(ray_range, false)
		if not hit.is_empty():
			var target: Node = hit.get("collider")
			var damage := int(data["damage"])
			if GameState.current_weapon == "shotgun":
				damage = maxi(5, int(damage * clampf(1.0 - camera.global_position.distance_to(hit.position) / ray_range, 0.25, 1.0)))
			if target and target.has_method("take_damage"):
				target.take_damage(int(float(damage) * (1.5 if _last_chance_timer > 0.0 else 1.0)))
				AudioManager.play_sfx("hit")
			elif target and target.get_parent() and target.get_parent().has_method("take_damage"):
				target.get_parent().take_damage(damage)
				AudioManager.play_sfx("hit")


func _start_reload() -> void:
	if GameState.current_weapon.is_empty() or not GameState.reload_weapon():
		return
	_reload_timer = float(GameState.WEAPONS[GameState.current_weapon]["reload"])
	AudioManager.play_sfx("reload")
	GameState.show_subtitle("Weapon", "Reloading %s…" % GameState.WEAPONS[GameState.current_weapon]["title"], _reload_timer)


func _weapon_swing() -> void:
	var target_hit := _raycast(float(GameState.WEAPONS["bat"]["range"]), false)
	if not target_hit.is_empty():
		var target: Node = target_hit.get("collider")
		if target and target.has_method("take_damage"):
			target.take_damage(int(float(GameState.weapon_damage) * (1.4 if _last_chance_timer > 0.0 else 1.0)))
	var tween := create_tween()
	tween.tween_property(weapon_model, "rotation:z", -0.9, 0.08)
	tween.tween_property(weapon_model, "rotation:z", 0.0, 0.18)


func _recoil() -> void:
	_pitch = clampf(_pitch - deg_to_rad(0.8), deg_to_rad(-50.0), deg_to_rad(52.0))
	camera_pivot.rotation.x = _pitch


func _select_weapon(index: int) -> void:
	if index < GameState.owned_weapons.size():
		GameState.current_weapon = GameState.owned_weapons[index]
		GameState.weapon_damage = int(GameState.WEAPONS[GameState.current_weapon]["damage"])
		GameState.inventory_changed.emit()


func _update_weapon_view() -> void:
	if not is_node_ready():
		return
	weapon_model.visible = GameState.has_weapon
	var color := Color(0.25, 0.26, 0.28)
	if GameState.current_weapon == "bat":
		color = Color(0.28, 0.12, 0.08)
	elif GameState.current_weapon == "shotgun":
		color = Color(0.2, 0.23, 0.21)
	elif GameState.current_weapon == "rifle":
		color = Color(0.12, 0.15, 0.16)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	var weapon_mesh := weapon_model.get_node_or_null("WeaponMesh") as MeshInstance3D
	if weapon_mesh:
		weapon_mesh.material_override = material
		weapon_mesh.visible = GameState.current_weapon != "bat"
	var grip := weapon_model.get_node_or_null("Grip") as MeshInstance3D
	if grip:
		grip.visible = GameState.current_weapon != "bat"
	var bat := weapon_model.get_node_or_null("Bat") as MeshInstance3D
	if bat:
		bat.visible = GameState.current_weapon == "bat"


func _activate_last_chance() -> void:
	if GameState.health > 30 or _last_chance_cooldown > 0.0:
		GameState.show_subtitle("Soul Focus", "Last Chance is ready only when health is critical.", 2.0)
		return
	_last_chance_timer = 5.0
	_last_chance_cooldown = 40.0
	GameState.show_subtitle("The Returned", "LAST CHANCE — move fast and strike back!", 3.0)


func _toggle_flashlight() -> void:
	if GameState.flashlight_battery <= 0.0:
		GameState.show_subtitle("Flashlight", "The battery is dead. Find another cell.", 2.0)
		return
	_flashlight_on = not _flashlight_on
	GameState.flashlight_enabled = _flashlight_on
	flashlight.visible = _flashlight_on
	AudioManager.play_sfx("flashlight")


func _update_flashlight(delta: float) -> void:
	if not _flashlight_on or not flashlight:
		return
	GameState.flashlight_battery = maxf(0.0, GameState.flashlight_battery - delta * 0.08)
	if GameState.flashlight_battery <= 0.0:
		_flashlight_on = false
		GameState.flashlight_enabled = false
		flashlight.visible = false
	elif GameState.flashlight_battery < 20.0:
		_flicker_timer += delta
		if _flicker_timer >= 0.3:
			_flicker_timer = 0.0
			flashlight.light_energy = 1.0 if randf() > 0.22 else 0.15


func _on_inventory_changed() -> void:
	_update_weapon_view()


func _on_health_changed(new_health: int, _max_health: int) -> void:
	if new_health <= 30 and new_health > 0 and not _last_chance_hint_shown:
		_last_chance_hint_shown = true
		GameState.show_subtitle("The Tether", "Your soul frays. Press V for Last Chance.", 2.0)


func _on_player_died() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_player_resurrected(_count: int) -> void:
	velocity = Vector3.ZERO
	if GameState.has_checkpoint:
		global_position = GameState.checkpoint_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

