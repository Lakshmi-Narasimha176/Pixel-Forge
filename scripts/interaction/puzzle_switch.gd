extends Interactable
## Interactive puzzle switch or breaker lever.

@export var puzzle_id: String = ""
@export var switch_index: int = 0
@export var switch_name: String = "Circuit Breaker"

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
		GameState.show_subtitle("System", "%s flipped (%d active)." % [switch_name, count], 2.5)

		# Check for specific puzzle completion
		if puzzle_id == "puzzle_l3_traps" and count >= 2:
			GameState.set_flag("l3_traps_disabled", true)
			GameState.show_subtitle("System", "All breakers activated! Traps disabled.", 4.0)
		elif puzzle_id == "puzzle_l4_anchors" and count >= 3:
			GameState.set_flag("l4_portal_unlocked", true)
			GameState.show_subtitle("System", "All soul anchors aligned! Void rift opened.", 4.0)

