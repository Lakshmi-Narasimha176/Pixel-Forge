extends CanvasLayer

## HUD — always-on overlay showing level name, interaction hint, clue counter.

@onready var level_name_label: Label = $Control/level_name_label
@onready var interaction_hint: Label = $Control/interaction_hint
@onready var clue_count: Label = $Control/clue_count


func _ready() -> void:
	if GameManager.has_signal("clue_collected"):
		GameManager.clue_collected.connect(_on_clue_collected)


func set_level_name(name: String) -> void:
	level_name_label.text = name.to_upper()


func show_interaction_hint(hint: String = "[ E ] Examine") -> void:
	interaction_hint.text = hint
	interaction_hint.visible = true


func hide_interaction_hint() -> void:
	interaction_hint.visible = false


func update_clue_count(count: int) -> void:
	clue_count.text = "CLUES: %d" % count


func _on_clue_collected(_clue_id: String) -> void:
	update_clue_count(GameManager.collected_clues.size())
