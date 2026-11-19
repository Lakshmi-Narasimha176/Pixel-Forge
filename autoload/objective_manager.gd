extends Node
## Data-backed objective list, presented one task at a time.

signal objective_updated(objective: Dictionary)
signal objective_completed(objective_id: String)
signal all_objectives_completed()

var current_level_id: String = "level_01"
var current_objective: Dictionary = {}
var level_objectives: Array[Dictionary] = []
var completed_objectives: Array[String] = []


func load_level_objectives(level_id: String) -> void:
	current_level_id = level_id
	level_objectives.clear()
	current_objective = {}
	var story: Variant = DataLoader.load_json("story/levels.json", ["levels"])
	if not (story is Dictionary):
		push_error("[ObjectiveManager] Could not load story/levels.json")
		objective_updated.emit({"id": "", "description": "Story data unavailable. Check the installation."})
		return
	for level_variant in story.get("levels", []):
		if not (level_variant is Dictionary) or str(level_variant.get("id", "")) != level_id:
			continue
		for objective_variant in level_variant.get("objectives", []):
			if objective_variant is Dictionary:
				level_objectives.append(objective_variant)
		_update_current_objective()
		return
	push_error("[ObjectiveManager] Unknown level in story data: %s" % level_id)
	objective_updated.emit({"id": "", "description": "Explore the area and look for clues."})


func complete_objective(objective_id: String) -> bool:
	if objective_id.is_empty() or completed_objectives.has(objective_id):
		return false
	if not _has_objective(objective_id):
		push_warning("[ObjectiveManager] Objective is not active in this level: %s" % objective_id)
		return false
	completed_objectives.append(objective_id)
	objective_completed.emit(objective_id)
	AudioManager.play_ui_sfx("confirm")
	_update_current_objective()
	SaveManager.save_game()
	if are_all_level_objectives_completed():
		all_objectives_completed.emit()
	return true


func are_all_level_objectives_completed(exempt_objective_id: String = "") -> bool:
	if level_objectives.is_empty():
		return false
	for objective in level_objectives:
		var objective_id := str(objective.get("id", ""))
		if objective_id == exempt_objective_id:
			continue
		if not completed_objectives.has(objective_id):
			return false
	return true


func _has_objective(objective_id: String) -> bool:
	for objective in level_objectives:
		if str(objective.get("id", "")) == objective_id:
			return true
	return false


func _update_current_objective() -> void:
	current_objective = {}
	for objective in level_objectives:
		if not completed_objectives.has(str(objective.get("id", ""))):
			current_objective = objective
			break
	objective_updated.emit(current_objective)
