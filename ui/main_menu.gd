extends CanvasLayer

## Main Menu UI controller.

@onready var begin_btn: Button = $CenterContainer/VBoxContainer/begin_btn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/quit_btn


func _ready() -> void:
	begin_btn.pressed.connect(_on_begin_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)


func _on_begin_pressed() -> void:
	GameManager.go_to_level(1)


func _on_quit_pressed() -> void:
	get_tree().quit()
