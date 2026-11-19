extends Node3D
## Slowly rotates a prop on specified axis for atmospheric effect.
@export var axis: Vector3 = Vector3.UP
@export var speed_degrees: float = 15.0
func _process(delta: float) -> void:
	rotate(axis.normalized(), deg_to_rad(speed_degrees) * delta)
