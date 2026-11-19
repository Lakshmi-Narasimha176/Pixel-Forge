extends Interactable
## Small, choice-based post-encounter character interaction; choices are saved by GameState.

@export var character_id: String = "betrayer"
@export var requires_secret: String = "friend_shot_to_break_the_binding_ritual"
@export var forgive_event_id: String = "l5_choice_forgive"
@export var refuse_event_id: String = "l5_choice_refuse"


func interact(_player: Node) -> void:
	if not bool(GameState.get_flag("betrayer_defeated", false)):
		GameState.show_subtitle("Your Friend", "The echo cannot hold together while the pact still has a living guard.", 4.0)
		return
	if not GameState.revealed_secrets.has(requires_secret):
		GameState.show_subtitle("Thought", "I need the whole story before I decide what to do with him.", 3.5)
		return
	if bool(GameState.get_flag("ending_forgive", false)) or bool(GameState.get_flag("ending_refuse", false)):
		GameState.show_subtitle("Your Friend", "I will carry your answer, whatever it is.", 3.5)
		return

	var choice := ConfirmationDialog.new()
	choice.title = "THE LAST CONVERSATION"
	choice.dialog_text = "He does not ask you to call the murder mercy. What do you choose?"
	choice.ok_button_text = "I forgive you, but remember."
	var refuse_button: Button = choice.add_cancel_button("I cannot forgive you.")
	get_tree().root.add_child(choice)
	choice.confirmed.connect(func(): _record_choice(choice, forgive_event_id, "forgive"))
	refuse_button.pressed.connect(func(): _record_choice(choice, refuse_event_id, "refuse"))
	choice.popup_centered()


func _record_choice(dialog: ConfirmationDialog, event_id: String, option_id: String) -> void:
	GameState.choose_dialogue("final_confrontation", option_id)
	if GameState.apply_story_event(event_id):
		ObjectiveManager.complete_objective("l5_obj_final_choice")
		SaveManager.save_game()
	dialog.queue_free()
