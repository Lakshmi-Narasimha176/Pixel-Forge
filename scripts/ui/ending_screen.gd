extends Control
## Resolves the mystery, then lets the player decide what to do with that truth.

@onready var summary_label: Label = $CenterBox/VBox/SummaryLabel
@onready var choice_label: Label = $CenterBox/VBox/ChoiceLabel
@onready var revenge_btn: Button = $CenterBox/VBox/RevengeBtn
@onready var release_btn: Button = $CenterBox/VBox/ReleaseBtn
@onready var break_btn: Button = $CenterBox/VBox/BreakLedgerBtn
@onready var menu_btn: Button = $CenterBox/VBox/MenuBtn
@onready var replay_btn: Button = $CenterBox/VBox/ReplayBtn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	summary_label.text = "Your friend killed you on purpose to keep the Ledger from claiming your soul. He hoped you would break the contract from within, but chose for you and concealed his own fear. Understanding his reason does not undo the betrayal."
	choice_label.text = "The two claimants are defeated. The contract opens. What will you do?"
	revenge_btn.pressed.connect(func() -> void: _choose("revenge"))
	release_btn.pressed.connect(func() -> void: _choose("release"))
	break_btn.pressed.connect(func() -> void: _choose("break_ledger"))
	menu_btn.pressed.connect(func() -> void: LevelManager.go_to_level("main_menu", false))
	replay_btn.pressed.connect(func() -> void: LevelManager.start_new_game())


func _choose(choice: String) -> void:
	GameState.set_flag("ending_choice", choice)
	match choice:
		"revenge":
			choice_label.text = "REVENGE — You refuse to absolve him. The Ledger accepts your answer, and his last lie is finally over. In the dawn, a new name appears in the book: yours."
		"release":
			choice_label.text = "RELEASE — You let his soul go without calling the killing right. The dawn comes quietly. Far below, the Ledger turns a page by itself."
		"break_ledger":
			choice_label.text = "BREAK THE LEDGER — You shatter the contract and free the tethered dead. Somewhere in the living world, an unknown voice reads your name aloud."
	revenge_btn.disabled = true
	release_btn.disabled = true
	break_btn.disabled = true
	SaveManager.save_game()
