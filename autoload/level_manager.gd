extends Node
## Handles level transitions, fade overlay, and safe scene loading.

const LEVEL_SCENES := {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"prologue": "res://scenes/ui/prologue.tscn",
	"level_01": "res://scenes/levels/level_01/level_01.tscn",
	"level_02": "res://scenes/levels/level_02/level_02.tscn",
	"level_03": "res://scenes/levels/level_03/level_03.tscn",
	"level_04": "res://scenes/levels/level_04/level_04.tscn",
	"level_05": "res://scenes/levels/level_05/level_05.tscn",
	"ending": "res://scenes/ui/ending_screen.tscn"
}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func go_to_level(level_id: String, reset_checkpoint: bool = true) -> void:
	if _is_transitioning:
		return
	if not LEVEL_SCENES.has(level_id):
		push_error("[LevelManager] Unknown level ID: %s" % level_id)
		return
	var scene_path: String = LEVEL_SCENES[level_id]
	if not ResourceLoader.exists(scene_path):
		push_error("[LevelManager] Missing scene file: %s" % scene_path)
		return

	_is_transitioning = true
	get_tree().paused = false

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.35)
	await tween.finished

	if level_id.begins_with("level_"):
		GameState.current_level_id = level_id
		if reset_checkpoint:
			GameState.has_checkpoint = false
		ObjectiveManager.load_level_objectives(level_id)
		SaveManager.save_game()

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[LevelManager] Failed to load scene %s (err=%d)" % [scene_path, err])

	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "color:a", 0.0, 0.35)
	await fade_in.finished
	_is_transitioning = false


func start_new_game() -> void:
	GameState.reset_for_new_game()
	ObjectiveManager.completed_objectives.clear()
	await go_to_level("prologue", true)


func continue_game() -> void:
	if SaveManager.load_game():
		await go_to_level(GameState.current_level_id, false)
	else:
		await start_new_game()
