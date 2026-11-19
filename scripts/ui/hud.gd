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

@onready var resume_btn: Button = $Root/PausePanel/VBox/ResumeBtn
@onready var restart_btn: Button = $Root/PausePanel/VBox/RestartBtn
@onready var save_btn: Button = $Root/PausePanel/VBox/SaveBtn
@onready var menu_btn: Button = $Root/PausePanel/VBox/MenuBtn
@onready var resurrect_btn: Button = $Root/DeathPanel/VBox/ResurrectBtn

var subtitle_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.player_health_changed.connect(_on_health_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.flashlight_changed.connect(_on_flashlight_changed)
	GameManager.blood_bag_count_changed.connect(_on_bag_count_changed)
	GameManager.weapon_changed.connect(_on_weapon_changed)
	GameManager.subtitle_requested.connect(show_subtitle)

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
	GameManager.change_level(GameManager.current_level)

func _on_save() -> void:
	SaveSystem.save_game()
	show_subtitle("System", "Progress saved.", 2.0)

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_resurrect() -> void:
	death_panel.visible = false
	get_tree().paused = false
	GameManager.resurrect()

func _on_health_changed(hp: int, max_hp: int) -> void:
	if health_label:
		health_label.text = "Health: %d / %d" % [hp, max_hp]

func _on_flashlight_changed(battery: float, enabled: bool) -> void:
	if battery_label:
		var state = "ON" if enabled else "OFF"
		battery_label.text = "Flashlight [%s]: %d%%" % [state, int(battery)]

func _on_bag_count_changed(count: int) -> void:
	_update_bag_label(count, GameManager.has_weapon)

func _on_weapon_changed(has_wep: bool) -> void:
	_update_bag_label(GameManager.blood_bags, has_wep)

func _update_bag_label(count: int, has_wep: bool) -> void:
	if bag_label:
		var wep_text = "Baseball Bat (LMB)" if has_wep else "Unarmed"
		bag_label.text = "Blood Bags [Q]: %d  |  %s" % [count, wep_text]

func _on_objective_updated(obj: Variant) -> void:
	if objective_label:
		var desc: String = ""
		if obj is Dictionary:
			desc = obj.get("description", "")
		elif obj is String:
			desc = obj
		objective_label.text = "Objective:\n" + desc

func _on_player_died() -> void:
	get_tree().paused = true
	death_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_prompt(text: String) -> void:
	if prompt_label:
		prompt_label.text = text

func show_subtitle(speaker: String, text: String, duration: float = 3.5) -> void:
	if subtitle_label and subtitle_panel:
		subtitle_label.text = "[%s]: %s" % [speaker, text]
		subtitle_panel.visible = true
		subtitle_timer = duration

func _update_all() -> void:
	_on_health_changed(GameManager.player_health, GameManager.max_health)
	_on_flashlight_changed(GameManager.flashlight_battery, GameManager.flashlight_on)
	_update_bag_label(GameManager.blood_bags, GameManager.has_weapon)
	if ObjectiveManager.current_objective:
		_on_objective_updated(ObjectiveManager.current_objective)

