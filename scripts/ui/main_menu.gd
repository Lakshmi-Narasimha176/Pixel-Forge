extends Control

@onready var new_game_btn: Button = get_node_or_null("CenterBox/VBox/NewGameBtn")
@onready var continue_btn: Button = get_node_or_null("CenterBox/VBox/ContinueBtn")
@onready var quit_btn: Button = get_node_or_null("CenterBox/VBox/QuitBtn")
@onready var settings_btn: Button = get_node_or_null("CenterBox/VBox/SettingsBtn")
@onready var settings_panel: PanelContainer = get_node_or_null("SettingsPanel")
@onready var sens_slider: HSlider = get_node_or_null("SettingsPanel/VBox/SensSlider")
@onready var volume_slider: HSlider = get_node_or_null("SettingsPanel/VBox/VolSlider")
@onready var close_settings_btn: Button = get_node_or_null("SettingsPanel/VBox/CloseSettingsBtn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
		continue_btn.disabled = not SaveManager.has_save_file()
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
	if settings_btn:
		settings_btn.pressed.connect(func(): settings_panel.visible = true)
	if close_settings_btn:
		close_settings_btn.pressed.connect(func(): settings_panel.visible = false)
	if sens_slider:
		sens_slider.value = GameState.mouse_sensitivity * 1000.0
		sens_slider.value_changed.connect(_on_sensitivity_changed)
	if volume_slider:
		volume_slider.value = GameState.master_volume
		volume_slider.value_changed.connect(_on_volume_changed)

func _on_new_game() -> void:
	SaveManager.delete_save()
	LevelManager.start_new_game()

func _on_continue() -> void:
	LevelManager.continue_game()


func _on_sensitivity_changed(value: float) -> void:
	GameState.mouse_sensitivity = value / 1000.0


func _on_volume_changed(value: float) -> void:
	GameState.master_volume = value
	AudioManager.apply_volume(value)

func _on_quit() -> void:
	get_tree().quit()

