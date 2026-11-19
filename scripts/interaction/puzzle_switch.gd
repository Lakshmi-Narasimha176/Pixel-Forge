extends Interactable
## Stateful lever/anchor that completes its shared puzzle after every unique switch.

@export var puzzle_id: String = ""
@export var switch_index: int = 0
@export var switch_name: String = "Circuit Breaker"
@export var required_switches: int = 1
@export var flag_to_set: String = ""
@export var objective_id: String = ""
@export var speaker: String = "System"
@export_multiline var activation_message: String = "Switch activated."


func _ready() -> void:
	var saved_state: Variant = GameState.puzzle_states.get(puzzle_id, [])
	if saved_state is Array and saved_state.has(switch_index):
		_used = true


func get_prompt() -> String:
	if _used:
		return "%s (Activated)" % switch_name
	return "[E] Activate %s" % switch_name


func interact(_player: Node) -> void:
	if _used:
		return
	if puzzle_id.is_empty():
		push_warning("Puzzle switch '%s' has no puzzle_id." % name)
		return

	_used = true
	AudioManager.play_interaction_sfx("switch")
	var lever_tween := create_tween()
	lever_tween.tween_property(self, "rotation_degrees:x", rotation_degrees.x + 45.0, 0.2)
	var saved_state: Variant = GameState.puzzle_states.get(puzzle_id, [])
	var activated: Array = saved_state if saved_state is Array else []
	if not activated.has(switch_index):
		activated.append(switch_index)
	GameState.puzzle_states[puzzle_id] = activated
	SaveManager.save_game()

	var complete := activated.size() >= maxi(1, required_switches)
	if complete:
		if not flag_to_set.is_empty():
			GameState.set_flag(flag_to_set, true)
		if not objective_id.is_empty():
			ObjectiveManager.complete_objective(objective_id)

	if not activation_message.is_empty():
		var message := activation_message if complete else "%s flipped (%d/%d)." % [switch_name, activated.size(), required_switches]
		GameState.show_subtitle(speaker, message, 3.5)
