extends Node3D
## Showcase of the PSX Anomaly Horror Modular Kit (bitkiln - https://bitkiln.itch.io): every piece of the kit in rows
## per theme, with its name. The pieces of the anomaly pairs are their ready anomaly scenes (AnomalyPiece): K
## switches every pair to its anomaly version and back. Ceilings are shown upside down so they face the camera.
## Keys: K anomalies on / off, L labels, Tab the anomaly loop, H help; the camera keys are in fly_camera.gd.

const MOVE_KEYS := "WASD / arrows move    mouse look (click)    Shift faster    F walk / fly    E Q up / down    Esc free the mouse"

@export var title := "PSX ANOMALY HORROR MODULAR KIT"
@export var subtitle := ""
## The scene that Tab opens.
@export_file("*.tscn") var other_scene := ""

## True while K has switched the anomaly pieces on.
var anomalies_on := false

var _labels_visible := true
var _fps_wait := 0.0

@onready var _camera = $Camera
@onready var _help: Label = $HUD/Help
@onready var _status: Label = $HUD/Status


func _ready() -> void:
	_help.text = title + ("   " + subtitle if subtitle != "" else "") + "\n" + MOVE_KEYS + "\nK anomalies on / off    L labels" + ("    Tab anomaly loop" if other_scene != "" else "") + "    H help"
	_update_status()


## Switches every anomaly piece of the scene to its anomaly version (true) or back (false).
func set_all_anomalies(on: bool) -> void:
	anomalies_on = on
	for piece in get_tree().get_nodes_in_group(AnomalyPiece.GROUP):
		piece.call("set_anomaly", on)
	_update_status()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_K:
			set_all_anomalies(not anomalies_on)
		KEY_L:
			_labels_visible = not _labels_visible
			get_tree().call_group("labels", "set_visible", _labels_visible)
		KEY_H:
			_help.visible = not _help.visible
		KEY_TAB:
			if other_scene != "" and ResourceLoader.exists(other_scene):
				get_tree().change_scene_to_file.call_deferred(other_scene)
		_:
			return
	_update_status()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_fps_wait -= delta
	if _fps_wait <= 0.0:
		_fps_wait = 0.5
		_update_status()


func _update_status() -> void:
	if not is_node_ready():
		return
	_status.text = "anomalies %s    |    %s    |    %d fps" % ["ON" if anomalies_on else "off",
			"fly" if _camera.get("flying") else "walk", Engine.get_frames_per_second()]
