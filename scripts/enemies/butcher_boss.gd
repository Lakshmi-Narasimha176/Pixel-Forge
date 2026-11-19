extends "res://scripts/enemies/base_enemy.gd"
## Butcher profile defaults: slow, armoured, and readable heavy strikes.

func _ready() -> void:
	move_speed = 2.6
	attack_windup = 1.0
	damage_resistance = 0.15
	super._ready()
