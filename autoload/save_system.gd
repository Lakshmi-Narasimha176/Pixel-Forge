extends "res://autoload/save_manager.gd"
## SaveSystem alias for SaveManager with convenience methods

func has_save() -> bool:
	return has_save_file()

