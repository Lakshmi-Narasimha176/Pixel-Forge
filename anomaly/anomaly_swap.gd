class_name AnomalySwap
extends Node
## One anomaly of an anomaly game: switches a surface between its normal and its anomaly look.
## PSX Anomaly Horror Texture Pack - bitkiln - https://bitkiln.itch.io
##
## Add it as a child of the thing that changes: a MeshInstance3D, a CSG shape, any GeometryInstance3D, a Decal,
## a Sprite3D or a WorldEnvironment (the sky pair). With no materials set, it reads the material the mesh already has (a material of this pack) and
## finds its anomaly version itself through AnomalyPairs, so in most cases there is nothing to set at all:
##
##     MeshInstance3D  (material: materials/03_House_Details/portrait_lady.tres)
##         AnomalySwap
##
## Then set_anomaly(true) shows the grinning portrait and set_anomaly(false) the normal one. AnomalyManager
## (anomaly_manager.gd) finds every AnomalySwap of the scene and picks the anomaly of each loop.
##
## Modes: SWAP_MATERIAL (default) swaps the material; APPEAR shows the target only during the anomaly (a shadow
## figure decal, writing on the wall, a door that should not be there); DISAPPEAR hides it during the anomaly.
## Swaps with the same anomaly_id change together, so every wallpapered wall of a room switches at once.
## While the PSX look of apply_psx.gd is on, the swap keeps it on.
##
## On a WorldEnvironment it swaps the environment: one of this pack's sky environments becomes its anomaly
## version (environments/sky_halloween_moon.tres -> sky_halloween_moon_anomaly.tres, the eye moon); your own
## Environment with a panorama sky of the pack keeps everything else and gets the anomaly panorama.

## Emitted when the anomaly is switched on or off.
signal anomaly_changed(on: bool)

enum Mode { SWAP_MATERIAL, APPEAR, DISAPPEAR }

## The group every AnomalySwap joins (AnomalyManager looks for this group).
const GROUP := &"anomaly_swaps"
## The group of the AnomalyManagers (AnomalyManager.MANAGER_GROUP).
const MANAGER_GROUP := &"anomaly_managers"
const _PSX_OVERRIDE := &"psx_original_material_override"
const _PSX_SURFACES := &"psx_original_surface_materials"

@export var mode := Mode.SWAP_MATERIAL
## The look without the anomaly. Empty: the material the target has when the scene starts.
@export var normal_material: Material
## The look with the anomaly. Empty: found through AnomalyPairs (a copy of normal_material with the anomaly
## textures of its pair, so UV scale, triplanar mapping and colors stay as you set them).
@export var anomaly_material: Material
## For a WorldEnvironment target: the environment without the anomaly. Empty: the one it has when the scene starts.
@export var normal_environment: Environment
## For a WorldEnvironment target: the environment with the anomaly. Empty: found through AnomalyPairs.
@export var anomaly_environment: Environment
## Surface of a MeshInstance3D to change. -1: the material_override (also used whenever the mesh has one).
@export var surface := 0
## The node that changes. Empty: the parent.
@export var target: NodePath
## Swaps with the same id switch together. Empty: the name of the texture pair (or of the target node).
@export var anomaly_id := ""
## What changes, for a HUD or a debug list. Empty: the description of the pair.
@export_multiline var description := ""
## How often AnomalyManager picks this anomaly compared with the others (1 = normal).
@export_range(0.0, 10.0, 0.1) var weight := 1.0
## Start with the anomaly on (handy to look at one in the editor or in a test run).
@export var start_active := false

## True while the anomaly is on.
var active := false
## The texture pair this swap uses ("" in APPEAR / DISAPPEAR mode or for materials outside the pack).
var pair_name := ""

var _target: Node
var _slot := ""
var _normal_textures := {}
var _anomaly_textures := {}
var _ready_done := false


func _ready() -> void:
	add_to_group(GROUP)
	setup()


func _exit_tree() -> void:
	# tell the managers at once, so they never call a node that is gone
	for manager in get_tree().get_nodes_in_group(MANAGER_GROUP):
		if manager.has_method("forget"):
			manager.call("forget", self)


## Finds the target and the two looks. Runs on _ready; call it again after changing target or the materials.
func setup() -> void:
	_target = get_node_or_null(target) if not target.is_empty() else get_parent()
	if _target == null:
		push_warning("AnomalySwap %s: no target" % get_path())
		return
	if mode == Mode.SWAP_MATERIAL:
		if _target is WorldEnvironment:
			_setup_environment()
		elif _target is Decal or _target is Sprite3D:
			_setup_textures()
		else:
			_setup_materials()
	else:
		var target_name := str(_target.name).to_snake_case()
		if anomaly_id == "":
			anomaly_id = target_name
		if description == "":
			description = "%s %s" % [target_name.replace("_", " "), "appears" if mode == Mode.APPEAR else "is gone"]
	_ready_done = true
	_apply(start_active)


## Switches the anomaly on or off.
func set_anomaly(on: bool) -> void:
	if not _ready_done:
		start_active = on
		return
	if on == active or not is_instance_valid(_target):
		return
	_apply(on)
	anomaly_changed.emit(on)


func toggle() -> void:
	set_anomaly(not active)


## True when this swap has two different looks to switch between (a valid anomaly).
func is_valid() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	if mode != Mode.SWAP_MATERIAL:
		return true
	if _slot == "environment":
		return normal_environment != null and anomaly_environment != null and normal_environment != anomaly_environment
	if _slot == "textures":
		return _normal_textures != _anomaly_textures
	return normal_material != null and anomaly_material != null and normal_material != anomaly_material


