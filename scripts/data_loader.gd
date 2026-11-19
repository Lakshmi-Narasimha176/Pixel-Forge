## data_loader.gd
## Loads all JSON data files for The Last Revenge.
## Can be used as an autoload or instantiated directly.
extends Node

const PATH_CLUES      := "res://data/clues/clues.json"
const PATH_PUZZLES    := "res://data/puzzles/puzzles.json"
const PATH_STORY      := "res://data/story/story.json"
const PATH_DIALOGUE   := "res://data/dialogue/dialogue.json"
const PATH_CHARACTERS := "res://data/characters/characters.json"


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("DataLoader: file not found — %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: cannot open — %s" % path)
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("DataLoader: JSON parse error in %s — %s" % [path, json.get_error_message()])
		return null
	return json.get_data()


func load_clues() -> Array:
	var data = _load_json(PATH_CLUES)
	if data is Array:
		return data
	push_warning("DataLoader: clues.json is not an Array, returning []")
	return []


func load_puzzles() -> Array:
	var data = _load_json(PATH_PUZZLES)
	if data is Array:
		return data
	push_warning("DataLoader: puzzles.json is not an Array, returning []")
	return []


func load_story() -> Dictionary:
	var data = _load_json(PATH_STORY)
	if data is Dictionary:
		return data
	push_warning("DataLoader: story.json is not a Dictionary, returning {}")
	return {}


func load_dialogue() -> Array:
	var data = _load_json(PATH_DIALOGUE)
	if data is Array:
		return data
	push_warning("DataLoader: dialogue.json is not an Array, returning []")
	return []


func load_characters() -> Array:
	var data = _load_json(PATH_CHARACTERS)
	if data is Array:
		return data
	push_warning("DataLoader: characters.json is not an Array, returning []")
	return []
