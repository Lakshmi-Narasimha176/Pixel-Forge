extends CanvasLayer

## Puzzle Screen — handles loading and answer checking for all puzzles.

@onready var puzzle_title: Label = $PanelContainer/VBoxContainer/puzzle_title
@onready var puzzle_objective: RichTextLabel = $PanelContainer/VBoxContainer/puzzle_objective
@onready var input_list: ItemList = $PanelContainer/VBoxContainer/input_list
@onready var answer_input: LineEdit = $PanelContainer/VBoxContainer/answer_input
@onready var hint_label: Label = $PanelContainer/VBoxContainer/hint_label
@onready var feedback_label: Label = $PanelContainer/VBoxContainer/feedback_label
@onready var submit_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/submit_btn
@onready var hint_btn: Button = $PanelContainer/VBoxContainer/HBoxContainer/hint_btn

var _current_puzzle_id: String = ""
var _hint_text: String = ""


func _ready() -> void:
	hide()
	submit_btn.pressed.connect(_on_submit)
	hint_btn.pressed.connect(_on_hint)
	PuzzleManager.puzzle_solved.connect(_on_puzzle_solved)
	PuzzleManager.puzzle_failed.connect(_on_puzzle_failed)


func load_puzzle(puzzle_id: String) -> void:
	_current_puzzle_id = puzzle_id
	var data: Dictionary = PuzzleManager.load_puzzle(puzzle_id)
	if data.is_empty():
		push_warning("PuzzleScreen: no data for puzzle_id=" + puzzle_id)
		return

	puzzle_title.text = data.get("title", "UNKNOWN PUZZLE").to_upper()
	puzzle_objective.text = data.get("objective", "")
	_hint_text = data.get("hint", "")
	hint_label.text = _hint_text
	hint_label.visible = false
	feedback_label.text = ""
	feedback_label.visible = false
	answer_input.text = ""

	input_list.clear()
	var inputs: Array = data.get("inputs", [])
	for entry in inputs:
		input_list.add_item(str(entry))

	show()


func _on_submit() -> void:
	var answer: String = answer_input.text.strip_edges()
	if answer.is_empty():
		return
	feedback_label.visible = false
	PuzzleManager.check_answer(_current_puzzle_id, answer)


func _on_hint() -> void:
	hint_label.visible = true


func _on_puzzle_solved(_puzzle_id: String) -> void:
	feedback_label.text = "[ CORRECT — ACCESS GRANTED ]"
	feedback_label.theme_override_colors = {}
	feedback_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2, 1))
	feedback_label.visible = true
	await get_tree().create_timer(1.5).timeout
	hide()


func _on_puzzle_failed(_puzzle_id: String) -> void:
	feedback_label.text = "[ INCORRECT — TRY AGAIN ]"
	feedback_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1, 1))
	feedback_label.visible = true
