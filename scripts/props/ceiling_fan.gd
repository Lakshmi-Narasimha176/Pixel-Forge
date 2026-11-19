extends Node3D
## Continuously rotates the node (ceiling fan blade) around Y axis.
@export var speed_degrees: float = 110.0
func _process(delta: float) -> void:
	rotation_degrees.y += speed_degrees * delta
