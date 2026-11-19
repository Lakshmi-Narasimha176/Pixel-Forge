extends Interactable
## Persistent switch/anchor puzzle with a clear partial-completion cue.

@export var puzzle_id := ""
@export var switch_index := 1
@export var required_switches := 2
@export var flag_to_set := ""
@export var objective_id := ""
@export var speaker := "The Mechanism"
@export_multiline var activation_message := "The mechanism shifts."


func _ready() -> void:
	if puzzle_id.is_empty():
		return
	var saved: Variant = GameState.puzzle_states.get(puzzle_id, [])
	if saved is Array and saved.has(switch_index):
		_used = true


func get_prompt() -> String:
	if _used:
		return ""
	return "[E] " + prompt_label


func interact(_player: Node) -> void:
	if _used:
		return
	_used = true
	var active: Array = GameState.puzzle_states.get(puzzle_id, [])
	if not active.has(switch_index):
		active.append(switch_index)
	GameState.puzzle_states[puzzle_id] = active
	AudioManager.play_sfx("unlock")
	if active.size() >= required_switches:
		if not flag_to_set.is_empty():
			GameState.set_flag(flag_to_set, true)
		if not objective_id.is_empty():
			ObjectiveManager.complete_objective(objective_id)
		GameState.show_subtitle(speaker, activation_message, 3.5)
	else:
		GameState.show_subtitle(speaker, "%s (%d/%d)" % [activation_message, active.size(), required_switches], 2.5)
	SaveManager.save_game()
