extends Node
## Central coordinator linking UI, GameState, and Level loading.

signal player_health_changed(current: int, max_hp: int)
signal player_died()
signal flashlight_changed(battery: float, is_on: bool)
signal blood_bag_count_changed(count: int)
signal weapon_changed(has_weapon: bool)
signal subtitle_requested(speaker: String, text: String, duration: float)

var current_level: int = 1
var flashlight_on: bool = true

var player_health: int:
	get: return GameState.health
var max_health: int:
	get: return GameState.MAX_HEALTH
var blood_bags: int:
	get: return GameState.blood_bags
var has_weapon: bool:
	get: return GameState.has_weapon
var flashlight_battery: float:
	get: return GameState.flashlight_battery


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_default_inputs()
	GameState.health_changed.connect(func(c, m): player_health_changed.emit(c, m))
	GameState.player_died.connect(func(): player_died.emit())
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.subtitle_requested.connect(func(s, t, d): subtitle_requested.emit(s, t, d))


func _setup_default_inputs() -> void:
	var mappings := {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"sprint": KEY_SHIFT,
		"crouch": KEY_C,
		"flashlight": KEY_F,
		"interact": KEY_E,
		"heal": KEY_Q,
		"pause": KEY_ESCAPE
	}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = mappings[action]
			InputMap.action_add_event(action, ev)

	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mb)


func _on_inventory_changed() -> void:
	blood_bag_count_changed.emit(GameState.blood_bags)
	weapon_changed.emit(GameState.has_weapon)


func change_level(level_num: int) -> void:
	current_level = level_num
	var level_id := "level_0%d" % level_num
	GameState.current_level_id = level_id
	if LevelManager:
		LevelManager.go_to_level(level_id, false)


func resurrect() -> void:
	GameState.trigger_resurrection()
