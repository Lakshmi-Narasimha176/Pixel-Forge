extends Node
## Global game state: player health, inventory, progression flags, resurrection, and settings.

signal health_changed(new_health: int, max_health: int)
signal inventory_changed()
signal flag_changed(flag_name: String, value: Variant)
signal player_died()
signal player_resurrected(resurrection_count: int)
signal subtitle_requested(speaker: String, text: String, duration: float)
signal journal_updated()

const MAX_HEALTH: int = 100

var health: int = MAX_HEALTH
var blood_bags: int = 1
var has_weapon: bool = false
var weapon_damage: int = 25
const WEAPONS := {
	"pistol": {"title": "Service Pistol", "damage": 28, "magazine": 12, "reserve": 48, "rate": 0.28, "reload": 1.25, "range": 55.0, "automatic": false},
	"rifle": {"title": "Service Rifle", "damage": 22, "magazine": 30, "reserve": 90, "rate": 0.16, "reload": 1.7, "range": 70.0, "automatic": true},
	"shotgun": {"title": "Pump Shotgun", "damage": 72, "magazine": 6, "reserve": 24, "rate": 0.75, "reload": 1.8, "range": 28.0, "automatic": false},
	"bat": {"title": "Ironwood Bat", "damage": 55, "magazine": 0, "reserve": 0, "rate": 0.52, "reload": 0.0, "range": 2.4, "automatic": false}
}
var current_weapon: String = ""
var owned_weapons: Array[String] = []
var weapon_ammo: Dictionary = {}
var last_chance_ready: bool = true
var flashlight_battery: float = 100.0
var flashlight_enabled: bool = true
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
var story_journal: Dictionary = {}
var visited_levels: Array[String] = []
var puzzle_states: Dictionary = {}

# Settings
var mouse_sensitivity: float = 0.0025
var master_volume: float = 0.8


func reset_for_new_game() -> void:
	health = MAX_HEALTH
	blood_bags = 1
	has_weapon = false
	current_weapon = ""
	owned_weapons.clear()
	weapon_ammo.clear()
	last_chance_ready = true
	flashlight_battery = 100.0
	flashlight_enabled = true
	is_dead = false
	resurrection_count = 0
	resurrection_rule_discovered = false
	resurrection_loophole_found = false
	current_level_id = "level_01"
	checkpoint_position = Vector3.ZERO
	has_checkpoint = false
	progression_flags.clear()
	collected_items.clear()
	story_journal.clear()
	visited_levels.clear()
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


func equip_weapon(weapon_id: String = "bat") -> void:
	if not WEAPONS.has(weapon_id):
		weapon_id = "pistol"
	if not owned_weapons.has(weapon_id):
		owned_weapons.append(weapon_id)
		var data: Dictionary = WEAPONS[weapon_id]
		weapon_ammo[weapon_id] = {"mag": int(data["magazine"]), "reserve": int(data["reserve"])}
	current_weapon = weapon_id
	has_weapon = true
	weapon_damage = int(WEAPONS[weapon_id]["damage"])
	inventory_changed.emit()
	show_subtitle("Inventory", "%s equipped." % WEAPONS[weapon_id]["title"], 2.0)


func select_next_weapon() -> void:
	if owned_weapons.size() < 2:
		return
	var index := owned_weapons.find(current_weapon)
	current_weapon = owned_weapons[(index + 1) % owned_weapons.size()]
	weapon_damage = int(WEAPONS[current_weapon]["damage"])
	inventory_changed.emit()


func ammo_for(weapon_id: String = "") -> Dictionary:
	var id := current_weapon if weapon_id.is_empty() else weapon_id
	return weapon_ammo.get(id, {"mag": 0, "reserve": 0})


func spend_ammo(amount: int = 1) -> bool:
	if current_weapon.is_empty() or int(WEAPONS[current_weapon]["magazine"]) == 0:
		return current_weapon == "bat"
	var ammo: Dictionary = weapon_ammo.get(current_weapon, {"mag": 0, "reserve": 0})
	if int(ammo["mag"]) < amount:
		return false
	ammo["mag"] = int(ammo["mag"]) - amount
	weapon_ammo[current_weapon] = ammo
	inventory_changed.emit()
	return true


func reload_weapon() -> bool:
	if current_weapon.is_empty() or int(WEAPONS[current_weapon]["magazine"]) == 0:
		return false
	var ammo: Dictionary = weapon_ammo.get(current_weapon, {"mag": 0, "reserve": 0})
	var capacity := int(WEAPONS[current_weapon]["magazine"])
	var needed := capacity - int(ammo["mag"])
	var loaded := mini(needed, int(ammo["reserve"]))
	if loaded <= 0:
		return false
	ammo["mag"] = int(ammo["mag"]) + loaded
	ammo["reserve"] = int(ammo["reserve"]) - loaded
	weapon_ammo[current_weapon] = ammo
	inventory_changed.emit()
	return true


func add_ammo(weapon_id: String, amount: int) -> void:
	if not WEAPONS.has(weapon_id) or not owned_weapons.has(weapon_id) or amount <= 0:
		return
	var ammo: Dictionary = weapon_ammo.get(weapon_id, {"mag": 0, "reserve": 0})
	ammo["reserve"] = int(ammo["reserve"]) + amount
	weapon_ammo[weapon_id] = ammo
	inventory_changed.emit()


func add_item(item_id: String) -> void:
	if not collected_items.has(item_id):
		collected_items.append(item_id)
		inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return collected_items.has(item_id)


func add_story_entry(entry_id: String, title: String, text: String, category: String = "Evidence") -> void:
	if entry_id.is_empty() or text.is_empty() or story_journal.has(entry_id):
		return
	story_journal[entry_id] = {"title": title, "text": text, "category": category}
	journal_updated.emit()


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
	SaveManager.save_game()


func show_subtitle(speaker: String, text: String, duration: float = 4.0) -> void:
	subtitle_requested.emit(speaker, text, duration)
