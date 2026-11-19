extends Node
## JSON-based save/load system stored at user://savegame.json.

const SAVE_PATH := "user://savegame.json"


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var payload := {
		"version": 1,
		"current_level_id": GameState.current_level_id,
		"has_checkpoint": GameState.has_checkpoint,
		"checkpoint_position": [
			GameState.checkpoint_position.x,
			GameState.checkpoint_position.y,
			GameState.checkpoint_position.z
		],
		"health": GameState.health,
		"blood_bags": GameState.blood_bags,
		"has_weapon": GameState.has_weapon,
		"flashlight_battery": GameState.flashlight_battery,
		"resurrection_count": GameState.resurrection_count,
		"resurrection_rule_discovered": GameState.resurrection_rule_discovered,
		"resurrection_loophole_found": GameState.resurrection_loophole_found,
		"progression_flags": GameState.progression_flags,
		"collected_items": GameState.collected_items,
		"completed_objectives": ObjectiveManager.completed_objectives,
		"puzzle_states": GameState.puzzle_states,
		"mouse_sensitivity": GameState.mouse_sensitivity,
		"master_volume": GameState.master_volume
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot write save file: err=%d" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_game() -> bool:
	if not has_save_file():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Cannot read save file: err=%d" % FileAccess.get_open_error())
		return false

	var raw := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(raw) != OK or not (json.data is Dictionary):
		push_error("[SaveManager] Corrupted save file.")
		return false

	var data: Dictionary = json.data
	GameState.current_level_id = str(data.get("current_level_id", "level_01"))
	GameState.has_checkpoint = bool(data.get("has_checkpoint", false))
	var cp: Variant = data.get("checkpoint_position", [0.0, 1.0, 0.0])
	if cp is Array and cp.size() == 3:
		GameState.checkpoint_position = Vector3(float(cp[0]), float(cp[1]), float(cp[2]))
	GameState.health = int(data.get("health", GameState.MAX_HEALTH))
	GameState.blood_bags = int(data.get("blood_bags", 1))
	GameState.has_weapon = bool(data.get("has_weapon", false))
	GameState.flashlight_battery = float(data.get("flashlight_battery", 100.0))
	GameState.resurrection_count = int(data.get("resurrection_count", 0))
	GameState.resurrection_rule_discovered = bool(data.get("resurrection_rule_discovered", false))
	GameState.resurrection_loophole_found = bool(data.get("resurrection_loophole_found", false))

	var flags: Variant = data.get("progression_flags", {})
	if flags is Dictionary:
		GameState.progression_flags = flags.duplicate(true)

	GameState.collected_items.clear()
	var items: Variant = data.get("collected_items", [])
	if items is Array:
		for item in items:
			GameState.collected_items.append(str(item))

	ObjectiveManager.completed_objectives.clear()
	var objs: Variant = data.get("completed_objectives", [])
	if objs is Array:
		for obj in objs:
			ObjectiveManager.completed_objectives.append(str(obj))

	var pstates: Variant = data.get("puzzle_states", {})
	if pstates is Dictionary:
		GameState.puzzle_states = pstates.duplicate(true)

	GameState.mouse_sensitivity = float(data.get("mouse_sensitivity", 0.0025))
	GameState.master_volume = float(data.get("master_volume", 0.8))
	AudioManager.apply_volume(GameState.master_volume)
	GameState.health_changed.emit(GameState.health, GameState.MAX_HEALTH)
	GameState.inventory_changed.emit()
	return true


func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
