extends Control

@onready var new_game_btn: Button = $CenterBox/VBox/NewGameBtn
@onready var continue_btn: Button = $CenterBox/VBox/ContinueBtn
@onready var settings_btn: Button = $CenterBox/VBox/SettingsBtn
@onready var quit_btn: Button = $CenterBox/VBox/QuitBtn
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var sensitivity_slider: HSlider = $SettingsPanel/VBox/SensSlider
@onready var volume_slider: HSlider = $SettingsPanel/VBox/VolSlider
@onready var close_settings_btn: Button = $SettingsPanel/VBox/CloseSettingsBtn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(func() -> void: settings_panel.visible = true)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	close_settings_btn.pressed.connect(func() -> void: settings_panel.visible = false)
	sensitivity_slider.value = GameState.mouse_sensitivity * 1000.0
	volume_slider.value = GameState.master_volume
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	continue_btn.disabled = not SaveManager.has_save_file()


func _on_new_game() -> void:
	SaveManager.delete_save()
	await LevelManager.start_new_game()


func _on_continue() -> void:
	LevelManager.continue_game()


func _on_sensitivity_changed(value: float) -> void:
	GameState.mouse_sensitivity = value / 1000.0


func _on_volume_changed(value: float) -> void:
	GameState.master_volume = value
	AudioManager.apply_volume(value)
