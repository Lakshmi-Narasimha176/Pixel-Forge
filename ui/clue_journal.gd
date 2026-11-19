extends CanvasLayer

## Clue Journal — "Dead World Dossier"
## Populated from GameManager.collected_clues via DataLoader.

@onready var clue_list: ItemList = $PanelContainer/VBoxContainer/HBoxContainer/clue_list
@onready var clue_title: Label = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/clue_title
@onready var clue_body: RichTextLabel = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/clue_body
@onready var close_btn: Button = $PanelContainer/VBoxContainer/close_btn

var _clues_cache: Array = []


func _ready() -> void:
	hide()
	close_btn.pressed.connect(_on_close_btn_pressed)
	clue_list.item_selected.connect(_on_clue_list_item_selected)


func toggle_journal() -> void:
	if visible:
		hide()
	else:
		refresh()
		show()


func refresh() -> void:
	clue_list.clear()
	_clues_cache = []
	var all_clues: Array = DataLoader.load_clues()
	for clue_id in GameManager.collected_clues:
		var clue_data = _find_clue(all_clues, clue_id)
		if clue_data:
			_clues_cache.append(clue_data)
			clue_list.add_item(clue_data.get("name", clue_id).to_upper())
	# Reset detail pane
	clue_title.text = ""
	clue_body.text = ""


func _find_clue(all_clues: Array, clue_id: String) -> Dictionary:
	for c in all_clues:
		if c.get("id", "") == clue_id:
			return c
	return {}


func _on_clue_list_item_selected(idx: int) -> void:
	if idx < 0 or idx >= _clues_cache.size():
		return
	var clue: Dictionary = _clues_cache[idx]
	clue_title.text = clue.get("name", "UNKNOWN").to_upper()
	var description: String = clue.get("description", "No description available.")
	var meaning: String = clue.get("meaning", "")
	var body_text: String = description
	if meaning != "":
		body_text += "\n\n[color=#8b0000]SIGNIFICANCE:[/color]\n" + meaning
	clue_body.text = body_text


func _on_close_btn_pressed() -> void:
	hide()
