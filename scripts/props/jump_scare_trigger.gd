extends Area3D
## One-shot jumpscare zone: plays a jumpscare audio when player enters.
@export var one_shot: bool = true
var _triggered: bool = false
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
	if one_shot and _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		if AudioManager:
			AudioManager.play_jumpscare()
