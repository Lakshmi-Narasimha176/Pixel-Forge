extends CharacterBody3D
## Low-cost readable AI: patrol, sight, search, chase, wind-up attack, recover, die.

enum State { IDLE, PATROL, SEARCH, CHASE, ATTACK, DEAD }

@export var enemy_name := "Lost Soul"
@export var max_health := 100
@export var move_speed := 3.2
@export var attack_damage := 18
@export_range(0.0, 0.85, 0.05) var damage_resistance := 0.0
@export_range(0.0, 0.8, 0.05) var enrage_threshold := 0.0
@export_range(1.0, 1.8, 0.05) var enrage_speed_multiplier := 1.0
@export var detect_range := 14.0
@export var attack_range := 2.1
@export var ranged_attack := false
@export var ranged_attack_range := 13.0
@export var attack_cooldown := 1.4
@export var attack_windup := 0.6
@export var gravity := 14.0
@export var patrol_offsets: Array[Vector3] = [Vector3(4, 0, 0), Vector3(-4, 0, 0)]
@export var death_objective_id := ""
@export var death_flag := ""
@export var reward_item_id := ""
@export_multiline var boss_defeat_line := ""

var current_health := 100
var state: State = State.PATROL
var _player: Node3D
var _patrol_points: Array[Vector3] = []
var _patrol_index := 0
var _attack_timer := 0.0
var _windup_timer := 0.0
var _search_timer := 0.0
var _origin := Vector3.ZERO
var _last_known_position := Vector3.ZERO
var _attack_announced := false
var _enraged := false


func _ready() -> void:
	current_health = max_health
	_origin = global_position
	for offset: Vector3 in patrol_offsets:
		_patrol_points.append(_origin + offset)
	if _patrol_points.is_empty():
		state = State.IDLE
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _windup_timer > 0.0:
		_windup_timer = maxf(0.0, _windup_timer - delta)
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0] as Node3D

	if _player and not GameState.is_dead:
		var distance := global_position.distance_to(_player.global_position)
		if distance <= detect_range and _has_line_of_sight():
			_search_timer = 3.0
			_last_known_position = _player.global_position
			if (ranged_attack and distance <= ranged_attack_range) or (not ranged_attack and distance <= attack_range):
				state = State.ATTACK
			else:
				state = State.CHASE
		elif _search_timer > 0.0:
			_search_timer -= delta
			state = State.SEARCH
		elif not _patrol_points.is_empty():
			state = State.PATROL
		else:
			state = State.IDLE

	match state:
		State.IDLE:
			_stop()
		State.PATROL:
			_do_patrol(delta)
		State.SEARCH:
			_do_search(delta)
		State.CHASE:
			_do_chase(delta)
		State.ATTACK:
			_do_attack(delta)
	move_and_slide()


func _do_patrol(delta: float) -> void:
	var target := _patrol_points[_patrol_index]
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() < 0.7:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
		_stop()
		return
	_move_direction(direction.normalized(), move_speed * 0.55, delta)


func _do_search(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_stop()
		return
	var direction := _last_known_position - global_position
	direction.y = 0.0
	if direction.length() > 1.0:
		_move_direction(direction.normalized(), move_speed * 0.8, delta)
	else:
		_stop()


func _do_chase(delta: float) -> void:
	if not _player:
		return
	var direction := _player.global_position - global_position
	direction.y = 0.0
	if direction.length() > 0.1:
		_move_direction(direction.normalized(), move_speed * (enrage_speed_multiplier if _enraged else 1.0), delta)


func _do_attack(delta: float) -> void:
	_stop()
	if not _player:
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > 0.05:
		_face_direction(to_player.normalized(), delta)
	if _attack_timer > 0.0:
		return
	if _windup_timer <= 0.0 and not _attack_announced:
		_windup_timer = attack_windup
		_attack_announced = true
		AudioManager.play_sfx("attack")
		GameState.show_subtitle(enemy_name, "The attack is coming — evade now!", 0.8)
		return
	if _windup_timer <= 0.0 and _attack_announced:
		_attack_announced = false
		_attack_timer = attack_cooldown
		if _has_line_of_sight():
			var distance := global_position.distance_to(_player.global_position)
			if (ranged_attack and distance <= ranged_attack_range) or (not ranged_attack and distance <= attack_range + 0.25):
				GameState.take_damage(attack_damage)
		GameState.show_subtitle(enemy_name, "Recover!", 0.35)


func _move_direction(direction: Vector3, speed: float, delta: float) -> void:
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face_direction(direction, delta)


func _stop() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _has_line_of_sight() -> bool:
	if not _player or not is_instance_valid(_player):
		return false
	var origin := global_position + Vector3.UP * 1.25
	var target := _player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, delta * 5.0)


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	current_health -= maxi(1, roundi(float(amount) * (1.0 - damage_resistance)))
	state = State.CHASE
	_search_timer = 3.0
	if _player and is_instance_valid(_player):
		_last_known_position = _player.global_position
	if enrage_threshold > 0.0 and not _enraged and current_health <= max_health * enrage_threshold:
		_enraged = true
		GameState.show_subtitle(enemy_name, "You knew every move I would make!", 1.7)
	AudioManager.play_sfx("hit")
	if current_health <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	if not death_objective_id.is_empty():
		ObjectiveManager.complete_objective(death_objective_id)
	if not death_flag.is_empty():
		GameState.set_flag(death_flag, true)
	if not reward_item_id.is_empty():
		GameState.add_item(reward_item_id)
	if not boss_defeat_line.is_empty():
		GameState.show_subtitle(enemy_name, boss_defeat_line, 4.5)
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.45)
	tween.tween_callback(queue_free)
