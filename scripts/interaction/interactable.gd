extends Area3D
class_name Interactable
## Shared prompt and one-shot behavior for all useable world objects.

@export var prompt_label := "Interact"
@export var one_shot := true
var _used := false


func get_prompt() -> String:
	if _used and one_shot:
		return ""
	return "[E] " + prompt_label


func interact(_player: Node) -> void:
	if one_shot and _used:
		return
	_used = true

