class_name Pickup
extends Interactable
## General world item pickup.

@export var item_id: String = ""
@export var pickup_name: String = "Item"
@export var sound_type: String = "pickup"


func get_prompt() -> String:
	return "[E] Take %s" % pickup_name


func interact(_player: Node) -> void:
	if not item_id.is_empty():
		GameState.add_item(item_id)
	if AudioManager:
		AudioManager.play_sfx(sound_type)
	GameState.show_subtitle("System", "Acquired %s." % pickup_name, 2.5)
	queue_free()

