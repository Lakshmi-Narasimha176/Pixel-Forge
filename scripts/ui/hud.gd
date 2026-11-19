extends CanvasLayer

@onready var health_label: Label = $Root/TopLeft/HealthLabel
@onready var battery_label: Label = $Root/TopLeft/BatteryLabel
@onready var bag_label: Label = $Root/TopLeft/BagLabel
@onready var objective_label: Label = $Root/TopRight/ObjectiveLabel
@onready var prompt_label: Label = $Root/PromptLabel
@onready var subtitle_panel: PanelContainer = $Root/SubtitlePanel
@onready var subtitle_label: Label = $Root/SubtitlePanel/SubtitleLabel
@onready var pause_panel: PanelContainer = $Root/PausePanel
@onready var death_panel: PanelContainer = $Root/DeathPanel
@onready var journal_panel: PanelContainer = $Root/JournalPanel
@onready var journal_label: Label = $Root/JournalPanel/JournalText

@onready var resume_btn: Button = $Root/PausePanel/VBox/ResumeBtn
@onready var restart_btn: Button = $Root/PausePanel/VBox/RestartBtn
@onready var save_btn: Button = $Root/PausePanel/VBox/SaveBtn
@onready var menu_btn: Button = $Root/PausePanel/VBox/MenuBtn
@onready var resurrect_btn: Button = $Root/DeathPanel/VBox/ResurrectBtn

var subtitle_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health_changed)
	GameState.player_died.connect(_on_player_died)
	GameState.flashlight_changed.connect(_on_flashlight_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.subtitle_requested.connect(_on_story_subtitle)
	GameState.narrative_changed.connect(_update_journal)
	ObjectiveManager.objective_updated.connect(_on_objective_updated)

	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if save_btn:
		save_btn.pressed.connect(_on_save)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)
	if resurrect_btn:
		resurrect_btn.pressed.connect(_on_resurrect)

	_update_all()

func _process(delta: float) -> void:
	if subtitle_timer > 0.0:
		subtitle_timer -= delta
		if subtitle_timer <= 0.0 and subtitle_panel:
			subtitle_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not death_panel.visible:
			toggle_pause()
	elif event.is_action_pressed("journal") and not get_tree().paused:
		journal_panel.visible = not journal_panel.visible
		if journal_panel.visible:
			_update_journal()

func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume() -> void:
	toggle_pause()

func _on_restart() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	LevelManager.go_to_level(GameState.current_level_id, false)

func _on_save() -> void:
	SaveManager.save_game()
	show_subtitle("Progress saved.", 2.0)

func _on_menu() -> void:
	get_tree().paused = false
	LevelManager.go_to_level("main_menu", false)

func _on_resurrect() -> void:
	death_panel.visible = false
	get_tree().paused = false
	GameState.trigger_resurrection()

func _on_health_changed(hp: int, max_hp: int) -> void:
	if health_label:
		health_label.text = "Health: %d / %d" % [hp, max_hp]

func _on_flashlight_changed(battery: float, enabled: bool) -> void:
	if battery_label:
		var state = "ON" if enabled else "OFF"
		battery_label.text = "Flashlight [%s]: %d%%" % [state, int(battery)]

func _on_bag_count_changed(count: int) -> void:
	_update_bag_label(count, GameState.has_weapon)

func _on_weapon_changed(has_wep: bool) -> void:
	_update_bag_label(GameState.blood_bags, has_wep)


func _on_inventory_changed() -> void:
	_update_bag_label(GameState.blood_bags, GameState.has_weapon)

func _update_bag_label(count: int, has_wep: bool) -> void:
	if bag_label:
		var wep_text = "Baseball Bat (LMB)" if has_wep else "Unarmed"
		bag_label.text = "Blood Bags [Q]: %d  |  %s" % [count, wep_text]

func _on_objective_updated(objective: Dictionary) -> void:
	if objective_label:
		var description := str(objective.get("description", ""))
		objective_label.text = "Objective:\n" + (description if not description.is_empty() else "All objectives complete.")

func _on_player_died() -> void:
	get_tree().paused = true
	death_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text

func show_subtitle(text: String, duration: float = 3.5) -> void:
	if subtitle_label and subtitle_panel:
		subtitle_label.text = text
		subtitle_panel.visible = true
		subtitle_timer = duration


func _on_story_subtitle(speaker: String, text: String, duration: float) -> void:
	var line := "%s: %s" % [speaker, text] if not speaker.is_empty() else text
	show_subtitle(line, duration)


func _update_journal() -> void:
	if not journal_label:
		return
	var lines: Array[String] = ["FIELD JOURNAL  [TAB to close]", "", "CURRENT MYSTERY", GameState.current_mystery, "", "EVIDENCE"]
	if GameState.discovered_evidence.is_empty():
		lines.append("No evidence collected.")
	else:
		for evidence_id in GameState.discovered_evidence:
			var entry: Dictionary = GameState.discovered_evidence[evidence_id]
			lines.append("• %s — %s" % [entry.get("title", evidence_id), entry.get("text", "")])
	lines.append_array(["", "CONTRADICTIONS: %d   MEMORIES: %d   SECRETS: %d" % [
		GameState.discovered_contradictions.size(), GameState.unlocked_memories.size(), GameState.revealed_secrets.size()
	], "", "TRUST / DOUBT"])
	for character_id in GameState.character_trust:
		lines.append("%s  trust %d / suspicion %d" % [character_id.replace("_", " ").capitalize(), GameState.character_trust[character_id], GameState.character_suspicion.get(character_id, 0)])
	journal_label.text = "\n".join(lines)

func _update_all() -> void:
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_on_flashlight_changed(GameState.flashlight_battery, GameState.flashlight_on)
	_update_bag_label(GameState.blood_bags, GameState.has_weapon)
	_on_objective_updated(ObjectiveManager.current_objective)
	_update_journal()
