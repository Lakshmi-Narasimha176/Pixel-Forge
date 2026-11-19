## puzzle_manager.gd
## Manages puzzle loading and answer checking.
## Can be used as an autoload or instantiated per-level.
extends Node

signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)

var _puzzles_data: Array = []
var _loaded: bool = false


func _ready() -> void:
	_ensure_loaded()


func _ensure_loaded() -> void:
	if _loaded:
		return
	var loader := DataLoader.new()
	_puzzles_data = loader.load_puzzles()
	loader.free()
	_loaded = true


func _find_puzzle(puzzle_id: String) -> Dictionary:
	_ensure_loaded()
	for puzzle in _puzzles_data:
		if puzzle is Dictionary and puzzle.get("id", "") == puzzle_id:
			return puzzle
	return {}


func load_puzzle(puzzle_id: String) -> Dictionary:
	var puzzle := _find_puzzle(puzzle_id)
	if puzzle.is_empty():
		push_warning("PuzzleManager: puzzle not found — '%s'" % puzzle_id)
	return puzzle


func check_answer(puzzle_id: String, answer: String) -> bool:
	var puzzle := _find_puzzle(puzzle_id)
	if puzzle.is_empty():
		push_error("PuzzleManager: cannot check answer — puzzle not found '%s'" % puzzle_id)
		return false
	# Support both single correct answer (string) and multiple (array)
	var correct = puzzle.get("answer", null)
	var normalized := answer.strip_edges().to_lower()
	var is_correct := false
	if correct is String:
		is_correct = normalized == correct.strip_edges().to_lower()
	elif correct is Array:
		for c in correct:
			if normalized == (c as String).strip_edges().to_lower():
				is_correct = true
				break
	if is_correct:
		emit_signal("puzzle_solved", puzzle_id)
	else:
		emit_signal("puzzle_failed", puzzle_id)
	return is_correct
