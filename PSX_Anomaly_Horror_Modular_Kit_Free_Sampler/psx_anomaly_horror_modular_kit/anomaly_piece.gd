class_name AnomalyPiece
extends Node3D
## A level piece that can be the anomaly of a loop. PSX Anomaly Horror Modular Kit - bitkiln - https://bitkiln.itch.io
##
## Every anomaly pair of the kit has a ready scene in psx_anomaly_horror_modular_kit/anomaly/<name>.tscn: this script
## on a Node3D with the normal piece as "Model" (a MeshInstance3D with the kit mesh and its PSX materials) and its
## collision as "Body". When the scene starts it adds AnomalySwap nodes (anomaly/anomaly_swap.gd of the PSX Anomaly
## Horror Texture Pack), so the AnomalyManager of the scene picks the piece like any other anomaly:
##   * texture pairs (the same mesh, an anomaly texture on one or more surfaces): one SWAP_MATERIAL swap per surface
##     whose material differs between anomaly_mesh and the model;
##   * mesh pairs (mesh_change: the doorway is gone, the fireplace is bricked up ...): the model disappears and
##     "AnomalyModel" appears, and the collision follows ("Body" off, "AnomalyBody" on).
##
##     var wall := load("res://psx_anomaly_horror_modular_kit/anomaly/house_wall_floral.tscn").instantiate()
##     add_child(wall)
##     wall.set_anomaly(true)         # the anomaly version
##
## companions: nodes that leave together with the anomaly (hidden, their collision off). house_wall_door_anomaly
## closes the door opening, so the door leaf standing in it is a companion and goes too.
## Like AnomalyProp of PSX Anomaly Horror Props, any piece can also be an anomaly by being moved, turned or dark:
## set anomaly_offset, anomaly_rotation_deg and / or anomaly_light_off (with or without a pair).
##
## The anomaly_id is the node name unless you set one: give several pieces the same anomaly_id to change them
## together (every floral wall of a room). difficulty lowers the chance of hard anomalies (weight x 0.6).

## Emitted when the anomaly is switched on or off.
signal anomaly_changed(on: bool)

enum Difficulty { EASY, MEDIUM, HARD }

## The group every AnomalyPiece joins (the showcase's K key switches them all).
const GROUP := &"anomaly_pieces"
## The group of the anomaly nodes AnomalyManager uses (AnomalySwap.GROUP).
const SWAP_GROUP := &"anomaly_swaps"
## weight multiplier per difficulty: hard anomalies come less often
const DIFFICULTY_WEIGHT := [1.0, 1.0, 0.6]

## The anomaly version of the piece: the same mesh with the anomaly materials (texture pair) or the changed mesh
## (mesh_change). Empty: no swap (use the options below).
@export var anomaly_mesh: Mesh
## The anomaly changes the mesh, not only a texture: the two models (and their collision) swap.
@export var mesh_change := false
## Nodes hidden (and without collision) during the anomaly, e.g. the door leaf in an opening the anomaly closes.
@export var companions: Array[NodePath] = []
## Swaps with the same id switch together. Empty: the name of this node.
@export var anomaly_id := ""
## What changes, for a HUD or a debug list.
@export_multiline var description := ""
## How hard the anomaly is to spot. Hard ones are picked less often (weight x 0.6).
@export var difficulty := Difficulty.MEDIUM
## How often AnomalyManager picks this piece compared with the other anomalies (1 = normal, 0 = never), before the
## difficulty factor.
@export_range(0.0, 10.0, 0.1) var weight := 1.0
## Start with the anomaly on.
@export var start_active := false

@export_group("Moved, turned, dark")
## During the anomaly the piece is moved by this offset (meters, in this node's space).
@export var anomaly_offset := Vector3.ZERO
## During the anomaly the piece is turned by these angles (degrees, around this node's origin).
@export var anomaly_rotation_deg := Vector3.ZERO
## During the anomaly the glowing parts go dark and the lights under this node are switched off.
@export var anomaly_light_off := false

## True while the anomaly is on.
var active := false
## The AnomalySwap nodes this piece made.
var swaps: Array[AnomalySwap] = []

var _model: MeshInstance3D
var _anomaly_model: MeshInstance3D
var _xforms := {}
var _dark := {}
var _extra_on := false
var _weighted := false


func _ready() -> void:
	add_to_group(GROUP)
	if anomaly_id == "":
		anomaly_id = str(name).to_snake_case()
	_model = get_node_or_null("Model") as MeshInstance3D
	if _model == null:
		for child in get_children():
			if child is MeshInstance3D:
				_model = child
				break
	if _model == null:
		push_warning("AnomalyPiece %s: no Model under it" % get_path())
		return
	if anomaly_mesh != null and mesh_change:
		_anomaly_model = get_node_or_null("AnomalyModel") as MeshInstance3D
		if _anomaly_model == null:
			_anomaly_model = MeshInstance3D.new()
			_anomaly_model.name = "AnomalyModel"
			_anomaly_model.mesh = anomaly_mesh
			_anomaly_model.transform = _model.transform
			add_child(_anomaly_model)
		_anomaly_model.visible = false
		_add_swap(_model, -1, AnomalySwap.Mode.DISAPPEAR, null, null)
		_add_swap(_anomaly_model, -1, AnomalySwap.Mode.APPEAR, null, null)
	elif anomaly_mesh != null and _model.mesh != null:
		var count := mini(_model.mesh.get_surface_count(), anomaly_mesh.get_surface_count())
		for s in count:
			var normal_material := _model.get_active_material(s)
			var anomaly_material := anomaly_mesh.surface_get_material(s)
			if normal_material != null and anomaly_material != null and normal_material != anomaly_material:
				_add_swap(_model, s, AnomalySwap.Mode.SWAP_MATERIAL, normal_material, anomaly_material)
	if not swaps.is_empty():
		swaps[0].anomaly_changed.connect(_apply_extra)
	elif _has_extra():
		add_to_group(SWAP_GROUP)        # the piece itself is the anomaly node
		weight = get_weight()           # AnomalyManager reads weight: the difficulty factor goes in once
		_weighted = true
	for child in get_children():
		if child is Node3D and not (child is Light3D):
			_xforms[child] = (child as Node3D).transform
	_set_bodies(false)
	if start_active:
		set_anomaly(true)


