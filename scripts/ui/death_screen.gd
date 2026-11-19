extends Control

@onready var resurrect_btn: Button = get_node_or_null("CenterBox/VBox/ResurrectBtn")
@onready var main_menu_btn: Button = get_node_or_null("CenterBox/VBox/MainMenuBtn")
@onready var rule_label: Label = get_node_or_null("CenterBox/VBox/RuleLabel")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if resurrect_btn:
		resurrect_btn.pressed.connect(_on_resurrect)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu)
	if rule_label:
		rule_label.text = "THE RESURRECTION RULE:\nDeath is not an escape. The entity brings you back."

func _on_resurrect() -> void:
	get_tree().paused = false
	GameState.trigger_resurrection()

func _on_main_menu() -> void:
	get_tree().paused = false
	LevelManager.go_to_level("main_menu", false)
