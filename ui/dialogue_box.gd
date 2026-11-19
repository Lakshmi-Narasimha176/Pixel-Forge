extends CanvasLayer

## Dialogue box controller for "The Last Revenge"
## Provides typewriter-effect line display and hooks to DialogueManager.

@onready var speaker_label: Label = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/speaker_label
@onready var dialogue_text: RichTextLabel = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/dialogue_text
@onready var next_btn: Button = $PanelContainer/VBoxContainer/next_btn
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _typewriter_timer: float = 0.0
var _full_text: String = ""
var _char_index: int = 0
var _typing: bool = false
const TYPEWRITER_SPEED: float = 0.03  # seconds per character


func _ready() -> void:
	hide()
	next_btn.pressed.connect(_on_next_btn_pressed)


func _process(delta: float) -> void:
	if not _typing:
		return
	_typewriter_timer -= delta
	if _typewriter_timer <= 0.0:
		_typewriter_timer = TYPEWRITER_SPEED
		_char_index += 1
		dialogue_text.text = _full_text.substr(0, _char_index)
		if _char_index >= _full_text.length():
			_typing = false


func show_line(speaker: String, text: String) -> void:
	speaker_label.text = speaker.to_upper()
	_full_text = text
	_char_index = 0
	dialogue_text.text = ""
	_typing = true
	_typewriter_timer = TYPEWRITER_SPEED
	show()
	if anim_player.has_animation("slide_in"):
		anim_player.play("slide_in")


func _skip_typewriter() -> void:
	if _typing:
		_typing = false
		dialogue_text.text = _full_text
		_char_index = _full_text.length()


func _on_next_btn_pressed() -> void:
	if _typing:
		_skip_typewriter()
		return
	DialogueManager.next_line()


func hide_dialogue() -> void:
	if anim_player.has_animation("slide_out"):
		anim_player.play("slide_out")
		await anim_player.animation_finished
	hide()
