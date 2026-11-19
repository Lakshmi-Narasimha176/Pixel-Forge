extends Node
## Headless engine smoke check for the shipped scenes. Run with --scene res://tools/qa/scene_validator.tscn.

const SCENES := [
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/ui/prologue.tscn",
	"res://scenes/levels/level_01/level_01.tscn",
	"res://scenes/levels/level_02/level_02.tscn",
	"res://scenes/levels/level_03/level_03.tscn",
	"res://scenes/levels/level_04/level_04.tscn",
	"res://scenes/levels/level_05/level_05.tscn",
	"res://scenes/ui/ending_screen.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/death_screen.tscn",
	"res://scenes/player/player.tscn",
	"res://scenes/enemies/lost_soul.tscn",
	"res://scenes/enemies/butcher.tscn",
	"res://scenes/enemies/strategist.tscn",
	"res://scenes/enemies/betrayer.tscn"
]


func _ready() -> void:
	call_deferred("_validate_scenes")


func _validate_scenes() -> void:
	var failures: Array[String] = []
	for scene_path: String in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			failures.append("Could not load " + scene_path)
			continue
		var instance := packed.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		if not is_instance_valid(instance):
			failures.append("Scene freed itself during startup: " + scene_path)
		else:
			instance.queue_free()
		await get_tree().process_frame
	if failures.is_empty():
		print("SCENE_VALIDATION_PASS: %d game scenes loaded and entered _ready()." % SCENES.size())
		get_tree().quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		get_tree().quit(1)
