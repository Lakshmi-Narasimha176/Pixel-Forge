extends "res://scripts/interaction/interactable.gd"
## Interactive puzzle switch or breaker lever.

@export var puzzle_id: String = ""
@export var switch_index: int = 0
@export var switch_name: String = "Circuit Breaker"
@export var required_switches: int = 1
@export var flag_to_set: String = ""
@export var objective_id: String = ""
@export var speaker: String = "System"
@export var activation_message: String = ""

var _active: bool = false


func get_prompt() -> String:
	if _active:
		return "%s (Activated)" % switch_name
	return "[E] Activate %s" % switch_name


func interact(_player: Node) -> void:
	if _active:
		return
	_active = true
	if AudioManager:
		AudioManager.play_interaction_sfx("switch")

	# Physical lever movement
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:x", rotation_degrees.x + 45.0, 0.2)

	# Update puzzle state in GameState
	if not puzzle_id.is_empty():
		var count: int = GameState.puzzle_states.get(puzzle_id, 0) + 1
		GameState.puzzle_states[puzzle_id] = count
		var msg := activation_message if activation_message != "" else "%s flipped (%d active)." % [switch_name, count]
		GameState.show_subtitle(speaker, msg, 2.5)

		# Check for specific puzzle completion
		if puzzle_id == "l3_traps" and count >= required_switches:
			var flag := flag_to_set if flag_to_set != "" else "l3_traps_disabled"
			GameState.set_flag(flag, true)
			GameState.show_subtitle(speaker, "All breakers activated! Traps disabled.", 4.0)
		elif puzzle_id == "l4_anchors" and count >= required_switches:
			var flag := flag_to_set if flag_to_set != "" else "l4_portal_unlocked"
			GameState.set_flag(flag, true)
			GameState.show_subtitle(speaker, "All soul anchors aligned! Void rift opened.", 4.0)
		elif not flag_to_set.is_empty() and count >= required_switches:
			GameState.set_flag(flag_to_set, true)
