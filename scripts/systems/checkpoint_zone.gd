extends Area3D
## Updates player checkpoint when entered.

@export var checkpoint_name: String = "Checkpoint"
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		GameState.set_checkpoint(global_position + Vector3(0, 0.5, 0))
		SaveManager.save_game()
		GameState.show_subtitle("Checkpoint", "%s reached. Progress saved." % checkpoint_name, 2.5)
