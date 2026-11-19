extends CanvasLayer
## Campaign HUD, subtitles, pause, death and checkpoint controls.

@onready var health_label: Label = $Root/TopLeft/HealthLabel
@onready var battery_label: Label = $Root/TopLeft/BatteryLabel
@onready var bag_label: Label = $Root/TopLeft/BagLabel
@onready var objective_label: Label = $Root/TopRight/ObjectiveLabel
@onready var prompt_label: Label = $Root/PromptLabel
@onready var subtitle_panel: PanelContainer = $Root/SubtitlePanel
@onready var subtitle_label: Label = $Root/SubtitlePanel/SubtitleLabel
@onready var pause_panel: PanelContainer = $Root/PausePanel
@onready var death_panel: PanelContainer = $Root/DeathPanel
@onready var resume_btn: Button = $Root/PausePanel/VBox/ResumeBtn
@onready var restart_btn: Button = $Root/PausePanel/VBox/RestartBtn
@onready var save_btn: Button = $Root/PausePanel/VBox/SaveBtn
@onready var menu_btn: Button = $Root/PausePanel/VBox/MenuBtn
@onready var resurrect_btn: Button = $Root/DeathPanel/VBox/ResurrectBtn

var subtitle_timer := 0.0
var hud_refresh_timer := 0.0
var journal_panel: PanelContainer
var journal_body: Label
var journal_map: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health_changed)
	GameState.inventory_changed.connect(_update_inventory)
	GameState.subtitle_requested.connect(_on_subtitle)
	GameState.player_died.connect(_on_player_died)
	GameState.player_resurrected.connect(_on_resurrected)
	GameState.journal_updated.connect(_refresh_journal)
	ObjectiveManager.objective_updated.connect(_on_objective_updated)
	var player := get_parent()
	if player and player.has_signal("interaction_prompt_changed"):
		player.interaction_prompt_changed.connect(_on_prompt_changed)
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	save_btn.pressed.connect(_on_save)
	menu_btn.pressed.connect(_on_menu)
	resurrect_btn.pressed.connect(_on_resurrect)
	_create_journal()
	_update_all()
	objective_label.text = "Objective:\n" + ObjectiveManager.current_objective


func _process(delta: float) -> void:
	hud_refresh_timer += delta
	if hud_refresh_timer >= 0.5:
		hud_refresh_timer = 0.0
		battery_label.text = "LIGHT %s  %02d%%" % ["ON" if GameState.flashlight_enabled else "OFF", int(GameState.flashlight_battery)]
	if subtitle_timer > 0.0:
		subtitle_timer -= delta
		if subtitle_timer <= 0.0:
			subtitle_panel.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") and not GameState.is_dead:
		_toggle_journal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and journal_panel.visible:
		_toggle_journal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and not GameState.is_dead:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not pause_panel.visible and not death_panel.visible and not journal_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


func _on_resume() -> void:
	toggle_pause()


func _on_restart() -> void:
	get_tree().paused = false
	LevelManager.go_to_level(GameState.current_level_id, false)


func _on_save() -> void:
	if SaveManager.save_game():
		_on_subtitle("System", "Progress saved on this device.", 2.0)


func _on_menu() -> void:
	get_tree().paused = false
	LevelManager.go_to_level("main_menu", false)


func _on_resurrect() -> void:
	death_panel.hide()
	get_tree().paused = false
	GameState.trigger_resurrection()


func _on_resurrected(_count: int) -> void:
	death_panel.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_health_changed(hp: int, max_hp: int) -> void:
	health_label.text = "VITALITY  %03d / %03d" % [hp, max_hp]


func _update_inventory() -> void:
	var weapon_name := "Unarmed"
	var ammo_text := ""
	if not GameState.current_weapon.is_empty():
		weapon_name = str(GameState.WEAPONS[GameState.current_weapon]["title"])
		var ammo := GameState.ammo_for()
		if int(GameState.WEAPONS[GameState.current_weapon]["magazine"]) > 0:
			ammo_text = "  |  %02d / %02d" % [int(ammo["mag"]), int(ammo["reserve"])]
	bag_label.text = "Q  Blood bags: %d   |   %s%s" % [GameState.blood_bags, weapon_name, ammo_text]
	battery_label.text = "LIGHT %s  %02d%%" % ["ON" if GameState.flashlight_enabled else "OFF", int(GameState.flashlight_battery)]


func _on_objective_updated(text: String) -> void:
	objective_label.text = "OBJECTIVE\n" + text


func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text


func _on_subtitle(speaker: String, text: String, duration: float) -> void:
	subtitle_label.text = "%s  —  %s" % [speaker.to_upper(), text]
	subtitle_panel.show()
	subtitle_timer = duration


func _on_player_died() -> void:
	get_tree().paused = true
	death_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _update_all() -> void:
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_update_inventory()
	objective_label.text = "OBJECTIVE\n" + ObjectiveManager.current_objective


func _create_journal() -> void:
	journal_panel = PanelContainer.new()
	journal_panel.name = "JournalPanel"
	journal_panel.set_anchors_preset(Control.PRESET_CENTER)
	journal_panel.offset_left = -390.0
	journal_panel.offset_top = -300.0
	journal_panel.offset_right = 390.0
	journal_panel.offset_bottom = 300.0
	journal_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	$Root.add_child(journal_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	journal_panel.add_child(column)
	var heading := Label.new()
	heading.text = "THE LEDGER  |  FIELD JOURNAL"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	column.add_child(heading)
	journal_map = Label.new()
	journal_map.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(journal_map)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	journal_body = Label.new()
	journal_body.custom_minimum_size.x = 720.0
	journal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_body.add_theme_constant_override("line_spacing", 5)
	scroll.add_child(journal_body)
	var close_button := Button.new()
	close_button.text = "Close  [J / Esc]"
	close_button.pressed.connect(_toggle_journal)
	column.add_child(close_button)
	journal_panel.hide()
	_refresh_journal()


func _toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	if journal_panel.visible:
		_refresh_journal()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_journal() -> void:
	if not journal_body:
		return
	var region_names := {
		"level_01": "Dead Settlement",
		"level_02": "Butcher's Territory",
		"level_03": "Strategist's Bunker",
		"level_04": "Resurrection Temple",
		"level_05": "Memory Labyrinth"
	}
	var map_text := "DEAD SETTLEMENT  →  BUTCHER'S YARD  →  BUNKER  →  LEDGER  →  MEMORY LABYRINTH\n"
	map_text += "Visited: "
	var visited_names := PackedStringArray()
	for level_id: String in GameState.visited_levels:
		if region_names.has(level_id):
			visited_names.append(str(region_names[level_id]))
	journal_map.text = map_text + (", ".join(visited_names) if not visited_names.is_empty() else "no regions recorded")
	var body := "\nEVIDENCE & MEMORIES\n"
	if GameState.story_journal.is_empty():
		body += "No evidence recovered yet. Search each area and press E when a clue is in view."
	else:
		for entry_id: String in GameState.story_journal:
			var entry: Dictionary = GameState.story_journal[entry_id]
			body += "\n\n%s  |  %s\n%s" % [str(entry.get("category", "Evidence")).to_upper(), str(entry.get("title", entry_id)), str(entry.get("text", ""))]
	journal_body.text = body
