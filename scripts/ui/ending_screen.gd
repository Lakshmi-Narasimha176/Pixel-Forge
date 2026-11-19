extends Control
## Ending screen showing story payoff and resurrection summary.

@onready var summary_label: Label = $CenterBox/VBox/SummaryLabel
@onready var menu_btn: Button = $CenterBox/VBox/MenuBtn
@onready var replay_btn: Button = $CenterBox/VBox/ReplayBtn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var loophole_text := "You broke the resurrection pact using the loophole." if GameState.resurrection_loophole_found else "You survived the Betrayer's final confrontation."
	summary_label.text = "%s\n\nResurrections endured: %d\nItems recovered: %d" % [
		loophole_text,
		GameState.resurrection_count,
		GameState.collected_items.size()
	]
	menu_btn.pressed.connect(func(): LevelManager.go_to_level("main_menu", false))
	replay_btn.pressed.connect(func(): LevelManager.start_new_game())
