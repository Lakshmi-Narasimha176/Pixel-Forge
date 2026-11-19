extends Control
## Ending screen showing story payoff and resurrection summary.

@onready var summary_label: Label = $CenterBox/VBox/SummaryLabel
@onready var menu_btn: Button = $CenterBox/VBox/MenuBtn
@onready var replay_btn: Button = $CenterBox/VBox/ReplayBtn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var ending_text := "You chose to forgive—not to excuse the murder, but to release the tether." if GameState.ending_id == "forgive" else "You refused forgiveness. The tether breaks, but the wound remains."
	var truth_text := "You learned your friend shot you to break the Witness's binding ritual after trying to find an escape. The Strategist altered the contract; the Butcher left a way out." if GameState.revealed_secrets.has("friend_shot_to_break_the_binding_ritual") else "The central murder mystery remains unresolved."
	summary_label.text = "%s\n\n%s\n\nThe Witness's true name remains unknown. The final gate is still listening.\n\nResurrections endured: %d\nEvidence recovered: %d" % [
		ending_text,
		truth_text,
		GameState.resurrection_count,
		GameState.discovered_evidence.size()
	]
	menu_btn.pressed.connect(func(): LevelManager.go_to_level("main_menu", false))
	replay_btn.pressed.connect(func(): LevelManager.start_new_game())
