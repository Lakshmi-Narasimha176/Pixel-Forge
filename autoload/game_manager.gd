extends Node
## Legacy helper kept for scene scripts from the earlier project layout.

func change_level(level_number: int) -> void:
	LevelManager.go_to_level("level_%02d" % clampi(level_number, 1, 5), true)


func resurrect() -> void:
	GameState.trigger_resurrection()
