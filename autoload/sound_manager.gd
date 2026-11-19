extends Node
## Legacy alias to the shared audio service.

func play_sfx(sound_name: String) -> void:
	AudioManager.play_sfx(sound_name)
