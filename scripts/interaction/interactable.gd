class_name Interactable
extends Node3D
## Base class for all interactable 3D world objects.

@export var prompt_label: String = "Interact"
@export var one_shot: bool = false

var _used: bool = false


func get_prompt() -> String:
	return "[E] %s" % prompt_label


func interact(_player: Node) -> void:
	if one_shot and _used:
		return
	_used = true

