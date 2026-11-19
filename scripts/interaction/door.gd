class_name Door
extends Interactable
## Standard interactive door with sound effects and physical swing animation.

@export var is_open: bool = false
@export var open_angle: float = 90.0

var _initial_rotation_y: float = 0.0


func _ready() -> void:
	_initial_rotation_y = rotation_degrees.y


func get_prompt() -> String:
	return "[E] Close Door" if is_open else "[E] Open Door"


func interact(_player: Node) -> void:
	is_open = not is_open
	if AudioManager:
		AudioManager.play_interaction_sfx("door_open" if is_open else "door_close")

	var target_angle := _initial_rotation_y + (open_angle if is_open else 0.0)
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees:y", target_angle, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

