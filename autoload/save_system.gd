extends Node
## Legacy method aliases. New game code should call SaveManager directly.

func has_save() -> bool:
	return SaveManager.has_save_file()


func save_game() -> bool:
	return SaveManager.save_game()


func load_game() -> bool:
	return SaveManager.load_game()


func delete_save() -> void:
	SaveManager.delete_save()
