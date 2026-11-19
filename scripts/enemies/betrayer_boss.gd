extends "res://scripts/enemies/base_enemy.gd"
## Betrayer profile defaults: aggressive, personal, and faster when cornered.

func _ready() -> void:
	move_speed = 4.2
	enrage_threshold = 0.5
	enrage_speed_multiplier = 1.35
	attack_windup = 0.45
	super._ready()
