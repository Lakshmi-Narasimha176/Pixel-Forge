extends "res://scripts/interaction/interactable.gd"
## Pickup or story clue: notes, evidence, keys, blood bags, weapon, and resurrection lore.

@export_enum("note", "evidence", "key", "weapon", "blood_bag", "battery", "resurrection_rule", "resurrection_loophole", "memory") var pickup_type: String = "note"
@export var item_id: String = ""
@export var objective_id: String = ""
@export var flag_to_set: String = ""
@export var subtitle_speaker: String = "Thought"
@export_multiline var subtitle_text: String = ""
@export var remove_on_pickup: bool = true


func _ready() -> void:
	if remove_on_pickup and not item_id.is_empty() and GameState.has_item(item_id):
		queue_free()


func interact(player: Node) -> void:
	if one_shot and _used:
		return
	super.interact(player)

	match pickup_type:
		"weapon":
			GameState.equip_weapon()
			AudioManager.play_sfx("pickup")
		"blood_bag":
			GameState.add_blood_bag(1)
			AudioManager.play_sfx("pickup")
		"battery":
			GameState.flashlight_battery = minf(100.0, GameState.flashlight_battery + 45.0)
			AudioManager.play_sfx("pickup")
		"resurrection_rule":
			GameState.set_flag("resurrection_rule_discovered", true)
		"resurrection_loophole":
			GameState.set_flag("resurrection_loophole_found", true)
		_:
			AudioManager.play_sfx("pickup")

	if not item_id.is_empty():
		GameState.add_item(item_id)
	if not flag_to_set.is_empty():
		GameState.set_flag(flag_to_set, true)
	if not objective_id.is_empty():
		ObjectiveManager.complete_objective(objective_id)
	if not subtitle_text.is_empty():
		GameState.show_subtitle(subtitle_speaker, subtitle_text, 5.0)

	if remove_on_pickup:
		queue_free()
