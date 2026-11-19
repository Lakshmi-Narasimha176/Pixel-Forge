extends Control

@onready var resume_btn: Button = get_node_or_null("CenterBox/VBox/ResumeBtn")
@onready var restart_btn: Button = get_node_or_null("CenterBox/VBox/RestartBtn")
@onready var main_menu_btn: Button = get_node_or_null("CenterBox/VBox/MainMenuBtn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume() -> void:
	toggle_pause()

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.change_level(GameManager.current_level)

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