## The node that changes (null when it was freed).
func get_target() -> Node:
	return _target if is_instance_valid(_target) else null


func _apply(on: bool) -> void:
	active = on
	if not is_instance_valid(_target):
		return
	match mode:
		Mode.APPEAR:
			_target.set("visible", on)
		Mode.DISAPPEAR:
			_target.set("visible", not on)
		_:
			if _slot == "textures":
				var textures: Dictionary = _anomaly_textures if on else _normal_textures
				for prop in textures:
					_target.set(prop, textures[prop])
			elif _slot == "environment":
				(_target as WorldEnvironment).environment = anomaly_environment if on else normal_environment
			else:
				_write(anomaly_material if on else normal_material)


# ---------------------------------------------------------------------------------------------- materials
func _setup_materials() -> void:
	_slot = "override"
	var mi := _target as MeshInstance3D
	var gi := _target as GeometryInstance3D
	if surface >= 0 and gi != null and gi.material_override == null:
		if mi != null:
			_slot = "surface"
		elif _target is CSGShape3D and "material" in _target:
			_slot = "csg"
	var current := _read()
	if normal_material == null and anomaly_material == null:
		normal_material = current
	if normal_material != null and anomaly_material == null:
		if AnomalyPairs.is_anomaly_material(normal_material):
			anomaly_material = normal_material
			normal_material = AnomalyPairs.make_variant(anomaly_material, false)
		else:
			anomaly_material = AnomalyPairs.make_variant(normal_material, true)
	elif normal_material == null and anomaly_material != null:
		normal_material = current if current != null else AnomalyPairs.make_variant(anomaly_material, false)
	pair_name = AnomalyPairs.pair_of_material(normal_material)
	if pair_name == "":
		pair_name = AnomalyPairs.pair_of_material(anomaly_material)
	_name_and_description()
	if not is_valid():
		push_warning("AnomalySwap %s: no anomaly version found for %s" % [get_path(), normal_material])


func _read() -> Material:
	match _slot:
		"surface":
			var mi := _target as MeshInstance3D
			if mi.has_meta(_PSX_SURFACES):
				var originals: Array = mi.get_meta(_PSX_SURFACES)
				if surface < originals.size() and originals[surface] != null:
					return originals[surface] as Material
			var m: Material = null
			if surface < mi.get_surface_override_material_count():
				m = mi.get_surface_override_material(surface)
			if m == null and mi.mesh != null and surface < mi.mesh.get_surface_count():
				m = mi.mesh.surface_get_material(surface)
			return m
		"csg":
			return _target.get("material") as Material
		_:
			if _target.has_meta(_PSX_OVERRIDE):
				return _target.get_meta(_PSX_OVERRIDE) as Material
			return (_target as GeometryInstance3D).material_override


func _write(material: Material) -> void:
	match _slot:
		"surface":
			var mi := _target as MeshInstance3D
			if surface >= mi.get_surface_override_material_count():
				return
			if mi.has_meta(_PSX_SURFACES):
				var originals: Array = mi.get_meta(_PSX_SURFACES)
				if surface < originals.size():
					originals[surface] = material
					mi.set_surface_override_material(surface, _psx_version(material))
					return
			mi.set_surface_override_material(surface, material)
		"csg":
			_target.set("material", material)
		_:
			var gi := _target as GeometryInstance3D
			if gi.has_meta(_PSX_OVERRIDE):
				gi.set_meta(_PSX_OVERRIDE, material)
				gi.material_override = _psx_version(material)
			else:
				gi.material_override = material


## The PSX version of a material while apply_psx.gd's look is on.
func _psx_version(material: Material) -> Material:
	var psx := load("res://shaders/apply_psx.gd") as GDScript
	if psx == null:
		return material
	return psx.call("convert_material", material) as Material


# ---------------------------------------------------------------------------------------------- environment (sky pair)
func _setup_environment() -> void:
	_slot = "environment"
	var current := (_target as WorldEnvironment).environment
	if normal_environment == null and anomaly_environment == null:
		normal_environment = current
	if normal_environment != null and anomaly_environment == null:
		if AnomalyPairs.is_anomaly_environment(normal_environment):
			anomaly_environment = normal_environment
			normal_environment = AnomalyPairs.environment_variant(anomaly_environment, false)
		else:
			anomaly_environment = AnomalyPairs.environment_variant(normal_environment, true)
	elif normal_environment == null and anomaly_environment != null:
		normal_environment = current if current != null else AnomalyPairs.environment_variant(anomaly_environment, false)
	pair_name = AnomalyPairs.pair_of_environment(normal_environment)
	_name_and_description()
	if not is_valid():
		push_warning("AnomalySwap %s: no anomaly sky found for %s" % [get_path(), normal_environment])


# ---------------------------------------------------------------------------------------------- textures (Decal, Sprite3D)
func _setup_textures() -> void:
	_slot = "textures"
	var props: Array[String] = ["texture"]
	if _target is Decal:
		props = ["texture_albedo", "texture_normal", "texture_emission"]
	for prop in props:
		var tex := _target.get(prop) as Texture2D
		if tex == null:
			continue
		_normal_textures[prop] = AnomalyPairs.swap_texture(tex, false)
		_anomaly_textures[prop] = AnomalyPairs.swap_texture(tex, true)
		if pair_name == "":
			pair_name = AnomalyPairs.pair_of_texture(tex)
	_name_and_description()


func _name_and_description() -> void:
	if anomaly_id == "":
		anomaly_id = pair_name if pair_name != "" else str(_target.name).to_snake_case()
	if description == "":
		description = AnomalyPairs.describe(pair_name)
