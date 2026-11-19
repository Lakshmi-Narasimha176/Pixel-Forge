extends "res://scripts/enemies/base_enemy.gd"
## Level 3 Boss: The Strategist
func _ready() -> void:
	enemy_name = "The Strategist"
	max_health = 150
	attack_damage = 25
	detect_range = 18.0
	attack_range = 2.2
	super._ready()

