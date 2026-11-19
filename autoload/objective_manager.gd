extends Node
## Objective and task tracking system for THE LAST REVENGE.

signal objective_updated(objective: Dictionary)
signal objective_completed(objective_id: String)
signal all_objectives_completed()

var current_objective: Dictionary = {}
var level_objectives: Array[Dictionary] = []
var completed_objectives: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func load_level_objectives(level_id: String) -> void:
	level_objectives.clear()
	var levels_data: Array = DataLoader.get_levels()
	for lvl in levels_data:
		if lvl.get("id") == level_id:
			var objs: Array = lvl.get("objectives", [])
			for o in objs:
				level_objectives.append(o)
			break
	_update_current_objective()


func complete_objective(obj_id: String) -> void:
	if not completed_objectives.has(obj_id):
		completed_objectives.append(obj_id)
		objective_completed.emit(obj_id)
		if AudioManager:
			AudioManager.play_ui_sfx("confirm")
		_update_current_objective()
		if are_all_level_objectives_completed():
			all_objectives_completed.emit()


func are_all_level_objectives_completed() -> bool:
	if level_objectives.is_empty():
		return true
	for obj in level_objectives:
		var oid: String = obj.get("id", "")
		if not completed_objectives.has(oid):
			return false
	return true


func _update_current_objective() -> void:
	for obj in level_objectives:
		var oid: String = obj.get("id", "")
		if not completed_objectives.has(oid):
			current_objective = obj
			objective_updated.emit(current_objective)
			return
	current_objective = {}
	objective_updated.emit(current_objective)

