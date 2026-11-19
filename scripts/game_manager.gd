## game_manager.gd
## Global singleton (AutoLoad as "GameManager").
## Tracks game state, level progression, clue collection, and save/load.
extends Node

signal clue_collected(clue_id: String)
signal puzzle_completed(puzzle_id: String)
signal level_changed(level_num: int)

const SAVE_PATH := "user://savegame.json"

var current_level: int = 0
var collected_clues: Array = []
var completed_puzzles: Array = []

# Level scene map
const LEVEL_SCENES: Dictionary = {
	1: "res://scenes/level_1.tscn",
	2: "res://scenes/level_2.tscn",
	3: "res://scenes/level_3.tscn",
	4: "res://scenes/level_4.tscn",
	5: "res://scenes/level_5.tscn",
}


func go_to_level(n: int) -> void:
	if n < 1 or n > 5:
		push_error("GameManager: invalid level %d" % n)
		return
	current_level = n
	emit_signal("level_changed", n)
	var path: String = LEVEL_SCENES[n]
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("GameManager: failed to load scene %s (err %d)" % [path, err])


func collect_clue(clue_id: String) -> void:
	if clue_id in collected_clues:
		return
	collected_clues.append(clue_id)
	emit_signal("clue_collected", clue_id)
	save_state()


func complete_puzzle(puzzle_id: String) -> void:
	if puzzle_id in completed_puzzles:
		return
	completed_puzzles.append(puzzle_id)
	emit_signal("puzzle_completed", puzzle_id)
	save_state()


func has_clue(clue_id: String) -> bool:
	return clue_id in collected_clues


func has_completed_puzzle(puzzle_id: String) -> bool:
	return puzzle_id in completed_puzzles


func save_state() -> void:
	var state := {
		"current_level": current_level,
		"collected_clues": collected_clues,
		"completed_puzzles": completed_puzzles,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameManager: cannot open save file for writing")
		return
	file.store_string(JSON.stringify(state, "\t"))
	file.close()


func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("GameManager: no save file found, starting fresh")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameManager: cannot open save file for reading")
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("GameManager: corrupt save file — %s" % json.get_error_message())
		return
	var state = json.get_data()
	if state is Dictionary:
		current_level     = state.get("current_level", 0)
		collected_clues   = state.get("collected_clues", [])
		completed_puzzles = state.get("completed_puzzles", [])


func reset_state() -> void:
	current_level     = 0
	collected_clues   = []
	completed_puzzles = []
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
