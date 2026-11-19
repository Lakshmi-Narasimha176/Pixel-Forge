extends OmniLight3D
## Horror flickering light effect.
@export var min_energy: float = 0.3
@export var max_energy: float = 2.0
@export var min_interval: float = 0.06
@export var max_interval: float = 0.5
var _timer: float = 0.0
func _ready() -> void:
	_timer = randf_range(min_interval, max_interval)
func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(min_interval, max_interval)
		light_energy = randf_range(min_energy, max_energy)
