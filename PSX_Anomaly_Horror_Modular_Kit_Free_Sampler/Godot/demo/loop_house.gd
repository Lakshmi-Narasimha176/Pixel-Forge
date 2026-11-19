extends Node3D
## The anomaly loop of the PSX Anomaly Horror Modular Kit (bitkiln - https://bitkiln.itch.io), built from kit pieces:
## the hallway, the living room and the stairs of the Hollis house at 27 Wren Lane, on a Halloween night that never
## ends. The shell is GridMaps with the kit's MeshLibraries; the pieces that can change are the kit's ready anomaly
## scenes (psx_anomaly_horror_modular_kit/anomaly/<name>.tscn, AnomalyPiece).
##
## Walk through the house and look closely. If something is wrong (one piece shows its anomaly), turn back; if not,
## keep going. A right choice adds 1 to the loop number, a wrong one sets it back to 0. Reach loop 8
## (AnomalyManager.goal) to get out. R starts a new run.
##
## How the loop works: the house is entered and left through two short passages shaped like an S (two 90 degree
## turns). From the middle of a passage neither end can be seen, and both passages are built the same way (each
## one also looks the same from both ends), so the player can be moved between them without a visible jump:
##   * going on: crossing the middle of the far passage (eastwards) moves the player by far-to-near into the middle
##     of the near passage, from where the house lies ahead again (a new loop);
##   * turning back: crossing the middle of the near passage the wrong way (westwards) turns the player 180 degrees
##     around that middle, so the house lies ahead again too.
## In the full kit the far passage is upstairs: the move also takes the player down one story, unseen.

@export var manager_path := NodePath("AnomalyManager")
@export var player_path := NodePath("Player")
## Middle of the near passage (the house is entered from it) and of the far passage.
@export var near_center := Vector3.ZERO
@export var far_center := Vector3.ZERO
## Half the width (along Z) and half the length (along X) of the passages around their middles.
@export var band_half_width := 0.9
@export var band_half_length := 2.8
## The box of the house: entering it means the player has seen this loop.
@export var house_min := Vector3.ZERO
@export var house_max := Vector3.ZERO
## Label3D signs that show the loop number, and lights that stutter when a new loop starts.
@export var counter_signs: Array[NodePath] = []
@export var loop_lights: Array[NodePath] = []
@export var title := "PSX ANOMALY HORROR MODULAR KIT"
## The scene that Tab opens.
@export_file("*.tscn") var other_scene := ""

var manager: AnomalyManager
var player: CharacterBody3D
## Loops played since the scene started (tests and screenshots read it).
var loops_played := 0
## The last choice: "on" (went on), "back" (turned back) or "".
var last_choice := ""

var _last := Vector3.ZERO
var _visited := false
var _message_time := 0.0

@onready var _loop_label: Label = $HUD/Loop
@onready var _message: Label = $HUD/Message
@onready var _help: Label = $HUD/Help


func _ready() -> void:
	manager = get_node(manager_path) as AnomalyManager
	player = get_node(player_path) as CharacterBody3D
	_last = player.global_position
	_message.text = ""
	_help.text = title + "   anomaly loop\nWASD / arrows walk    mouse look (click)    Shift run    F flashlight    Esc free the mouse    R new run    H help" + ("    Tab showcase" if other_scene != "" else "")
	_start.call_deferred()


func _start() -> void:
	manager.collect()
	manager.reset_run()
	_update_counters()
	say("Something in this house changes from one loop to the next.\nIf something is wrong, turn back. If not, keep going.", 8.0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			manager.reset_run()
			_update_counters()
			say("Back to loop 0.")
		KEY_H:
			_help.visible = not _help.visible
		KEY_TAB:
			if other_scene != "" and ResourceLoader.exists(other_scene):
				get_tree().change_scene_to_file.call_deferred(other_scene)
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message.text = ""


func _physics_process(_delta: float) -> void:
	_check_loop()


func _check_loop() -> void:
	var p: Vector3 = player.global_position
	if p.x > house_min.x and p.x < house_max.x and p.y > house_min.y and p.y < house_max.y \
			and p.z > house_min.z and p.z < house_max.z:
		_visited = true
	if _in_band(p, far_center) and _last.x < far_center.x and p.x >= far_center.x:
		player.call("transport", Transform3D(Basis.IDENTITY, near_center - far_center))
		_decide(false)
	elif _in_band(p, near_center) and _last.x > near_center.x and p.x <= near_center.x:
		player.call("transport", turn_around(near_center))
		if _visited:
			_decide(true)
	_last = player.global_position


## The transform that turns a point 180 degrees around the vertical line through center.
static func turn_around(center: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, PI), center) * Transform3D(Basis.IDENTITY, -center)


func _in_band(p: Vector3, c: Vector3) -> bool:
	return absf(p.z - c.z) < band_half_width and absf(p.x - c.x) < band_half_length and absf(p.y - c.y) < 1.2


## Judges the choice of the loop that just ended and starts the next one.
func _decide(turned_back: bool) -> void:
	var description := manager.get_active_description()
	var had_anomaly := manager.is_anomaly_active()
	var correct := manager.submit_choice(turned_back)
	_visited = false
	loops_played += 1
	last_choice = "back" if turned_back else "on"
	var text := ""
	if correct and manager.streak >= manager.goal:
		text = "Loop %d. The front door is open: you made it out of 27 Wren Lane.\nKeep going to walk the loop again." % manager.goal
		manager.reset_run()
	else:
		if correct and had_anomaly:
			text = "You turned back. Something was wrong: %s." % description
		elif correct:
			text = "Nothing was wrong. Keep going."
		elif had_anomaly:
			text = "You missed it: %s.\nBack to loop 0." % description
		else:
			text = "There was nothing wrong.\nBack to loop 0."
		if correct:
			manager.start_loop()
		else:
			manager.reset_run()                  # back to loop 0: a normal loop to look at the house again
	_update_counters()
	for path in loop_lights:
		var light := get_node_or_null(path)
		if light != null and light.has_method("dip"):
			light.call("dip", 0.7)
	say(text, 5.0)


## Shows a message at the bottom of the screen for some seconds.
func say(text: String, seconds := 3.0) -> void:
	_message.text = text
	_message_time = seconds


## Shows one anomaly now (id from AnomalyManager.get_anomaly_ids(); "" = none). For screenshots and tests.
func show_anomaly(id: String) -> void:
	manager.force_anomaly(id)


func _update_counters() -> void:
	var n := manager.streak
	for path in counter_signs:
		var label := get_node_or_null(path) as Label3D
		if label != null:
			label.text = str(n)
	_loop_label.text = "Loop %d of %d" % [n, manager.goal]
