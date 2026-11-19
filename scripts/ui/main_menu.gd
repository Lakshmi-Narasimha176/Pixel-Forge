extends Control

@onready var new_game_btn: Button = get_node_or_null("CenterBox/VBox/NewGameBtn")
@onready var continue_btn: Button = get_node_or_null("CenterBox/VBox/ContinueBtn")
@onready var settings_btn: Button = get_node_or_null("CenterBox/VBox/SettingsBtn")
@onready var quit_btn: Button = get_node_or_null("CenterBox/VBox/QuitBtn")
@onready var settings_panel: PanelContainer = get_node_or_null("SettingsPanel")
@onready var close_btn: Button = get_node_or_null("SettingsPanel/VBox/CloseSettingsBtn")
@onready var sens_slider: HSlider = get_node_or_null("SettingsPanel/VBox/SensSlider")
@onready var vol_slider: HSlider = get_node_or_null("SettingsPanel/VBox/VolSlider")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.start_ambient("lost")
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
		continue_btn.disabled = not SaveSystem.has_save()
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
	if close_btn:
		close_btn.pressed.connect(_on_close_settings)
	if sens_slider:
		sens_slider.value = GameState.mouse_sensitivity * 3200.0
		sens_slider.value_changed.connect(_on_sens_changed)
	if vol_slider:
		vol_slider.value = GameState.master_volume
		vol_slider.value_changed.connect(_on_vol_changed)

func _on_new_game() -> void:
	AudioManager.play_ui_sfx("click")
	SaveSystem.delete_save()
	LevelManager.start_new_game()

func _on_continue() -> void:
	AudioManager.play_ui_sfx("click")
	LevelManager.continue_game()

func _on_settings() -> void:
	AudioManager.play_ui_sfx("click")
	if settings_panel:
		settings_panel.visible = true

func _on_close_settings() -> void:
	AudioManager.play_ui_sfx("back")
	if settings_panel:
		settings_panel.visible = false

func _on_quit() -> void:
	AudioManager.play_ui_sfx("click")
	get_tree().quit()

func _on_sens_changed(value: float) -> void:
	GameState.mouse_sensitivity = value / 3200.0

func _on_vol_changed(value: float) -> void:
	GameState.master_volume = value
	AudioManager.apply_volume(value)
