class_name AnomalyPairs
extends RefCounted
## The normal / anomaly texture pairs of the PSX Anomaly Horror Texture Pack (bitkiln - https://bitkiln.itch.io).
##
## Every pair is two textures with the same layout: the anomaly version hides one wrong detail (eyes in the
## wallpaper, a second door knob, "OPEN 25 HOURS"). Swap the material and the player has to spot the change.
## This file lists every pair of this project with its materials and textures, and finds the other half of any
## material or texture of a pair:
##
##     AnomalyPairs.names()                                   # every pair name ("portrait_lady", ...)
##     AnomalyPairs.describe("portrait_lady")                 # what changes in the anomaly version
##     AnomalyPairs.load_material("portrait_lady", true)      # the anomaly material
##     AnomalyPairs.make_variant(my_material, true)           # a copy of any material with the anomaly textures
##
## AnomalySwap (anomaly_swap.gd) uses it to find the anomaly of the material a mesh already has.

## pair name -> category, kind (tile / tall / sign / decal / anim / sky), size (meters), what changes, materials
## ("normal", "anomaly", and for tiling textures "normal_triplanar", "anomaly_triplanar"; skies: environments).
const PAIRS := {
	# none in this project: the pieces of PSX Anomaly Horror Modular Kit swap their own materials
	# (psx_anomaly_horror_modular_kit/anomaly_piece.gd). With the texture pack, keep its anomaly_pairs.gd.
}

## Texture of the normal version -> texture of the anomaly version (albedo, normal map, glow map).
const TEXTURES := {

}

const SLOTS: Array[BaseMaterial3D.TextureParam] = [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL,
		BaseMaterial3D.TEXTURE_EMISSION]

static var _reverse := {}
static var _by_material := {}


## Every pair name, in the order of the pack's folders.
static func names() -> PackedStringArray:
	return PackedStringArray(PAIRS.keys())


static func has_pair(pair_name: String) -> bool:
	return PAIRS.has(pair_name)


## The entry of one pair (empty when there is no such pair).
static func get_pair(pair_name: String) -> Dictionary:
	return PAIRS.get(pair_name, {})


## What changes in the anomaly version of a pair, in one sentence.
static func describe(pair_name: String) -> String:
	return str(get_pair(pair_name).get("description", ""))


## The real-world size to place a sign, decal or tall texture of a pair at, in meters (signs and paper are drawn
## larger than life so they stay readable: place them at this size). Tiling textures: the size of one repeat.
static func get_size(pair_name: String) -> Vector2:
	var size: Array = get_pair(pair_name).get("size", [1.0, 1.0])
	return Vector2(float(size[0]), float(size[1]))


## Loads the normal (anomaly = false) or anomaly material of a pair. triplanar = true gives the world-space
## triplanar version (tiling textures only). Skies give their Environment.
static func load_material(pair_name: String, anomaly: bool, triplanar := false) -> Resource:
	var pair := get_pair(pair_name)
	var key := "anomaly" if anomaly else "normal"
	if triplanar and pair.has(key + "_triplanar"):
		key += "_triplanar"
	if not pair.has(key):
		return null
	return load(str(pair[key]))


## The pair a material belongs to ("" when none): found by its file, its textures or its name.
static func pair_of_material(material: Material) -> String:
	if material == null:
		return ""
	_index()
	if material.resource_path != "" and _by_material.has(material.resource_path):
		return str(_by_material[material.resource_path])
	for tex in textures_of(material):
		var found := pair_of_texture(tex)
		if found != "":
			return found
	var n := material.resource_name.trim_suffix("_psx").trim_suffix("_anomaly")
	return n if PAIRS.has(n) else ""


## The pair a texture belongs to ("" when none).
static func pair_of_texture(texture: Texture2D) -> String:
	if texture == null or texture.resource_path == "":
		return ""
	var path := texture.resource_path
	_index()
	var normal_path := path
	if _reverse.has(path):
		normal_path = str(_reverse[path])
	elif not TEXTURES.has(path):
		return ""
	var file := normal_path.get_file().get_basename()
	for suffix in ["_n", "_emit"]:
		if file.ends_with(suffix) and PAIRS.has(file.trim_suffix(suffix)):
			return file.trim_suffix(suffix)
	return file if PAIRS.has(file) else ""


## True when the material (or texture) shows the anomaly version of its pair.
static func is_anomaly_material(material: Material) -> bool:
	_index()
	if material == null:
		return false
	if material.resource_path != "" and _by_material.has(material.resource_path):
		return material.resource_path.get_file().get_basename().ends_with("_anomaly")
	for tex in textures_of(material):
		if _reverse.has(tex.resource_path):
			return true
		if TEXTURES.has(tex.resource_path):
			return false
	return material.resource_name.ends_with("_anomaly")