## Switches the anomaly on or off.
func set_anomaly(on: bool) -> void:
	if on == active and (not swaps.is_empty() or _extra_on == on):
		return
	active = on
	for swap in swaps:
		if is_instance_valid(swap):
			swap.set_anomaly(on)
	if swaps.is_empty():
		_apply_extra(on)        # with swaps, the first swap's anomaly_changed runs _apply_extra


func toggle() -> void:
	set_anomaly(not active)


## True when the piece has an anomaly to switch to.
func is_valid() -> bool:
	if swaps.is_empty():
		return _has_extra() and _model != null
	for swap in swaps:
		if not is_instance_valid(swap) or not swap.is_valid():
			return false
	return true


## The weight AnomalyManager uses (weight x the difficulty factor).
func get_weight() -> float:
	if _weighted:
		return weight
	return weight * float(DIFFICULTY_WEIGHT[clampi(difficulty, 0, 2)])


## The model that shows now.
func get_visible_model() -> MeshInstance3D:
	return _anomaly_model if mesh_change and active and _anomaly_model != null else _model


## The companion nodes that exist.
func get_companions() -> Array[Node]:
	var out: Array[Node] = []
	for path in companions:
		var n := get_node_or_null(path)
		if n != null:
			out.append(n)
	return out


func _has_extra() -> bool:
	return anomaly_offset != Vector3.ZERO or anomaly_rotation_deg != Vector3.ZERO or anomaly_light_off


func _apply_extra(on: bool) -> void:
	active = on
	_extra_on = on
	_set_bodies(on)
	for n in get_companions():
		_set_present(n, not on)
	if anomaly_offset != Vector3.ZERO or anomaly_rotation_deg != Vector3.ZERO:
		var turn := Basis.from_euler(anomaly_rotation_deg * (PI / 180.0))
		var moved := Transform3D(turn, anomaly_offset)
		for child in _xforms:
			if is_instance_valid(child):
				(child as Node3D).transform = (moved * _xforms[child]) if on else _xforms[child]
	if anomaly_light_off:
		for light in find_children("*", "Light3D", true, false):
			(light as Light3D).visible = not on
		for n in find_children("*", "MeshInstance3D", true, false):
			_set_dark(n as MeshInstance3D, on)
	anomaly_changed.emit(on)


## Mesh pairs: the collision of the model that shows ("Body" for the normal piece, "AnomalyBody" for the anomaly).
func _set_bodies(on: bool) -> void:
	var anomaly_body := get_node_or_null("AnomalyBody")
	if anomaly_body == null:
		return
	var body := get_node_or_null("Body")
	if body != null:
		_set_shapes(body, not on)
	_set_shapes(anomaly_body, on)


func _set_shapes(root: Node, enabled: bool) -> void:
	var shapes := root.find_children("*", "CollisionShape3D", true, false)
	if root is CollisionShape3D:
		shapes.append(root)
	for s in shapes:
		(s as CollisionShape3D).set_deferred("disabled", not enabled)


## A companion shows (with its collision) or leaves (hidden, collision off).
func _set_present(n: Node, present: bool) -> void:
	if n is Node3D:
		(n as Node3D).visible = present
	_set_shapes(n, present)


## Glowing surfaces of a mesh go dark (an override material without emission) or back to their material.
func _set_dark(mi: MeshInstance3D, on: bool) -> void:
	if mi.mesh == null:
		return
	for s in mi.mesh.get_surface_count():
		var key := "%d:%d" % [mi.get_instance_id(), s]
		if on and not _dark.has(key):
			var m := mi.get_active_material(s)
			var dark: Material = null
			if m is BaseMaterial3D and (m as BaseMaterial3D).emission_enabled:
				dark = m.duplicate()
				(dark as BaseMaterial3D).emission_enabled = false
			elif m is ShaderMaterial and (m as ShaderMaterial).get_shader_parameter("use_emission_texture") == true:
				dark = m.duplicate()
				(dark as ShaderMaterial).set_shader_parameter("emission_energy", 0.0)
			if dark != null:
				_dark[key] = mi.get_surface_override_material(s)
				mi.set_surface_override_material(s, dark)
		elif not on and _dark.has(key):
			mi.set_surface_override_material(s, _dark[key])
			_dark.erase(key)


func _add_swap(target_node: Node, surface: int, mode: AnomalySwap.Mode, normal_material: Material,
		anomaly_material: Material) -> void:
	var swap := AnomalySwap.new()
	swap.name = "AnomalySwap%d" % swaps.size()
	swap.mode = mode
	swap.surface = surface
	swap.normal_material = normal_material
	swap.anomaly_material = anomaly_material
	swap.anomaly_id = anomaly_id
	swap.description = description
	swap.weight = get_weight()
	swap.target = NodePath("../" + str(get_path_to(target_node)))
	add_child(swap)
	swaps.append(swap)
