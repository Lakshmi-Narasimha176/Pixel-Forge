extends Node
## Global game state: player health, inventory, progression flags, resurrection, and settings.

signal health_changed(new_health: int, max_health: int)
signal inventory_changed()
signal flag_changed(flag_name: String, value: Variant)
signal player_died()
signal player_resurrected(resurrection_count: int)
signal subtitle_requested(speaker: String, text: String, duration: float)
signal flashlight_changed(battery: float, enabled: bool)
signal narrative_changed()

const MAX_HEALTH: int = 100

var health: int = MAX_HEALTH
var blood_bags: int = 1
var has_weapon: bool = false
var weapon_damage: int = 25
var flashlight_battery: float = 100.0
var flashlight_on: bool = true
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

# Psychological narrative state. Evidence values are journal-ready dictionaries.
var character_trust: Dictionary = {"unknown_voice": 0, "butcher": 0, "strategist": 0, "betrayer": 0}
var character_suspicion: Dictionary = {"unknown_voice": 0, "butcher": 0, "strategist": 0, "betrayer": 0}
var discovered_evidence: Dictionary = {}
var unlocked_memories: Array[String] = []
var revealed_secrets: Array[String] = []
var discovered_contradictions: Array[String] = []
var dialogue_choices: Dictionary = {}
var fired_story_events: Array[String] = []
var current_mystery: String = "Who is speaking through the walkie-talkie?"
var ending_id: String = ""

# Settings
var mouse_sensitivity: float = 0.0025
var master_volume: float = 0.8


func reset_for_new_game() -> void:
	health = MAX_HEALTH
	blood_bags = 1
	has_weapon = false
	flashlight_battery = 100.0
	flashlight_on = true
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
	character_trust = {"unknown_voice": 0, "butcher": 0, "strategist": 0, "betrayer": 0}
	character_suspicion = {"unknown_voice": 0, "butcher": 0, "strategist": 0, "betrayer": 0}
	discovered_evidence.clear()
	unlocked_memories.clear()
	revealed_secrets.clear()
	discovered_contradictions.clear()
	dialogue_choices.clear()
	fired_story_events.clear()
	current_mystery = "Who is speaking through the walkie-talkie?"
	ending_id = ""
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
	narrative_changed.emit()


func change_trust(character_id: String, amount: int) -> void:
	character_trust[character_id] = clampi(int(character_trust.get(character_id, 0)) + amount, -5, 5)
	narrative_changed.emit()


func change_suspicion(character_id: String, amount: int) -> void:
	character_suspicion[character_id] = clampi(int(character_suspicion.get(character_id, 0)) + amount, 0, 5)
	narrative_changed.emit()


func record_evidence(evidence_id: String, title: String, text: String, level_id: String = "") -> void:
	if evidence_id.is_empty() or discovered_evidence.has(evidence_id):
		return
	discovered_evidence[evidence_id] = {"title": title, "text": text, "level": level_id}
	narrative_changed.emit()


func record_contradiction(contradiction_id: String) -> void:
	if not contradiction_id.is_empty() and not discovered_contradictions.has(contradiction_id):
		discovered_contradictions.append(contradiction_id)
		narrative_changed.emit()


func unlock_memory(memory_id: String) -> void:
	if not memory_id.is_empty() and not unlocked_memories.has(memory_id):
		unlocked_memories.append(memory_id)
		narrative_changed.emit()


func reveal_secret(secret_id: String) -> void:
	if not secret_id.is_empty() and not revealed_secrets.has(secret_id):
		revealed_secrets.append(secret_id)
		narrative_changed.emit()


func choose_dialogue(choice_id: String, option_id: String) -> void:
	if not choice_id.is_empty():
		dialogue_choices[choice_id] = option_id
		narrative_changed.emit()


func condition_satisfied(condition: Dictionary) -> bool:
	for evidence_id in condition.get("requires_evidence", []):
		if not discovered_evidence.has(str(evidence_id)):
			return false
	for secret_id in condition.get("requires_secrets", []):
		if not revealed_secrets.has(str(secret_id)):
			return false
	for contradiction_id in condition.get("requires_contradictions", []):
		if not discovered_contradictions.has(str(contradiction_id)):
			return false
	for flag_id in condition.get("requires_flags", []):
		if not bool(get_flag(str(flag_id), false)):
			return false
	var character_id := str(condition.get("character", ""))
	if not character_id.is_empty():
		if character_trust.get(character_id, 0) < int(condition.get("min_trust", -5)):
			return false
		if character_suspicion.get(character_id, 0) > int(condition.get("max_suspicion", 5)):
			return false
	return true


func apply_story_event(event_id: String) -> bool:
	if event_id.is_empty() or fired_story_events.has(event_id):
		return false
	var event := get_story_event(event_id)
	if event.is_empty():
		push_error("[GameState] Unknown narrative event: %s" % event_id)
		return false
	if not condition_satisfied(event):
		return false
	var character_id := str(event.get("character", ""))
	if not character_id.is_empty():
		change_trust(character_id, int(event.get("trust_change", 0)))
		change_suspicion(character_id, int(event.get("suspicion_change", 0)))
	var evidence_id := str(event.get("evidence_id", ""))
	if not evidence_id.is_empty():
		record_evidence(evidence_id, str(event.get("evidence_title", evidence_id)), str(event.get("evidence_text", "")), current_level_id)
	var contradiction_id := str(event.get("contradiction_id", ""))
	if not contradiction_id.is_empty():
		record_contradiction(contradiction_id)
	var secret_id := str(event.get("reveals", ""))
	if not secret_id.is_empty():
		reveal_secret(secret_id)
	var memory_id := str(event.get("memory_id", ""))
	if not memory_id.is_empty():
		unlock_memory(memory_id)
	var flag_id := str(event.get("sets_flag", ""))
	if not flag_id.is_empty():
		set_flag(flag_id, true)
	var event_ending_id := str(event.get("ending_id", ""))
	if not event_ending_id.is_empty():
		ending_id = event_ending_id
	var objective_id := str(event.get("completes_objective", ""))
	if not objective_id.is_empty():
		ObjectiveManager.complete_objective(objective_id)
	var next_mystery := str(event.get("next_mystery", ""))
	if not next_mystery.is_empty():
		current_mystery = next_mystery
	fired_story_events.append(event_id)
	var dialogue := str(event.get("dialogue", ""))
	if not dialogue.is_empty():
		show_subtitle(str(event.get("speaker", "")), dialogue, float(event.get("duration", 5.0)))
	narrative_changed.emit()
	SaveManager.save_game()
	return true


func get_story_event(event_id: String) -> Dictionary:
	var story: Variant = DataLoader.load_json("story/narrative_events.json", ["events"])
	if not (story is Dictionary):
		return {}
	for event_variant in story.get("events", []):
		if event_variant is Dictionary and str(event_variant.get("id", "")) == event_id:
			return event_variant.duplicate(true)
	return {}


func story_event_ready(event_id: String) -> bool:
	if fired_story_events.has(event_id):
		return false
	var event := get_story_event(event_id)
	return not event.is_empty() and condition_satisfied(event)


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
	flashlight_changed.emit(flashlight_battery, flashlight_on)
	if AudioManager:
		AudioManager.play_sfx("resurrect")


func show_subtitle(speaker: String, text: String, duration: float = 4.0) -> void:
	subtitle_requested.emit(speaker, text, duration)
