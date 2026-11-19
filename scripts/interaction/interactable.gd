extends Area3D
class_name Interactable
## Common camera-ray interaction contract for clues, doors, and puzzle devices.

@export var prompt_label: String = "Interact"
@export var one_shot: bool = true
var _used: bool = false


func get_prompt() -> String:
	return "[E] %s" % prompt_label


func interact(_player: Node) -> void:
	if one_shot and _used:
		return
	_used = true
	AudioManager.play_interaction_sfx("pickup")
