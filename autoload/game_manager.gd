extends Node
## GameManager — Core central coordinator for THE LAST REVENGE
## Handles game states, level transitions, player persistence, and the Resurrection System.

signal level_changed(level_index: int)
signal player_damaged(amount: float, current_health: float)
signal player_healed(amount: float, current_health: float)
signal player_died()
signal player_resurrected(checkpoint_position: Vector3)
signal inventory_updated()
signal game_paused(is_paused: bool)

const LEVEL_SCENES = {
	1: "res://scenes/levels/level_01/level_01.tscn",
	2: "res://scenes/levels/level_02/level_02.tscn",
	3: "res://scenes/levels/level_03/level_03.tscn",
	4: "res://scenes/levels/level_04/level_04.tscn",
	5: "res://scenes/levels/level_05/level_05.tscn"
}

const LEVEL_NAMES = {
	1: "CHAPTER 1: THE AWAKENING",
	2: "CHAPTER 2: THE BUTCHER",
	3: "CHAPTER 3: THE STRATEGIST",
	4: "CHAPTER 4: THE IMPOSSIBLE RETURN",
	5: "CHAPTER 5: THE BETRAYER"
}

# --- Player State ---
var player_health: float = 100.0
var max_health: float = 100.0
var player_checkpoint: Vector3 = Vector3(0, 1.2, 0)
var current_level_index: int = 1

# --- Resurrection Mechanic ---
var death_count: int = 0
var resurrection_rule_known: bool = false       # Discovered in Level 1
var resurrection_loophole_known: bool = false   # Discovered in Level 4
var final_truth_revealed: bool = false          # Discovered in Level 5

# --- Inventory & Equipment ---
var has_flashlight: bool = false
var flashlight_battery: float = 100.0
var has_weapon: bool = false
var inventory: Array[String] = []
var story_clues: Array[String] = []
var active_keys: Array[String] = []

# --- System State ---
var is_game_paused: bool = false
var current_player: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start_new_game() -> void:
	reset_state()
	change_level(1)


func reset_state() -> void:
	player_health = 100.0
	death_count = 0
	resurrection_rule_known = false
	resurrection_loophole_known = false
	final_truth_revealed = false
	has_flashlight = false
	flashlight_battery = 100.0
	has_weapon = false
	inventory.clear()
	story_clues.clear()
	active_keys.clear()


func change_level(level_index: int) -> void:
	if not LEVEL_SCENES.has(level_index):
		push_error("Invalid level index: %d" % level_index)
		return
	
	current_level_index = level_index
	var scene_path = LEVEL_SCENES[level_index]
	
	# Save progress upon level transition
	if SaveSystem:
		SaveSystem.save_game()
	
	get_tree().change_scene_to_file(scene_path)
	level_changed.emit(level_index)


func register_player(player_node: Node) -> void:
	current_player = player_node


func damage_player(amount: float) -> void:
	if player_health <= 0:
		return
	
	player_health = maxf(0.0, player_health - amount)
	player_damaged.emit(amount, player_health)
	
	if player_health <= 0.0:
		handle_player_death()


func heal_player(amount: float) -> void:
	player_health = minf(max_health, player_health + amount)
	player_healed.emit(amount, player_health)


func handle_player_death() -> void:
	death_count += 1
	player_died.emit()
	
	# Open Death / Resurrection UI
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resurrect_player() -> void:
	player_health = max_health
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if current_player and current_player.has_method("teleport_to"):
		current_player.teleport_to(player_checkpoint)
	
	player_resurrected.emit(player_checkpoint)


func add_inventory_item(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
		if item_id == "flashlight":
			has_flashlight = true
		elif item_id == "baseball_bat":
			has_weapon = true
		inventory_updated.emit()


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func add_key(key_id: String) -> void:
	if not active_keys.has(key_id):
		active_keys.append(key_id)
		inventory_updated.emit()


func has_key(key_id: String) -> bool:
	return active_keys.has(key_id)


func add_clue(clue_id: String) -> void:
	if not story_clues.has(clue_id):
		story_clues.append(clue_id)
