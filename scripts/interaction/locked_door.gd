extends "res://scripts/interaction/interactable.gd"
## Reusable door / level exit with key, flag, or objective gating.

@export var next_level_id: String = ""
@export var required_item_id: String = ""
@export var required_flag: String = ""
@export var require_all_objectives: bool = false
@export var objective_id: String = ""
@export var locked_message: String = "Locked. Check your current objective."


func get_prompt() -> String:
	if not next_level_id.is_empty():
		return "[E] %s" % prompt_label
	return "[E] %s" % prompt_label


func interact(_player: Node) -> void:
	if not required_item_id.is_empty() and not GameState.has_item(required_item_id):
		AudioManager.play_sfx("error")
		GameState.show_subtitle("System", locked_message, 3.0)
		return

	if not required_flag.is_empty() and not bool(GameState.get_flag(required_flag, false)):
		AudioManager.play_sfx("error")
		GameState.show_subtitle("System", locked_message, 3.0)
		return

	if require_all_objectives and not ObjectiveManager.are_all_level_objectives_completed():
		AudioManager.play_sfx("error")
		GameState.show_subtitle("System", "Complete remaining objectives first.", 3.0)
		return

	AudioManager.play_sfx("unlock")
	if not objective_id.is_empty():
		ObjectiveManager.complete_objective(objective_id)

	if not next_level_id.is_empty():
		LevelManager.go_to_level(next_level_id, true)
	else:
		# Simple physical door swing
		var parent := get_parent()
		if parent and parent is Node3D:
			var tween := create_tween()
			tween.tween_property(parent, "rotation_degrees:y", parent.rotation_degrees.y + 90.0, 0.45)
		one_shot = true
		_used = true
