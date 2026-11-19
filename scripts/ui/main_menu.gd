extends Control

@onready var new_game_btn: Button = get_node_or_null("CenterBox/VBox/NewGameBtn")
@onready var continue_btn: Button = get_node_or_null("CenterBox/VBox/ContinueBtn")
@onready var quit_btn: Button = get_node_or_null("CenterBox/VBox/QuitBtn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
		continue_btn.disabled = not SaveSystem.has_save()
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)

func _on_new_game() -> void:
	SaveSystem.delete_save()
	GameManager.change_level(1)

func _on_continue() -> void:
	SaveSystem.load_game()

func _on_quit() -> void:
	get_tree().quit()
