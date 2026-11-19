extends Node
## ObjectiveManager — Handles active narrative tasks, progression, and level goals.

signal objective_changed(objective_text: String)
signal objective_completed(objective_id: String)
signal all_level_objectives_completed()

var current_objective_id: String = ""
var current_objective_text: String = ""
var level_objectives: Array[Dictionary] = []
var objective_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Initialize objectives for a specific level
func load_objectives_for_level(level_index: int) -> void:
	level_objectives.clear()
	objective_index = 0
	
	match level_index:
		1:
			level_objectives = [
				{"id": "l1_wake", "text": "Find a way out of the darkness. Locate a light source."},
				{"id": "l1_flashlight", "text": "Explore the settlement and search for answers."},
				{"id": "l1_rule", "text": "Read the Devil's Bible to discover the Resurrection Rule."},
				{"id": "l1_escape", "text": "Unlock the gate and proceed to the warehouse district."}
			]
		2:
			level_objectives = [
				{"id": "l2_infiltrate", "text": "Infiltrate the Butcher's slaughterhouse."},
				{"id": "l2_arm", "text": "Find a weapon to defend yourself."},
				{"id": "l2_boss", "text": "Defeat the Butcher and claim his keycard."},
				{"id": "l2_unlock", "text": "Unlock the underground bunker entrance."}
			]
		3:
			level_objectives = [
				{"id": "l3_explore", "text": "Navigate the underground facility and evade the tripwire traps."},
				{"id": "l3_puzzles", "text": "Activate the power generator switches."},
				{"id": "l3_strategist", "text": "Confront and outsmart the Strategist."},
				{"id": "l3_evidence", "text": "Recover the classified ledger detailing the betrayal."}
			]
		4:
			level_objectives = [
				{"id": "l4_void", "text": "Traverse the distorted afterlife corridors."},
				{"id": "l4_loophole", "text": "Solve the antique clock puzzle at 3:00 to discover the Resurrection Loophole."},
				{"id": "l4_portal", "text": "Open the spectral passage back to the realm of the living."}
			]
		5:
			level_objectives = [
				{"id": "l5_reach", "text": "Escape through the subterranean collapse tunnel."},
				{"id": "l5_confront", "text": "Confront the Betrayer at the farmhouse sanctuary."},
				{"id": "l5_survive", "text": "Defeat the Betrayer using the loophole to break the curse."}
			]
	
	if not level_objectives.is_empty():
		_set_active_objective(0)


func complete_objective(obj_id: String) -> void:
	if current_objective_id == obj_id:
		objective_completed.emit(obj_id)
		objective_index += 1
		if objective_index < level_objectives.size():
			_set_active_objective(objective_index)
		else:
			current_objective_text = "All chapter objectives completed! Proceed to exit."
			objective_changed.emit(current_objective_text)
			all_level_objectives_completed.emit()


func _set_active_objective(index: int) -> void:
	var obj = level_objectives[index]
	current_objective_id = obj["id"]
	current_objective_text = obj["text"]
	objective_changed.emit(current_objective_text)
