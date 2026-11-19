extends Node
## Global game state: player health, inventory, progression flags, resurrection, and settings.

signal health_changed(new_health: int, max_health: int)
signal inventory_changed()
signal flag_changed(flag_name: String, value: Variant)
signal player_died()
signal player_resurrected(resurrection_count: int)
signal subtitle_requested(speaker: String, text: String, duration: float)

const MAX_HEALTH: int = 100

var health: int = MAX_HEALTH
var blood_bags: int = 1
var has_weapon: bool = false
var weapon_damage: int = 25
var flashlight_battery: float = 100.0
var is_dead: bool = false

# Resurrection core mechanic state
var resurrection_count: int = 0
var resurrection_rule_discovered: bool = false
var resurrection_loophole_found: bool = false

# Progression & level tracking
var current_level_id: String = "level_01"
var checkpoint_position: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false
var progression_flags: Dictionary = {}
var collected_items: Array[String] = []
var puzzle_states: Dictionary = {}

# Settings
var mouse_sensitivity: float = 0.0025
var master_volume: float = 0.8


func reset_for_new_game() -> void:
	health = MAX_HEALTH
	blood_bags = 1
	has_weapon = false
	flashlight_battery = 100.0
	is_dead = false
	resurrection_count = 0
	resurrection_rule_discovered = false
	resurrection_loophole_found = false
	current_level_id = "level_01"
	checkpoint_position = Vector3.ZERO
	has_checkpoint = false
	progression_flags.clear()
	collected_items.clear()
	puzzle_states.clear()
	health_changed.emit(health, MAX_HEALTH)
	inventory_changed.emit()


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if AudioManager:
		AudioManager.play_sfx("damage")
	if health <= 0:
		is_dead = true
		player_died.emit()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	health = mini(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)


func heal_with_blood_bag() -> bool:
	if is_dead or blood_bags <= 0 or health >= MAX_HEALTH:
		return false
	blood_bags -= 1
	heal(35)
	inventory_changed.emit()
	if AudioManager:
		AudioManager.play_sfx("heal")
	show_subtitle("System", "Used Blood Bag (+35 HP).", 2.5)
	return true


func add_blood_bag(count: int = 1) -> void:
	blood_bags += count
	inventory_changed.emit()


func equip_weapon() -> void:
	has_weapon = true
	inventory_changed.emit()


func add_item(item_id: String) -> void:
	if not collected_items.has(item_id):
		collected_items.append(item_id)
		inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return collected_items.has(item_id)


func set_flag(flag_name: String, value: Variant = true) -> void:
	progression_flags[flag_name] = value
	if flag_name == "resurrection_rule_discovered":
		resurrection_rule_discovered = bool(value)
	elif flag_name == "resurrection_loophole_found":
		resurrection_loophole_found = bool(value)
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return progression_flags.get(flag_name, default_value)


func set_checkpoint(pos: Vector3) -> void:
	checkpoint_position = pos
	has_checkpoint = true


func trigger_resurrection() -> void:
	resurrection_count += 1
	is_dead = false
	health = MAX_HEALTH
	flashlight_battery = maxf(flashlight_battery, 40.0)
	health_changed.emit(health, MAX_HEALTH)
	player_resurrected.emit(resurrection_count)
	if AudioManager:
		AudioManager.play_sfx("resurrect")


func show_subtitle(speaker: String, text: String, duration: float = 4.0) -> void:
	subtitle_requested.emit(speaker, text, duration)
