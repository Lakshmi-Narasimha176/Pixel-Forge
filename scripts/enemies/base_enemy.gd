extends CharacterBody3D
## Reusable horror enemy AI: Idle, Patrol, Chase, Attack, Take Damage, Die.

enum State { IDLE, PATROL, CHASE, ATTACK, DEAD }

@export var enemy_name: String = "Stalker"
@export var max_health: int = 100
@export var move_speed: float = 3.2
@export var attack_damage: int = 20
@export var detect_range: float = 14.0
@export var attack_range: float = 2.1
@export var attack_cooldown: float = 1.4
@export var gravity: float = 12.0
@export var patrol_offsets: Array[Vector3] = [Vector3(4, 0, 0), Vector3(-4, 0, 0)]
@export var death_objective_id: String = ""
@export var death_flag: String = ""
@export var reward_item_id: String = ""
@export var boss_defeat_line: String = ""

var current_health: int
var state: State = State.PATROL
var _player: Node3D = null
var _patrol_points: Array[Vector3] = []
var _patrol_index: int = 0
var _attack_timer: float = 0.0
var _origin: Vector3 = Vector3.ZERO


func _ready() -> void:
	current_health = max_health
	_origin = global_position
	for offset in patrol_offsets:
		_patrol_points.append(_origin + offset)
	if _patrol_points.is_empty():
		state = State.IDLE


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if _attack_timer > 0.0:
		_attack_timer -= delta

	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node3D

	if _player and not GameState.is_dead:
		var dist := global_position.distance_to(_player.global_position)
		if dist <= attack_range:
			state = State.ATTACK
		elif dist <= detect_range:
			state = State.CHASE
		elif not _patrol_points.is_empty():
			state = State.PATROL
		else:
			state = State.IDLE

	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)
		State.ATTACK:
			_do_attack()

	move_and_slide()


func _do_patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	var target := _patrol_points[_patrol_index]
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.7:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	else:
		dir = dir.normalized()
		velocity.x = dir.x * (move_speed * 0.65)
		velocity.z = dir.z * (move_speed * 0.65)
		_face_direction(dir, delta)


func _do_chase(delta: float) -> void:
	if _player == null:
		return
	var dir := _player.global_position - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		_face_direction(dir, delta)


func _do_attack() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _player:
		var dir := (_player.global_position - global_position)
		dir.y = 0.0
		if dir.length() > 0.05:
			look_at(global_position + dir.normalized(), Vector3.UP)
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		GameState.take_damage(attack_damage)


func _face_direction(dir: Vector3, delta: float) -> void:
	var target_angle := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, delta * 6.0)


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	current_health -= amount
	GameState.show_subtitle("Combat", "%s HP: %d/%d" % [enemy_name, maxi(0, current_health), max_health], 1.5)
	if current_health <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	if not death_objective_id.is_empty():
		ObjectiveManager.complete_objective(death_objective_id)
	if not death_flag.is_empty():
		GameState.set_flag(death_flag, true)
	if not reward_item_id.is_empty():
		GameState.add_item(reward_item_id)
	if not boss_defeat_line.is_empty():
		GameState.show_subtitle(enemy_name, boss_defeat_line, 4.5)
	queue_free()
