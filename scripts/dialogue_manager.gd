## dialogue_manager.gd
## Global singleton (AutoLoad as "DialogueManager").
## Drives line-by-line dialogue playback using data from DataLoader.
extends Node

signal dialogue_started(dialogue_id: String)
signal dialogue_line_changed(speaker: String, text: String)
signal dialogue_finished(dialogue_id: String)

var _dialogue_data: Array = []
var _current_entry: Dictionary = {}
var _current_lines: Array = []
var _line_index: int = 0
var _active_id: String = ""
var _is_active: bool = false

# Reference to the DialogueBox UI scene instance (set by HUD or level on ready)
var dialogue_box: Node = null


func _ready() -> void:
	var loader := DataLoader.new()
	_dialogue_data = loader.load_dialogue()
	loader.free()


func _find_entry(dialogue_id: String) -> Dictionary:
	for entry in _dialogue_data:
		if entry is Dictionary and entry.get("id", "") == dialogue_id:
			return entry
	return {}


func show_dialogue(dialogue_id: String) -> void:
	if _is_active:
		push_warning("DialogueManager: already showing dialogue '%s'" % _active_id)
		return
	_current_entry = _find_entry(dialogue_id)
	if _current_entry.is_empty():
		push_error("DialogueManager: dialogue id not found — '%s'" % dialogue_id)
		return
	_active_id = dialogue_id
	_current_lines = _current_entry.get("lines", [])
	_line_index = 0
	_is_active = true
	if dialogue_box:
		dialogue_box.visible = true
	emit_signal("dialogue_started", dialogue_id)
	_emit_current_line()


func _emit_current_line() -> void:
	if _line_index >= _current_lines.size():
		end_dialogue()
		return
	var line = _current_lines[_line_index]
	var speaker: String = ""
	var text: String = ""
	if line is Dictionary:
		speaker = line.get("speaker", "")
		text    = line.get("text", "")
	elif line is String:
		text = line
	emit_signal("dialogue_line_changed", speaker, text)


func next_line() -> void:
	if not _is_active:
		return
	_line_index += 1
	_emit_current_line()


func end_dialogue() -> void:
	if not _is_active:
		return
	_is_active = false
	if dialogue_box:
		dialogue_box.visible = false
	var finished_id := _active_id
	_active_id = ""
	_current_entry = {}
	_current_lines = []
	_line_index = 0
	emit_signal("dialogue_finished", finished_id)


func is_active() -> bool:
	return _is_active
