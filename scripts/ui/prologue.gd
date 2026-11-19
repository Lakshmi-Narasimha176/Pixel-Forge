extends Control
## Brief text-driven murder prologue. It runs locally and can be skipped at any time.

@onready var chapter_label: Label = $Center/VBox/ChapterLabel
@onready var story_label: Label = $Center/VBox/StoryLabel

var _skipped := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Center/VBox/SkipButton.pressed.connect(_skip)
	call_deferred("_play")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		_skip()


func _play() -> void:
	var cards := [
		["THREE NIGHTS AGO", "You and your closest friend found a name in a book that should not exist."],
		["THE BETRAYAL", "He knew you trusted him. He raised the gun anyway."],
		["THE SHOT", "The reason died with you. The choice was his."],
		["THE LEDGER OF PASSAGE", "A new claimant entered. Your story begins where the living world ends."]
	]
	for card: Array in cards:
		if _skipped:
			return
		chapter_label.text = str(card[0])
		story_label.text = str(card[1])
		story_label.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(story_label, "modulate:a", 1.0, 0.55)
		await tween.finished
		await get_tree().create_timer(2.0).timeout
	if not _skipped:
		_enter_dead_world()


func _skip() -> void:
	if not _skipped:
		_skipped = true
		_enter_dead_world()


func _enter_dead_world() -> void:
	if _skipped and not is_inside_tree():
		return
	_skipped = true
	LevelManager.go_to_level("level_01", true)
