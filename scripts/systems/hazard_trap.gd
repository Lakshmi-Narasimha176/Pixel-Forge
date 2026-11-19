extends Area3D
## Reusable trap/hazard zone that damages player unless deactivated by a flag.

@export var damage: int = 25
@export var deactivated_by_flag: String = ""
@export var cooldown: float = 1.2

var _timer: float = 0.0
var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not deactivated_by_flag.is_empty() and bool(GameState.get_flag(deactivated_by_flag, false)):
		visible = false
		return
	if _player_inside:
		_timer -= delta
		if _timer <= 0.0:
			_timer = cooldown
			GameState.take_damage(damage)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_timer = 0.0


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
