## main_menu.gd
## Script attached to the MainMenu scene root.
extends Node2D


func _ready() -> void:
	# If a save exists, enable Continue button
	var continue_btn := $CenterContainer/VBoxContainer/ContinueButton
	continue_btn.disabled = not FileAccess.file_exists("user://savegame.json")


func _on_new_game_pressed() -> void:
	GameManager.reset_state()
	GameManager.go_to_level(1)


func _on_continue_pressed() -> void:
	GameManager.load_state()
	var lvl := GameManager.current_level
	if lvl < 1:
		lvl = 1
	GameManager.go_to_level(lvl)


func _on_quit_pressed() -> void:
	get_tree().quit()
