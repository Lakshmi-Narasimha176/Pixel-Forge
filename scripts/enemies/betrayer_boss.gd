extends "res://scripts/enemies/base_enemy.gd"
## Level 5 Final Boss: The Betrayer
func _ready() -> void:
	enemy_name = "The Betrayer"
	max_health = 220
	attack_damage = 35
	detect_range = 20.0
	attack_range = 2.5
	super._ready()
