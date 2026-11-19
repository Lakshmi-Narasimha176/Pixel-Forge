## journal.gd
## Clue journal UI controller.
## Attach to a CanvasLayer node (or the clue_journal.tscn root).
## Add to group "journal" so other scripts can find it.
extends CanvasLayer

@onready var clue_list: ItemList   = %ClueList
@onready var clue_detail: TextEdit = %ClueDetail
@onready var close_btn: Button     = %CloseBtn

var _clues_data: Array = []
var _clue_map: Dictionary = {}  # clue_id -> clue dict


func _ready() -> void:
	add_to_group("journal")
	visible = false

	# Load clue metadata for display
	var loader := DataLoader.new()
	_clues_data = loader.load_clues()
	loader.free()
	for c in _clues_data:
		if c is Dictionary:
			_clue_map[c.get("id", "")] = c

	# Signals
	close_btn.pressed.connect(_on_close_pressed)
	clue_list.item_selected.connect(_on_clue_selected)
	GameManager.clue_collected.connect(_on_clue_collected)


func toggle() -> void:
	if visible:
		hide()
	else:
		_refresh_list()
		show()


func _refresh_list() -> void:
	clue_list.clear()
	clue_detail.text = ""
	for clue_id in GameManager.collected_clues:
		var entry: Dictionary = _clue_map.get(clue_id, {})
		var display: String = entry.get("name", clue_id)
		clue_list.add_item(display)
		# Store clue_id as metadata on each list item
		clue_list.set_item_metadata(clue_list.item_count - 1, clue_id)


func _on_clue_selected(index: int) -> void:
	var clue_id: String = clue_list.get_item_metadata(index)
	var entry: Dictionary = _clue_map.get(clue_id, {})
	var text := "%s\n\n%s" % [entry.get("name", clue_id), entry.get("description", "No details available.")]
	clue_detail.text = text


func _on_close_pressed() -> void:
	hide()


func _on_clue_collected(_id: String) -> void:
	# If journal is open, refresh immediately
	if visible:
		_refresh_list()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle()
