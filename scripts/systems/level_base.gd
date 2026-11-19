extends Node3D
## Base level controller: manages spawn point, checkpoint, objectives, and intro subtitle.

@export var level_id: String = "level_01"
@export var level_title: String = "The Awakening"
@export_multiline var intro_subtitle: String = ""


func _ready() -> void:
	GameState.current_level_id = level_id
	ObjectiveManager.load_level_objectives(level_id)

	var spawn := get_node_or_null("SpawnPoint") as Node3D
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and spawn:
		var player := players[0] as Node3D
		if GameState.has_checkpoint:
			player.global_position = GameState.checkpoint_position
		else:
			player.global_position = spawn.global_position
			GameState.set_checkpoint(spawn.global_position)

	if not intro_subtitle.is_empty():
		GameState.show_subtitle(level_title, intro_subtitle, 5.5)
