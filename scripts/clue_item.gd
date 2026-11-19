## clue_item.gd
## Attach to any interactable node in a level scene that represents a clue.
## Place the node in group "interactable" so the player ray finds it.
extends Node3D

signal clue_picked_up(clue_id: String)

@export var clue_id: String = ""
@export var clue_display_name: String = ""
@export var clue_description: String = ""
@export var one_shot: bool = true  # Remove from scene after pickup

var _collected: bool = false


func _ready() -> void:
	add_to_group("interactable")


## Called by player.gd when the player interacts with this node.
func interact() -> void:
	if _collected:
		return
	if clue_id == "":
		push_warning("ClueItem: clue_id is empty on node '%s'" % name)
		return

	GameManager.collect_clue(clue_id)
	emit_signal("clue_picked_up", clue_id)
	_show_popup()

	if one_shot:
		_collected = true
		# Disable collision / hide mesh if present
		for child in get_children():
			if child is CollisionShape3D or child is MeshInstance3D:
				child.visible = false
		set_process(false)
		set_physics_process(false)


func _show_popup() -> void:
	# Ask HUD to display a brief clue-acquired popup
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_clue_popup"):
		hud.show_clue_popup(clue_display_name, clue_description)
	else:
		# Fallback: print to console
		print("Clue acquired: [%s] %s — %s" % [clue_id, clue_display_name, clue_description])
