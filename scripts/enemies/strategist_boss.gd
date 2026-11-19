extends "res://scripts/enemies/base_enemy.gd"
## Strategist profile defaults: quick precision attacks from medium range.

func _ready() -> void:
	ranged_attack = true
	ranged_attack_range = 13.0
	attack_windup = 0.8
	move_speed = 3.8
	super._ready()
