## level_base.gd
## Base class for all level scenes in The Last Revenge.
## Each level scene's root node should have script = level_base.gd (or extend it).
extends Node3D

signal level_ready(level_id: String)
signal unlock_condition_met(level_id: String)

@export var level_id: String = ""
@export var level_display_name: String = ""
@export var required_clue_ids: Array[String] = []
@export var puzzle_id: String = ""

var _puzzle_data: Dictionary = {}
var _clues_data: Array = []


func _ready() -> void:
	_load_level_data()
	_setup_hud()
	emit_signal("level_ready", level_id)


func _load_level_data() -> void:
	var loader := DataLoader.new()

	# Load all clues, then filter those belonging to this level
	var all_clues: Array = loader.load_clues()
	_clues_data = all_clues.filter(func(c): return c is Dictionary and c.get("level_id", "") == level_id)

	# Load puzzle for this level
	if puzzle_id != "":
		var all_puzzles: Array = loader.load_puzzles()
		for p in all_puzzles:
			if p is Dictionary and p.get("id", "") == puzzle_id:
				_puzzle_data = p
				break

	loader.free()


func _setup_hud() -> void:
	# Notify HUD of the level name so it can display on entry
	if level_display_name != "" and Engine.has_singleton("GameManager"):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_level_name"):
			hud.show_level_name(level_display_name)


func check_unlock_condition() -> bool:
	for clue_id in required_clue_ids:
		if not GameManager.has_clue(clue_id):
			return false
	if puzzle_id != "" and not GameManager.has_completed_puzzle(puzzle_id):
		return false
	emit_signal("unlock_condition_met", level_id)
	return true


func get_puzzle_data() -> Dictionary:
	return _puzzle_data


func get_level_clues() -> Array:
	return _clues_data