## The other version of a texture of a pair (anomaly = true: the anomaly version). Other textures come back as
## they are.
static func swap_texture(texture: Texture2D, anomaly: bool) -> Texture2D:
	if texture == null or texture.resource_path == "":
		return texture
	_index()
	var path := texture.resource_path
	if anomaly and TEXTURES.has(path):
		return load(str(TEXTURES[path])) as Texture2D
	if not anomaly and _reverse.has(path):
		return load(str(_reverse[path])) as Texture2D
	return texture


## A copy of any material (StandardMaterial3D, ORMMaterial3D or ShaderMaterial: the animated strips, the PSX
## materials of apply_psx.gd) with every texture of a pair swapped to its anomaly (anomaly = true) or normal
## version. Everything else (UV scale and offset, triplanar mapping, colors) stays as it is, so a material you
## tuned for your mesh keeps its tuning. Returns the material itself when none of its textures belongs to a pair.
static func make_variant(material: Material, anomaly: bool) -> Material:
	if material == null:
		return null
	var copy := material.duplicate() as Material
	var changed := false
	if copy is BaseMaterial3D:
		var m := copy as BaseMaterial3D
		for slot: BaseMaterial3D.TextureParam in SLOTS:
			var tex := m.get_texture(slot)
			var other := swap_texture(tex, anomaly)
			if other != tex:
				m.set_texture(slot, other)
				changed = true
	elif copy is ShaderMaterial:
		var sm := copy as ShaderMaterial
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				var param := StringName(str(u["name"]))
				var value: Variant = sm.get_shader_parameter(param)
				if not value is Texture2D:
					continue
				var tex := value as Texture2D
				var other := swap_texture(tex, anomaly)
				if other != tex:
					sm.set_shader_parameter(param, other)
					changed = true
	if not changed:
		return material
	var base := material.resource_name.trim_suffix("_anomaly")
	if base != "":
		copy.resource_name = base + ("_anomaly" if anomaly else "")
	return copy


## The panorama texture of an Environment's sky (null without a PanoramaSkyMaterial).
static func panorama_of(environment: Environment) -> Texture2D:
	if environment == null or environment.sky == null:
		return null
	var pano := environment.sky.sky_material as PanoramaSkyMaterial
	return pano.panorama if pano != null else null


## The sky pair an Environment belongs to ("" when none): this pack's environments, or any Environment whose
## panorama is a texture of a sky pair.
static func pair_of_environment(environment: Environment) -> String:
	if environment == null:
		return ""
	_index()
	if environment.resource_path != "" and _by_material.has(environment.resource_path):
		return str(_by_material[environment.resource_path])
	return pair_of_texture(panorama_of(environment))


## True when the Environment shows the anomaly version of its sky pair.
static func is_anomaly_environment(environment: Environment) -> bool:
	_index()
	if environment == null:
		return false
	if environment.resource_path != "" and _by_material.has(environment.resource_path):
		return environment.resource_path.get_file().get_basename().ends_with("_anomaly")
	var tex := panorama_of(environment)
	return tex != null and _reverse.has(tex.resource_path)


## The other version of an Environment of a sky pair (anomaly = true: the anomaly sky). One of this pack's
## environments gives the matching environment of the pack (its fog fits that sky); any other Environment gives a
## copy with the other panorama and everything else as it is. Returns the environment itself when its sky is not
## part of a pair.
static func environment_variant(environment: Environment, anomaly: bool) -> Environment:
	var pair_name := pair_of_environment(environment)
	if pair_name == "":
		return environment
	if environment.resource_path != "" and _by_material.has(environment.resource_path):
		var pack_env := load_material(pair_name, anomaly) as Environment
		if pack_env != null:
			return pack_env
	var tex := panorama_of(environment)
	var other := swap_texture(tex, anomaly)
	if other == tex:
		return environment
	var copy := environment.duplicate() as Environment
	copy.sky = environment.sky.duplicate() as Sky
	var pano := environment.sky.sky_material.duplicate() as PanoramaSkyMaterial
	pano.panorama = other
	copy.sky.sky_material = pano
	return copy


## The textures a material uses (albedo, normal and glow maps; every texture parameter of a ShaderMaterial).
static func textures_of(material: Material) -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	if material is BaseMaterial3D:
		var m := material as BaseMaterial3D
		for slot: BaseMaterial3D.TextureParam in SLOTS:
			var tex := m.get_texture(slot)
			if tex != null:
				found.append(tex)
	elif material is ShaderMaterial:
		var sm := material as ShaderMaterial
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				var value: Variant = sm.get_shader_parameter(StringName(str(u["name"])))
				if value is Texture2D:
					found.append(value as Texture2D)
	return found


static func _index() -> void:
	if not _reverse.is_empty() or TEXTURES.is_empty():
		return
	for path in TEXTURES:
		_reverse[TEXTURES[path]] = path
	for pair_name in PAIRS:
		var pair: Dictionary = PAIRS[pair_name]
		for key in ["normal", "anomaly", "normal_triplanar", "anomaly_triplanar"]:
			if pair.has(key):
				_by_material[pair[key]] = pair_name
