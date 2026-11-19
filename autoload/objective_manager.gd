extends Node
## Loads mission objectives from JSON and persists completion through GameState/SaveManager.

signal objective_updated(text: String)
signal objective_completed(objective_id: String)

var current_level_id: String = "level_01"
var current_objective: String = ""
var level_objectives: Array[Dictionary] = []
var completed_objectives: Array[String] = []


func load_level_objectives(level_id: String) -> void:
	current_level_id = level_id
	level_objectives.clear()
	var payload: Variant = DataLoader.load_json("story/levels.json")
	if payload is Dictionary:
		for level: Variant in payload.get("levels", []):
			if level is Dictionary and str(level.get("id", "")) == level_id:
				for item: Variant in level.get("objectives", []):
					if item is Dictionary:
						level_objectives.append(item)
				break
	_update_current()


func complete_objective(objective_id: String) -> void:
	if objective_id.is_empty() or completed_objectives.has(objective_id):
		return
	completed_objectives.append(objective_id)
	objective_completed.emit(objective_id)
	_update_current()
	if is_instance_valid(SaveManager):
		SaveManager.save_game()


func is_objective_complete(objective_id: String) -> bool:
	return completed_objectives.has(objective_id)


func are_all_level_objectives_completed(except_id: String = "") -> bool:
	for objective: Dictionary in level_objectives:
		var objective_id := str(objective.get("id", ""))
		if objective_id != except_id and not completed_objectives.has(objective_id):
			return false
	return not level_objectives.is_empty()


func _update_current() -> void:
	current_objective = ""
	for objective: Dictionary in level_objectives:
		var objective_id := str(objective.get("id", ""))
		if not completed_objectives.has(objective_id):
			current_objective = str(objective.get("description", "Explore the area."))
			break
	if current_objective.is_empty():
		current_objective = "Area complete — follow the marked exit."
	objective_updated.emit(current_objective)
