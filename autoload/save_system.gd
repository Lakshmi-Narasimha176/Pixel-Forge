extends Node
## SaveSystem — Local JSON-based save & load system with error recovery.

const SAVE_PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var save_dict = {
		"level_index": GameManager.current_level_index,
		"player_health": GameManager.player_health,
		"checkpoint": {
			"x": GameManager.player_checkpoint.x,
			"y": GameManager.player_checkpoint.y,
			"z": GameManager.player_checkpoint.z
		},
		"death_count": GameManager.death_count,
		"resurrection_rule_known": GameManager.resurrection_rule_known,
		"resurrection_loophole_known": GameManager.resurrection_loophole_known,
		"final_truth_revealed": GameManager.final_truth_revealed,
		"has_flashlight": GameManager.has_flashlight,
		"has_weapon": GameManager.has_weapon,
		"inventory": GameManager.inventory,
		"story_clues": GameManager.story_clues,
		"active_keys": GameManager.active_keys,
		"objective_id": ObjectiveManager.current_objective_id,
		"objective_index": ObjectiveManager.objective_index
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to write save file: %s" % error_string(FileAccess.get_open_error()))
		return false
	
	var json_string = JSON.stringify(save_dict, "  ")
	file.store_string(json_string)
	file.close()
	print("[SaveSystem] Game saved successfully.")
	return true


func load_game() -> bool:
	if not has_save():
		push_warning("No save file found.")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to read save file.")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in save file: %s" % json.get_error_message())
		return false
	
	var data = json.data
	if not data is Dictionary:
		push_error("Save data is not a valid dictionary.")
		return false
	
	# Apply restored state
	GameManager.current_level_index = data.get("level_index", 1)
	GameManager.player_health = data.get("player_health", 100.0)
	
	var cp = data.get("checkpoint", {})
	if cp.has("x") and cp.has("y") and cp.has("z"):
		GameManager.player_checkpoint = Vector3(cp.x, cp.y, cp.z)
	
	GameManager.death_count = data.get("death_count", 0)
	GameManager.resurrection_rule_known = data.get("resurrection_rule_known", false)
	GameManager.resurrection_loophole_known = data.get("resurrection_loophole_known", false)
	GameManager.final_truth_revealed = data.get("final_truth_revealed", false)
	GameManager.has_flashlight = data.get("has_flashlight", false)
	GameManager.has_weapon = data.get("has_weapon", false)
	GameManager.inventory = Array(data.get("inventory", []), TYPE_STRING, "", null)
	GameManager.story_clues = Array(data.get("story_clues", []), TYPE_STRING, "", null)
	GameManager.active_keys = Array(data.get("active_keys", []), TYPE_STRING, "", null)
	
	# Transition into loaded level
	GameManager.change_level(GameManager.current_level_index)
	print("[SaveSystem] Game loaded successfully.")
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
