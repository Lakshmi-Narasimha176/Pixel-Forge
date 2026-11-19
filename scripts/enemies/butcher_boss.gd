extends "res://scripts/enemies/base_enemy.gd"
## Level 2 Boss: The Butcher
func _ready() -> void:
	enemy_name = "The Butcher"
	max_health = 180
	attack_damage = 30
	detect_range = 16.0
	attack_range = 2.4
	super._ready()

