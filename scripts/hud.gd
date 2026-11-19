## hud.gd
## Heads-Up Display controller.
## Attach to the hud.tscn root node. Add to group "hud".
extends CanvasLayer

@onready var interaction_hint: Label  = %InteractionHint
@onready var level_name_label: Label  = %LevelNameLabel

# Clue popup — created dynamically if not wired
var _clue_popup_timer: SceneTreeTimer = null
const LEVEL_NAME_DISPLAY_SEC: float = 3.0
const CLUE_POPUP_DISPLAY_SEC: float = 4.0


func _ready() -> void:
	add_to_group("hud")
	interaction_hint.visible = false
	level_name_label.visible = false


## Called by player.gd when raycast target changes.
func set_interaction_hint(visible_flag: bool) -> void:
	interaction_hint.text = "Press E to examine"
	interaction_hint.visible = visible_flag


## Called by level_base.gd on level entry.
func show_level_name(name_text: String) -> void:
	level_name_label.text = name_text
	level_name_label.visible = true
	await get_tree().create_timer(LEVEL_NAME_DISPLAY_SEC).timeout
	level_name_label.visible = false


## Called by clue_item.gd after pickup.
func show_clue_popup(clue_name: String, description: String) -> void:
	# Reuse level_name_label area for clue popup (brief flash).
	# Replace with a dedicated popup node if desired.
	level_name_label.text = "Clue found: %s\n%s" % [clue_name, description]
	level_name_label.visible = true
	if _clue_popup_timer:
		_clue_popup_timer = null
	_clue_popup_timer = get_tree().create_timer(CLUE_POPUP_DISPLAY_SEC)
	await _clue_popup_timer.timeout
	level_name_label.visible = false
	_clue_popup_timer = null
