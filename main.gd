extends Node3D
## THE LAST REVENGE - first-person survival horror in the Hollis house.
## Built only from the GLB files in the repository root + the PSX Anomaly kit house pieces.
## Goal: find the brass key, unlock the slaughter room, take the Devil's Bible, escape by the front door.
## The Butcher hunts by sight and sound. Run = loud, crouch = quiet, flashlight = visible.
## G (menu) opens the asset gallery with every character and environment.

const KIT := "res://PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/"
const CELL := 2.0
const MODELS := {
	"butcher": "res://horror_butcher_fat_killer_bloody_cleaver.glb",
	"ghost": "res://horror_ghost_character_-_blood_stained_spirit.glb",
	"woman": "res://horror_woman.glb",
	"girl": "res://a_horror_girl_character.glb",
	"rat": "res://street_rat.glb",
	"doll": "res://cursed_porcelain_doll_-_antique_horror_prop.glb",
	"flashlight": "res://horror_game_flashlight_download_game-ready.glb",
	"bible": "res://devils_bible_-_dark_fantasy_book.glb",
	"pig": "res://dead_pig.glb",
	"meat": "res://psx_raw_meat_pack__low-poly_2_types.glb",
	"bloodbag": "res://blood_bag.glb",
	"bloodwall": "res://abandoned_horror_wall_with_blood_splatter.glb",
	"clock": "res://vintage_wooden_wall_clock_-.glb",
	"fan": "res://old_rusty_ceiling_fan.glb",
	"bat": "res://baseball_bat_covered_in_blood.glb",
	"toilet": "res://old_wooden_toilet_house_2.glb",
}

# ---------------------------------------------------------------- floor plan
# Cell (i,j) is centred on world (2i, 2j); +x east, +z south.
const ROOMS := [
	{"id": "hall", "i": 1, "j": 3, "w": 13, "h": 1, "paper": "sprig"},
	{"id": "bed", "i": 1, "j": 1, "w": 4, "h": 2, "paper": "sprig"},
	{"id": "bath", "i": 5, "j": 1, "w": 2, "h": 2, "paper": "sprig"},
	{"id": "study", "i": 7, "j": 1, "w": 3, "h": 2, "paper": "sprig"},
	{"id": "kitchen", "i": 10, "j": 1, "w": 4, "h": 2, "paper": "sprig"},
	{"id": "living", "i": 1, "j": 4, "w": 5, "h": 3, "paper": "floral"},
	{"id": "foyer", "i": 6, "j": 4, "w": 3, "h": 3, "paper": "floral"},
	{"id": "dining", "i": 9, "j": 4, "w": 2, "h": 3, "paper": "floral"},
	{"id": "slaughter", "i": 11, "j": 4, "w": 3, "h": 3, "paper": "sprig"},
]
const DOORS := [
	{"i": 2, "j": 2, "s": "S", "k": "door", "n": "Bedroom door"},
	{"i": 5, "j": 2, "s": "S", "k": "door", "n": "Bathroom door"},
	{"i": 8, "j": 2, "s": "S", "k": "door", "n": "Study door"},
	{"i": 11, "j": 2, "s": "S", "k": "door", "n": "Kitchen door"},
	{"i": 3, "j": 4, "s": "N", "k": "door", "n": "Living room door"},
	{"i": 7, "j": 4, "s": "N", "k": "door", "n": "Foyer door"},
	{"i": 9, "j": 4, "s": "N", "k": "door", "n": "Dining room door"},
	{"i": 4, "j": 1, "s": "E", "k": "door", "n": "Bathroom door"},
	{"i": 6, "j": 2, "s": "E", "k": "door", "n": "Study door"},
	{"i": 9, "j": 1, "s": "E", "k": "door", "n": "Kitchen door"},
	{"i": 5, "j": 5, "s": "E", "k": "arch", "n": ""},
	{"i": 8, "j": 5, "s": "E", "k": "arch", "n": ""},
	{"i": 10, "j": 5, "s": "E", "k": "door", "lock": "slaughter", "n": "Slaughter room door"},
	{"i": 13, "j": 4, "s": "N", "k": "door", "lock": "slaughter", "n": "Slaughter room back door"},
	{"i": 7, "j": 6, "s": "S", "k": "door", "lock": "exit", "exit": true, "n": "Front door"},
]
const WINDOWS := [
	[2, 1, "N"], [4, 1, "N"], [1, 2, "W"], [5, 1, "N"], [8, 1, "N"], [11, 1, "N"], [13, 1, "N"],
	[1, 3, "W"], [13, 3, "E"], [2, 6, "S"], [4, 6, "S"], [10, 6, "S"], [12, 6, "S"], [13, 5, "E"],
]
# light fixtures: [i, j, power]  (power 0 = dead fixture)
const BULBS := [[3, 3, 1.0], [7, 3, 1.0], [11, 3, 1.0], [7, 5, 1.0], [11, 2, 0.9], [9, 5, 0.8], [2, 1, 0.0], [8, 1, 0.0], [3, 5, 0.0], [12, 5, 0.0]]
const SIDE := {
	"N": {"dx": 0, "dz": -1, "rot": 0.0, "axis": "x"},
	"S": {"dx": 0, "dz": 1, "rot": PI, "axis": "x"},
	"E": {"dx": 1, "dz": 0, "rot": -PI / 2.0, "axis": "z"},
	"W": {"dx": -1, "dz": 0, "rot": PI / 2.0, "axis": "z"},
}

class Door extends RefCounted:
	var pivot: Node3D
	var body: StaticBody3D
	var amount := 0.0
	var target := 0.0
	var dir := 1.0
	var speed := 2.6
	var locked := false
	var lock := ""
	var label := "Door"
	var pos := Vector3.ZERO
	var kind := "door"
	var exit := false
	var cx := 0.0
	var cz := 0.0
	var rot := 0.0
	func face_of(p: Vector3) -> float:
		return 1.0 if ((p.x - cx) * sin(rot) + (p.z - cz) * cos(rot)) >= 0.0 else -1.0
	func open_from(p: Vector3) -> void:
		if kind == "arch": return
		dir = face_of(p)
		target = 1.0
	func close() -> void:
		target = 0.0
	func update(dt: float) -> void:
		if kind == "arch": return
		var d := target - amount
		amount += signf(d) * minf(absf(d), speed * dt)
		pivot.rotation.y = amount * dir * 1.52
		body.collision_layer = 1 if amount < 0.4 else 0

# ------------------------------------------------------------------- state
static var autostart := false
var kit_cache := {}
var missing: Array = []
var room_of := {}
var edges := {}
var cells := {}
var nav := {}
var doors: Array = []
var bulbs: Array = []
var interact: Array = []
var level_root: Node3D
var player: CharacterBody3D
var cam: Camera3D
var flash: SpotLight3D
var butcher: CharacterBody3D
var state := "menu"
var yaw := 0.0
var pitch := 0.0
var stamina := 1.0
var battery := 1.0
var flash_on := false
var has_key := false
var has_bible := false
var batteries := 0
var step_t := 0.0
var noise_cd := 0.0
var time := 0.0
var shake := 0.0
var rng := RandomNumberGenerator.new()
# butcher AI
var b_state := "patrol"
var b_path: Array = []
var b_target := Vector3.ZERO
var b_last_seen := Vector3.ZERO
var b_wait := 0.0
var b_lose := 0.0
var b_stuck := 0.0
var b_prev := Vector3.ZERO
var b_model: Node3D
var b_step := 0.0
var enraged := false
# apparitions
var girl: Node3D
var doll: Node3D
var ghost: Node3D
var woman: Node3D
var rat: Node3D
var rat_t := 5.0
var woman_t := 25.0
var woman_life := 0.0
var scare_t := 18.0
var fan: Node3D
# ui
var hud_obj: Label
var hud_prompt: Label
var hud_msg: Label
var hud_warn: Label
var bar_stam: ProgressBar
var bar_batt: ProgressBar
var overlay: ColorRect
var overlay_label: Label
var post_mat: ShaderMaterial
var msg_t := 0.0
# audio
var snd := {}
var p_heart: AudioStreamPlayer
var p_sfx: AudioStreamPlayer
var p_amb: AudioStreamPlayer
var p_butcher: AudioStreamPlayer3D
var heart_t := 0.0
var threat := 0.0

func _ready() -> void:
	rng.randomize()
	_build_environment()
	level_root = Node3D.new()
	add_child(level_root)
	_build_level()
	_build_nav()
	_build_furniture()
	_build_player()
	_build_dressing()
	_build_characters()
	_build_items()
	_build_audio()
	_build_hud()
	_reset_run()
	_show_overlay("THE LAST REVENGE\n\nENTER  start the hunt\nG  asset gallery (all characters + environments)\n\nWASD move   SHIFT run   C crouch   F flashlight   E interact   ESC pause\nFind the brass key. Unlock the slaughter room. Take the Devil's Bible. Escape.\nThe Butcher hears footsteps and sees light.")
	if autostart:
		autostart = false
		_start()
	if missing.size() > 0:
		hud_warn.text = "%d model(s) are Git LFS stubs - run `git lfs pull` and reopen the project." % missing.size()

# ---------------------------------------------------------------- helpers
func _kit(name: String) -> PackedScene:
	if not kit_cache.has(name):
		kit_cache[name] = load(KIT + name + ".glb")
	return kit_cache[name]

func piece(name: String, pos: Vector3, rot := 0.0) -> Node3D:
	var ps: PackedScene = _kit(name)
	var n: Node3D
	if ps == null:
		if not missing.has(name): missing.append(name)
		n = Node3D.new()
	else:
		n = ps.instantiate()
	n.position = pos
	n.rotation.y = rot
	level_root.add_child(n)
	return n

func add_box(center: Vector3, size: Vector3, layer := 1, parent: Node = null) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = center
	b.collision_layer = layer
	b.collision_mask = 0
	(parent if parent != null else level_root).add_child(b)
	return b

func _aabb(n: Node, xf: Transform3D) -> AABB:
	var res := AABB()
	var has := false
	var t := xf
	if n is Node3D: t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		res = t * (n as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in n.get_children():
		var a := _aabb(c, t)
		if a.size != Vector3.ZERO:
			res = a if not has else res.merge(a)
			has = true
	return res

## Load a root-folder GLB, scale it to `height` (or longest side `length`), stand it on y=0, centre it on x/z.
func fit(key_or_path: String, height := 0.0, length := 0.0, face_x := false) -> Node3D:
	var path: String = MODELS.get(key_or_path, key_or_path)
	var holder := Node3D.new()
	var ps = null
	if ResourceLoader.exists(path): ps = load(path)
	if ps == null:
		missing.append(path.get_file())
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.4, height if height > 0.0 else 0.4, 0.4)
		mi.mesh = bm
		mi.position.y = bm.size.y / 2.0
		holder.add_child(mi)
		return holder
	var inst: Node3D = ps.instantiate()
	var rot := Node3D.new()
	holder.add_child(rot)
	rot.add_child(inst)
	var bb := _aabb(inst, Transform3D.IDENTITY)
	var k := 1.0
	if height > 0.0 and bb.size.y > 0.0: k = height / bb.size.y
	elif length > 0.0:
		var m := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
		if m > 0.0: k = length / m
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-(bb.position.x + bb.size.x / 2.0) * k, -bb.position.y * k, -(bb.position.z + bb.size.z / 2.0) * k)
	if face_x: rot.rotation.y = -PI / 2.0
	holder.set_meta("size", bb.size * k)
	return holder

func _mat(color: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

func block(x: float, z: float, w: float, d: float, h: float, color: Color, y := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, d)
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = Vector3(x, y + h / 2.0, z)
	add_child(mi)
	add_box(Vector3(x, y + h / 2.0, z), Vector3(w, h, d), 1, self)

func cell_center(i: int, j: int) -> Vector3:
	return Vector3(i * CELL, 0.0, j * CELL)

func _ek(i: int, j: int, s: String) -> String:
	match s:
		"E": return "E%d,%d" % [i, j]
		"W": return "E%d,%d" % [i - 1, j]
		"S": return "S%d,%d" % [i, j]
	return "S%d,%d" % [i, j - 1]

# ------------------------------------------------------------ environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.13, 0.15, 0.22)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.055, 0.07)
	env.fog_density = 0.035
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.03
	env.volumetric_fog_albedo = Color(0.75, 0.78, 0.85)
	env.volumetric_fog_length = 24.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.85
	env.adjustment_contrast = 1.08
	we.environment = env
	add_child(we)
	# moonlight through the windows (soft, no shadows)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.45, 0.55, 0.9)
	moon.light_energy = 0.08
	moon.rotation_degrees = Vector3(-55, 30, 0)
	moon.shadow_enabled = false
	add_child(moon)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	ground.mesh = pm
	ground.material_override = _mat(Color(0.03, 0.045, 0.03), 1.0)
	ground.position = Vector3(14, -0.04, 8)
	add_child(ground)
	add_box(Vector3(14, -0.55, 8), Vector3(260, 1, 260), 1, self)

# ------------------------------------------------------------------ level
func _build_level() -> void:
	for r in ROOMS:
		for i in range(r.i, r.i + r.w):
			for j in range(r.j, r.j + r.h):
				room_of["%d,%d" % [i, j]] = r
				cells["%d,%d" % [i, j]] = Vector2i(i, j)
	var edge_defs := {}
	for d in DOORS: edge_defs[_ek(d.i, d.j, d.s)] = {"type": d.k, "def": d}
	for w in WINDOWS: edge_defs[_ek(w[0], w[1], w[2])] = {"type": "window", "def": null}
	for r in ROOMS:
		for i in range(r.i, r.i + r.w):
			for j in range(r.j, r.j + r.h):
				for s in ["N", "E", "S", "W"]:
					var k := _ek(i, j, s)
					if edges.has(k): continue
					var sd = SIDE[s]
					var nr = room_of.get("%d,%d" % [i + sd.dx, j + sd.dz], null)
					if nr == r: continue
					var c := cell_center(i, j)
					var e := {"key": k, "i": i, "j": j, "room": r, "rot": sd.rot, "axis": sd.axis,
						"ox": c.x, "oz": c.z, "cx": c.x + sd.dx * CELL / 2.0, "cz": c.z + sd.dz * CELL / 2.0, "type": "wall", "def": null, "door": null}
					if edge_defs.has(k):
						e.type = edge_defs[k].type
						e.def = edge_defs[k].def
					edges[k] = e
	for e in edges.values():
		var origin := Vector3(e.ox, 0, e.oz)
		var paper := "house_wall_floral" if e.room.paper == "floral" else "house_wall"
		var along := Vector3(1, 0, 0) if e.axis == "x" else Vector3(0, 0, 1)
		var cp := Vector3(e.cx, 1.5, e.cz)
		if e.type == "wall" or e.type == "window":
			if e.type == "window":
				piece("house_wall_window", origin, e.rot)
				piece("house_window", origin, e.rot)
			else:
				piece(paper, origin, e.rot)
			add_box(cp, Vector3(2.26, 3, 0.26) if e.axis == "x" else Vector3(0.26, 3, 2.26))
		else:
			piece("house_wall_door", origin, e.rot)
			for sgn in [-1.0, 1.0]:
				var pc: Vector3 = cp + along * sgn * 0.815
				add_box(pc, Vector3(0.63, 3, 0.26) if e.axis == "x" else Vector3(0.26, 3, 0.63))
			add_box(cp + Vector3(0, 2.65, 0), Vector3(1.0, 0.7, 0.26) if e.axis == "x" else Vector3(0.26, 0.7, 1.0))
			if e.type == "door":
				var d := Door.new()
				d.kind = "door"
				d.label = e.def.n
				d.lock = e.def.get("lock", "")
				d.locked = d.lock != ""
				d.exit = e.def.get("exit", false)
				d.cx = e.cx; d.cz = e.cz; d.rot = e.rot
				d.pos = Vector3(e.cx, 1.0, e.cz)
				var frame := Node3D.new()
				frame.position = origin
				frame.rotation.y = e.rot
				level_root.add_child(frame)
				var pivot := Node3D.new()
				pivot.position = Vector3(-0.48, 0, -1)
				frame.add_child(pivot)
				var leaf: Node3D = _kit("house_door").instantiate() if _kit("house_door") != null else Node3D.new()
				leaf.position = Vector3(0.48, 0, 1)
				pivot.add_child(leaf)
				d.pivot = pivot
				d.body = add_box(Vector3(e.cx, 1.1, e.cz), Vector3(1.0, 2.2, 0.14) if e.axis == "x" else Vector3(0.14, 2.2, 1.0))
				e.door = d
				doors.append(d)
				interact.append({"kind": "door", "door": d})
	# corner posts
	for a in range(0, 16):
		for b in range(0, 9):
			var N := edges.has("E%d,%d" % [a - 1, b - 1])
			var S := edges.has("E%d,%d" % [a - 1, b])
			var W := edges.has("S%d,%d" % [a - 1, b - 1])
			var E := edges.has("S%d,%d" % [a, b - 1])
			var n := int(N) + int(S) + int(W) + int(E)
			if n < 2 or (n == 2 and ((N and S) or (W and E))): continue
			piece("house_corner", Vector3((a - 1) * CELL, 0, b * CELL))
	# floors, ceilings, fixtures
	var bulb_at := {}
	for b in BULBS: bulb_at["%d,%d" % [b[0], b[1]]] = b[2]
	for key in cells:
		var c: Vector2i = cells[key]
		var p := cell_center(c.x, c.y)
		piece("house_floor", p)
		if bulb_at.has(key):
			piece("house_ceiling_light", p)
			if bulb_at[key] > 0.0:
				var l := OmniLight3D.new()
				l.position = Vector3(p.x, 2.5, p.z)
				l.light_color = Color(1.0, 0.78, 0.5)
				l.omni_range = 9.0
				l.light_energy = 1.7 * bulb_at[key]
				l.shadow_enabled = false
				level_root.add_child(l)
				bulbs.append({"light": l, "base": l.light_energy, "mode": "on", "t": 0.0, "pos": p})
		else:
			piece("house_ceiling", p)

func _build_nav() -> void:
	for key in cells: nav[key] = []
	for key in cells:
		var c: Vector2i = cells[key]
		for s in ["N", "E", "S", "W"]:
			var sd = SIDE[s]
			var nk := "%d,%d" % [c.x + sd.dx, c.y + sd.dz]
			if not cells.has(nk): continue
			if room_of[nk] == room_of[key]:
				nav[key].append({"to": nk, "door": null})
			else:
				var e = edges.get(_ek(c.x, c.y, s), null)
				if e != null and (e.type == "door" or e.type == "arch"):
					nav[key].append({"to": nk, "door": e.door})

func nav_path(from_k: String, to_k: String) -> Array:
	if from_k == to_k: return [from_k]
	var prev := {from_k: ""}
	var queue := [from_k]
	while queue.size() > 0:
		var cur: String = queue.pop_front()
		if cur == to_k: break
		for nb in nav[cur]:
			if prev.has(nb.to): continue
			prev[nb.to] = cur
			queue.append(nb.to)
	if not prev.has(to_k): return []
	var out := [to_k]
	while out[0] != from_k: out.push_front(prev[out[0]])
	return out

func cell_key_at(p: Vector3) -> String:
	return "%d,%d" % [roundi(p.x / CELL), roundi(p.z / CELL)]

func door_between(a_k: String, b_k: String):
	for nb in nav[a_k]:
		if nb.to == b_k: return nb.door
	return null

func _build_furniture() -> void:
	var wood := Color(0.2, 0.13, 0.08)
	block(6.0, 2.5, 1.5, 2.1, 0.5, Color(0.35, 0.34, 0.3))       # bed
	block(2.2, 1.65, 1.5, 0.8, 2.0, Color(0.12, 0.08, 0.06))     # wardrobe
	block(1.75, 4.6, 1.1, 0.45, 0.8, wood)                         # dresser
	block(11.5, 1.65, 1.7, 0.8, 0.6, Color(0.55, 0.55, 0.52))     # tub
	block(16.0, 1.75, 1.8, 0.8, 0.78, wood)                        # desk
	block(13.75, 2.2, 0.35, 1.2, 2.0, Color(0.1, 0.07, 0.05))     # bookcases
	block(18.85, 2.2, 0.35, 1.2, 2.0, Color(0.1, 0.07, 0.05))
	block(23.4, 1.55, 5.0, 0.65, 0.9, wood)                        # kitchen counter
	block(22.0, 4.4, 0.9, 1.4, 0.9, Color(0.4, 0.42, 0.42))       # island
	block(5.2, 8.0, 2.2, 0.9, 0.5, Color(0.33, 0.12, 0.13))       # couch
	block(19.0, 10.0, 1.0, 2.5, 0.75, wood)                        # dining table
	block(24.0, 10.0, 1.6, 0.9, 0.9, Color(0.45, 0.46, 0.47))     # altar / butcher block
	block(24.0, 12.5, 2.4, 0.7, 0.9, Color(0.45, 0.46, 0.47))
	block(14.0, 7.55, 1.4, 0.45, 0.8, wood)                        # foyer table

func _build_dressing() -> void:
	for p in [[22.6, 8.0], [25.6, 11.8], [22.4, 11.0]]:
		var pig := fit("pig", 1.25)
		pig.position = Vector3(p[0], 3.0 - 1.55, p[1])
		add_child(pig)
	var m := fit("meat", 0, 0.7); m.position = Vector3(24.2, 0.9, 12.5); add_child(m)
	var bb := fit("bloodbag", 0, 0.32); bb.position = Vector3(24.8, 0.9, 10.1); add_child(bb)
	var bw := fit("bloodwall", 0, 5.2); bw.position = Vector3(24, 0, 7.2); add_child(bw)
	var clk := fit("clock", 0, 0.55); clk.position = Vector3(1.17, 1.8, 9.6); clk.rotation.y = PI / 2.0; add_child(clk)
	fan = fit("fan", 0, 1.3)
	fan.position = Vector3(23.0, 3.0 - (fan.get_meta("size", Vector3(0, 0.6, 0)) as Vector3).y, 3.0)
	add_child(fan)
	var toilet := fit("toilet", 2.3); toilet.position = Vector3(-4.5, 0, 6.0); toilet.rotation.y = PI / 2.0; add_child(toilet)
	var bat := fit("bat", 0, 0.85); bat.position = Vector3(8.0, 0.05, 12.3); bat.rotation.z = 0.0; add_child(bat)

func _build_characters() -> void:
	# Butcher: patrols, hears you, sees your light. Static mesh, animated by code (stride bob, lean, sway).
	butcher = CharacterBody3D.new()
	butcher.collision_layer = 4
	butcher.collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	butcher.add_child(cs)
	b_model = fit("butcher", 1.95, 0, true)
	butcher.add_child(b_model)
	butcher.position = Vector3(24.0, 0.05, 8.6)
	add_child(butcher)
	p_butcher = AudioStreamPlayer3D.new()
	p_butcher.unit_size = 3.0
	p_butcher.max_distance = 30.0
	butcher.add_child(p_butcher)
	var carry := OmniLight3D.new()
	carry.light_color = Color(1.0, 0.25, 0.15)
	carry.light_energy = 0.0
	carry.omni_range = 3.0
	carry.position.y = 1.6
	butcher.add_child(carry)
	butcher.set_meta("eye_light", carry)
	# Girl: weeping-angel rule - she only moves while you are not looking at her.
	girl = fit("girl", 1.68)
	girl.position = Vector3(3.2, 0, 3.9)
	add_child(girl)
	# Doll: on the dresser, turns to watch you.
	doll = fit("doll", 0.55)
	doll.position = Vector3(1.75, 0.8, 4.6)
	add_child(doll)
	# Ghost: drifts through the dining room.
	ghost = fit("ghost", 1.7, 0, true)
	ghost.position = Vector3(19.0, 0.35, 8.0)
	add_child(ghost)
	# Woman: appears at the end of the hall, vanishes when approached.
	woman = fit("woman", 1.7)
	woman.visible = false
	add_child(woman)
	# Rat: scurries along the skirting boards.
	rat = fit("rat", 0, 0.45, true)
	rat.visible = false
	add_child(rat)

func _build_items() -> void:
	var key_spots := [Vector3(7.4, 0.58, 1.55), Vector3(16.2, 0.8, 1.7), Vector3(23.2, 0.92, 1.5)]
	_add_pickup("key", key_spots[rng.randi() % key_spots.size()], "Take the brass key")
	var bspots := [Vector3(4.6, 0.6, 1.55), Vector3(11.3, 0.66, 1.65), Vector3(14.0, 0.84, 7.5), Vector3(5.2, 0.44, 9.4), Vector3(22.0, 0.94, 4.4), Vector3(19.0, 0.78, 10.0), Vector3(27.0, 0.05, 12.4), Vector3(17.6, 0.05, 4.7)]
	bspots.shuffle()
	for i in 5: _add_pickup("battery", bspots[i], "Take the battery")
	var bible := fit("bible", 0.34)
	bible.position = Vector3(24.0, 0.93, 10.0)
	bible.rotation.x = 0.0
	add_child(bible)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.1, 0.05)
	glow.light_energy = 2.0
	glow.omni_range = 5.0
	glow.position = Vector3(24.0, 1.4, 10.0)
	add_child(glow)
	interact.append({"kind": "bible", "node": bible, "pos": Vector3(24.0, 1.1, 10.0), "label": "Take the Devil's Bible", "glow": glow})

func _add_pickup(kind: String, pos: Vector3, label: String) -> void:
	var mi := MeshInstance3D.new()
	if kind == "key":
		var tm := TorusMesh.new()
		tm.inner_radius = 0.035
		tm.outer_radius = 0.06
		mi.mesh = tm
		mi.material_override = _mat(Color(0.85, 0.65, 0.2), 0.3, 0.9)
	else:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.03
		cm.height = 0.16
		mi.mesh = cm
		var bm := _mat(Color(0.1, 0.1, 0.1), 0.4, 0.5)
		bm.emission_enabled = true
		bm.emission = Color(0.1, 1.0, 0.4)
		bm.emission_energy_multiplier = 1.2
		mi.material_override = bm
	mi.position = pos
	add_child(mi)
	interact.append({"kind": kind, "node": mi, "pos": pos, "label": label})

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.collision_layer = 2
	player.collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	player.add_child(cs)
	add_child(player)
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	cam.far = 120
	cam.position.y = 1.62
	player.add_child(cam)
	flash = SpotLight3D.new()
	flash.light_color = Color(1.0, 0.94, 0.82)
	flash.light_energy = 6.0
	flash.spot_range = 28.0
	flash.spot_angle = 30.0
	flash.spot_angle_attenuation = 0.6
	flash.shadow_enabled = true
	flash.light_volumetric_fog_energy = 1.4
	flash.position = Vector3(0.16, -0.12, -0.1)
	flash.visible = false
	cam.add_child(flash)
	var fl := fit("flashlight", 0, 0.27, true)
	fl.position = Vector3(0.19, -0.2, -0.34)
	fl.rotation.y = PI
	cam.add_child(fl)
	for m in fl.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ------------------------------------------------------------------ audio
func _wav(fn: Callable, secs: float, loop := false) -> AudioStreamWAV:
	var rate := 22050
	var n := int(secs * rate)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var s: float = clampf(fn.call(float(i) / rate, secs), -1.0, 1.0)
		bytes.encode_s16(i * 2, int(s * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w

func _build_audio() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	snd["heart"] = _wav(func(t, _d): return (sin(TAU * 58.0 * t) * exp(-t * 18.0) + sin(TAU * 52.0 * (t - 0.17)) * exp(-(t - 0.17) * 18.0) * (1.0 if t > 0.17 else 0.0)) * 0.9, 0.5)
	snd["step"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * 0.5 + sin(TAU * 90.0 * t)) * exp(-t * 26.0) * 0.8, 0.22)
	snd["bstep"] = _wav(func(t, _d): return (sin(TAU * 55.0 * t * exp(-t * 3.0)) + r.randf_range(-1, 1) * 0.3) * exp(-t * 9.0), 0.45)
	snd["stinger"] = _wav(func(t, d): return (sin(TAU * 110.0 * t) + sin(TAU * 116.5 * t) + sin(TAU * 185.0 * t) * 0.7 + r.randf_range(-1, 1) * 0.4) * exp(-t * 2.0) * 0.35, 1.8)
	snd["door"] = _wav(func(t, d): return sin(TAU * (150.0 + 90.0 * sin(t * 3.0)) * t) * sin(PI * t / d) * 0.35 + r.randf_range(-1, 1) * 0.05, 0.8)
	snd["click"] = _wav(func(t, _d): return r.randf_range(-1, 1) * exp(-t * 120.0), 0.06)
	snd["drone"] = _wav(func(t, _d): return (sin(TAU * 41.0 * t) + sin(TAU * 41.5 * t) + sin(TAU * 61.5 * t) * 0.5 + r.randf_range(-1, 1) * 0.05) * 0.2, 4.0, true)
	p_heart = AudioStreamPlayer.new(); p_heart.stream = snd["heart"]; add_child(p_heart)
	p_sfx = AudioStreamPlayer.new(); add_child(p_sfx)
	p_amb = AudioStreamPlayer.new(); p_amb.stream = snd["drone"]; p_amb.volume_db = -10.0; add_child(p_amb)

func play(name: String, vol := 0.0) -> void:
	if not snd.has(name): return
	var p := AudioStreamPlayer.new()
	p.stream = snd[name]
	p.volume_db = vol
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

# --------------------------------------------------------------------- HUD
func _label(text: String, pos: Vector2, size := 18, color := Color(0.85, 0.85, 0.8)) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _build_hud() -> void:
	var post := CanvasLayer.new()
	post.layer = 5
	add_child(post)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://horror/post.gdshader")
	rect.material = post_mat
	post.add_child(rect)
	var hud := CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	hud_obj = _label("", Vector2(24, 20), 20)
	hud_prompt = _label("", Vector2(0, 0), 22, Color(1, 1, 1))
	hud_prompt.set_anchors_preset(Control.PRESET_CENTER)
	hud_prompt.position = Vector2(-160, 60)
	hud_msg = _label("", Vector2(0, 0), 20, Color(0.9, 0.85, 0.6))
	hud_msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud_msg.position = Vector2(-380, -130)
	hud_warn = _label("", Vector2(24, 690), 14, Color(1, 0.5, 0.3))
	bar_stam = ProgressBar.new(); bar_stam.max_value = 1.0; bar_stam.show_percentage = false
	bar_stam.position = Vector2(24, 640); bar_stam.size = Vector2(180, 8)
	bar_batt = ProgressBar.new(); bar_batt.max_value = 1.0; bar_batt.show_percentage = false
	bar_batt.position = Vector2(24, 660); bar_batt.size = Vector2(180, 8)
	for n in [hud_obj, hud_prompt, hud_msg, hud_warn, bar_stam, bar_batt]: hud.add_child(n)
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.5)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -2)
	hud.add_child(dot)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label = _label("", Vector2(0, 0), 26, Color(0.9, 0.85, 0.8))
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.add_child(overlay_label)
	hud.add_child(overlay)

func _show_overlay(text: String) -> void:
	overlay_label.text = text
	overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func say(text: String, secs := 5.0) -> void:
	hud_msg.text = text
	msg_t = secs

func objective() -> String:
	if not has_key: return "Find the brass key"
	if not has_bible: return "Unlock the slaughter room and take the Devil's Bible"
	return "ESCAPE - the front door is open"

# ------------------------------------------------------------------- run
func _reset_run() -> void:
	player.position = Vector3(5.0, 0.05, 3.9)
	player.velocity = Vector3.ZERO
	yaw = PI
	pitch = 0.0
	stamina = 1.0
	battery = 1.0
	flash_on = false
	flash.visible = false
	has_key = false
	has_bible = false
	batteries = 0
	enraged = false
	b_state = "patrol"
	b_path = []
	butcher.position = Vector3(24.0, 0.05, 8.6)
	b_wait = 20.0
	for d in doors:
		d.target = 0.0
		d.amount = 0.0
		d.locked = d.lock != ""
	post_mat.set_shader_parameter("flash", 0.0)
	post_mat.set_shader_parameter("desat", 0.0)

func _start() -> void:
	overlay.visible = false
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	p_amb.play()
	say("The radio crackles: \"Key first. Don't let him hear you.\"", 7.0)

func _die() -> void:
	state = "dead"
	play("stinger")
	post_mat.set_shader_parameter("flash", 0.85)
	_show_overlay("YOU DIED\n\nThe Butcher found you.\n\nENTER  try again     G  gallery")

func _win() -> void:
	state = "won"
	_show_overlay("YOU ESCAPED\n\nThe Devil's Bible burns behind you.\n\nENTER  play again     G  gallery")

func noise(pos: Vector3, radius: float) -> void:
	if state != "play": return
	var d := butcher.position.distance_to(pos)
	if not _los(butcher.position + Vector3(0, 1.5, 0), pos + Vector3(0, 1.2, 0)): radius *= 0.6
	if d < radius and b_state != "chase":
		b_state = "investigate"
		b_target = pos
		b_path = []
		b_wait = 0.0

func _los(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# ------------------------------------------------------------------ input
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and state == "play":
		yaw -= event.relative.x * 0.0022
		pitch = clampf(pitch - event.relative.y * 0.0022, -1.45, 1.45)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER:
				if state == "menu": _start()
				elif state == "dead" or state == "won":
					autostart = true
					get_tree().reload_current_scene()
			KEY_G:
				if state != "play": get_tree().change_scene_to_file("res://horror/gallery.tscn")
			KEY_ESCAPE:
				if state == "play":
					state = "pause"
					_show_overlay("PAUSED\n\nENTER  resume     G  gallery")
				elif state == "pause": state = "play"; overlay.visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			KEY_F:
				if state == "play": _toggle_flash()
			KEY_E:
				if state == "play": _interact()
	if event is InputEventKey and event.pressed and (event.physical_keycode == KEY_ENTER) and state == "pause":
		state = "play"; overlay.visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_flash() -> void:
	if not flash_on and battery <= 0.0:
		play("click", -12.0)
		return
	flash_on = not flash_on
	flash.visible = flash_on
	play("click")

func _find_focus():
	var f := -cam.global_transform.basis.z
	var best = null
	var best_score := 1e9
	for it in interact:
		var pos: Vector3
		if it.kind == "door": pos = it.door.pos
		else:
			if it.get("taken", false): continue
			pos = it.pos
		var to := pos - cam.global_position
		var d := to.length()
		if d > 2.3: continue
		var cs := f.dot(to / d)
		if cs < 0.86: continue
		var score := d * 0.6 + (1.0 - cs) * 6.0
		if score < best_score:
			best_score = score
			best = it
	return best

func _interact() -> void:
	var it = _find_focus()
	if it == null: return
	match it.kind:
		"door":
			var d: Door = it.door
			if d.locked:
				if d.lock == "slaughter" and has_key:
					d.locked = false
					for o in doors: if o.lock == "slaughter": o.locked = false
					say("The key turns. Something moves on the other side.")
					play("click")
				elif d.lock == "exit" and has_bible:
					d.locked = false
				else:
					say("Locked." if d.lock != "exit" else "The front door will not budge. Not yet.")
					play("click", -6.0)
					return
			if d.exit and not d.locked:
				_win()
				return
			if d.target > 0.0: d.close()
			else: d.open_from(player.position)
			play("door")
			noise(d.pos, 6.0)
		"key":
			has_key = true
			it.taken = true
			(it.node as Node3D).visible = false
			say("Brass key. It smells of old iron.")
			play("click")
		"battery":
			it.taken = true
			(it.node as Node3D).visible = false
			battery = minf(1.0, battery + 0.5)
			batteries += 1
			say("Battery +50%")
			play("click")
		"bible":
			it.taken = true
			(it.node as Node3D).visible = false
			(it.glow as OmniLight3D).visible = false
			has_bible = true
			enraged = true
			for d in doors: if d.lock == "exit": d.locked = false
			for b in bulbs: b.mode = "flicker"
			play("stinger")
			b_state = "chase"
			b_last_seen = player.position
			say("The Butcher screams. RUN to the front door!", 8.0)

# -------------------------------------------------------------- main loop
func _physics_process(dt: float) -> void:
	time += dt
	if fan != null: fan.rotation.y += dt * 1.1
	for d in doors: d.update(dt)
	_update_lights(dt)
	if state != "play":
		_animate_idle(dt)
		return
	_update_player(dt)
	_update_butcher(dt)
	_update_characters(dt)
	_update_director(dt)
	_update_ui(dt)

func _update_lights(dt: float) -> void:
	for b in bulbs:
		var k := 1.0
		b.t -= dt
		match b.mode:
			"flicker":
				if b.t <= 0.0:
					b.t = 0.03 + rng.randf() * 0.12
					b.k = 0.9 if rng.randf() > 0.45 else 0.05
				k = b.get("k", 1.0)
			"off": k = 0.0
			_: k = 0.96 + sin(time * 9.0 + b.pos.x * 3.0) * 0.03
		(b.light as OmniLight3D).light_energy = b.base * k

func _animate_idle(dt: float) -> void:
	if ghost != null: ghost.position.y = 0.35 + sin(time * 1.3) * 0.08
	if b_model != null: b_model.rotation.z = sin(time * 0.8) * 0.02

func _update_player(dt: float) -> void:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var mv := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): mv.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): mv.y -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): mv.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): mv.x -= 1
	var crouch := Input.is_physical_key_pressed(KEY_C) or Input.is_physical_key_pressed(KEY_CTRL)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and mv.y > 0.0 and stamina > 0.0 and not crouch
	if sprint: stamina = maxf(0.0, stamina - 0.2 * dt)
	else: stamina = minf(1.0, stamina + 0.13 * dt)
	var speed := 4.3 if sprint else (1.15 if crouch else 2.2)
	var wish := (fwd * mv.y + right * mv.x)
	if wish.length() > 0.0: wish = wish.normalized() * speed
	player.velocity.x = lerpf(player.velocity.x, wish.x, minf(1.0, 12.0 * dt))
	player.velocity.z = lerpf(player.velocity.z, wish.z, minf(1.0, 12.0 * dt))
	player.velocity.y = -2.0
	player.move_and_slide()
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.4
	if moving:
		step_t += Vector2(player.velocity.x, player.velocity.z).length() * dt
		if step_t > (1.9 if sprint else (1.1 if crouch else 1.45)):
			step_t = 0.0
			play("step", -4.0 if sprint else (-18.0 if crouch else -10.0))
		noise_cd -= dt
		if noise_cd <= 0.0:
			noise_cd = 0.3
			noise(player.position, 11.0 if sprint else (1.8 if crouch else 5.2))
	if flash_on:
		battery = maxf(0.0, battery - 0.0042 * dt)
		if battery <= 0.0:
			flash_on = false; flash.visible = false
		elif battery < 0.2:
			flash.light_energy = 6.0 * (1.0 if rng.randf() > 0.25 else 0.1)
		else: flash.light_energy = 6.0
	var eye := 1.0 if crouch else 1.62
	cam.position.y = lerpf(cam.position.y, eye + sin(time * 9.0) * 0.02 * float(moving), minf(1.0, 9.0 * dt))
	shake = maxf(0.0, shake - dt * 1.6)
	cam.rotation = Vector3(pitch + (rng.randf() - 0.5) * shake * 0.03, yaw, sin(time * 5.0) * 0.003 * float(moving))
	player.rotation = Vector3.ZERO

func _update_ui(dt: float) -> void:
	hud_obj.text = "%s\nBatteries found: %d    Key: %s" % [objective(), batteries, "yes" if has_key else "no"]
	bar_stam.value = stamina
	bar_batt.value = battery
	var f = _find_focus()
	if f == null: hud_prompt.text = ""
	elif f.kind == "door":
		var d: Door = f.door
		hud_prompt.text = "[E] %s %s%s" % ["Close" if d.target > 0.0 else "Open", d.label, "  (locked)" if d.locked else ""]
	else: hud_prompt.text = "[E] " + f.label
	if msg_t > 0.0:
		msg_t -= dt
		if msg_t <= 0.0: hud_msg.text = ""
	# fear: heartbeat + colour drain scale with the Butcher's proximity
	var d := butcher.position.distance_to(player.position)
	var t := clampf(1.0 - d / 14.0, 0.0, 1.0) if b_state != "patrol" or d < 9.0 else 0.0
	threat = lerpf(threat, t, minf(1.0, 3.0 * dt))
	post_mat.set_shader_parameter("desat", threat * 0.7)
	post_mat.set_shader_parameter("vignette", 1.0 + threat * 0.5)
	post_mat.set_shader_parameter("aberration", 0.0025 + threat * 0.006)
	post_mat.set_shader_parameter("flash", maxf(0.0, (post_mat.get_shader_parameter("flash") as float) - dt * 1.6))
	if threat > 0.12:
		heart_t -= dt
		if heart_t <= 0.0:
			heart_t = 1.0 / (1.0 + threat * 1.9)
			p_heart.volume_db = -14.0 + threat * 12.0
			p_heart.play()

# ------------------------------------------------------------ the Butcher
func _can_see_player() -> bool:
	var to := player.position - butcher.position
	var d := to.length()
	var lit := flash_on or _room_lit(player.position)
	var sight := 14.0 if lit else 4.5
	if enraged: sight += 6.0
	if d > sight: return false
	var facing := Vector3(sin(b_model_yaw()), 0, cos(b_model_yaw()))
	if d > 2.0 and facing.dot(to.normalized()) < cos(PI * 0.31): return false
	return _los(butcher.position + Vector3(0, 1.6, 0), player.position + Vector3(0, 1.4, 0))

func b_model_yaw() -> float:
	return butcher.rotation.y

func _room_lit(p: Vector3) -> bool:
	for b in bulbs:
		if (b.pos as Vector3).distance_to(p) < 6.5 and b.mode != "off" and b.base > 0.0: return true
	return false

func _update_butcher(dt: float) -> void:
	var seen := _can_see_player()
	if seen:
		if b_state != "chase": play("stinger", -8.0)
		b_state = "chase"
		b_last_seen = player.position
		b_lose = 0.0
	elif b_state == "chase":
		b_lose += dt
		if b_lose > 3.5:
			b_state = "search"
			b_target = b_last_seen
			b_path = []
			b_wait = 4.0
	var speed := 0.0
	match b_state:
		"patrol":
			if b_wait > 0.0: b_wait -= dt
			else:
				if b_path.size() == 0: _pick_patrol()
				speed = 1.35
		"investigate":
			speed = 1.9
			if butcher.position.distance_to(b_target) < 1.4:
				b_state = "search"; b_wait = 3.5
		"search":
			if b_wait > 0.0: b_wait -= dt
			else: b_state = "patrol"; b_path = []; b_wait = 1.0
		"chase":
			b_target = b_last_seen
			speed = 3.9 if enraged else 3.35
	if speed > 0.0: _walk_to(b_target, speed, dt)
	else: butcher.velocity = Vector3.ZERO
	# kill
	if butcher.position.distance_to(player.position) < 0.95 and state == "play":
		_die()
	# presentation: stride bob, lean, blood-red eyes while chasing
	var moving := speed > 0.0
	b_step += dt * speed * 2.0
	b_model.position.y = absf(sin(b_step)) * 0.05 * float(moving)
	b_model.rotation.z = sin(b_step) * 0.05 * float(moving)
	b_model.rotation.x = 0.12 * float(b_state == "chase")
	var carry: OmniLight3D = butcher.get_meta("eye_light")
	carry.light_energy = 1.2 if b_state == "chase" else 0.0
	if moving and sin(b_step) > 0.98 and b_step - floorf(b_step) < 0.5:
		p_butcher.stream = snd["bstep"]
		if not p_butcher.playing: p_butcher.play()
	p_butcher.volume_db = 4.0

func _pick_patrol() -> void:
	var keys := cells.keys()
	var pk: String = player_cell_bias(keys)
	b_path = nav_path(cell_key_at(butcher.position), pk)
	if b_path.size() > 1: b_path.pop_front()

func player_cell_bias(keys: Array) -> String:
	if rng.randf() < 0.4:
		return cell_key_at(player.position)
	var k: String = keys[rng.randi() % keys.size()]
	return k

func _walk_to(target: Vector3, speed: float, dt: float) -> void:
	var goal := target
	if b_state == "chase" or b_state == "investigate" or b_path.size() == 0:
		# follow the cell graph towards the target so doors get used
		var from_k := cell_key_at(butcher.position)
		var to_k := cell_key_at(target)
		if from_k != to_k and (b_path.size() == 0 or b_path[b_path.size() - 1] != to_k or rng.randf() < 0.02):
			b_path = nav_path(from_k, to_k)
			if b_path.size() > 1: b_path.pop_front()
	if b_path.size() > 0:
		var nk: String = b_path[0]
		var c: Vector2i = cells[nk]
		goal = cell_center(c.x, c.y)
		var cur_k := cell_key_at(butcher.position)
		var dr = door_between(cur_k, nk)
		if dr != null and dr.kind == "door":
			dr.locked = false
			if dr.amount < 0.6:
				dr.open_from(butcher.position)
				if butcher.position.distance_to(dr.pos) < 1.6:
					butcher.velocity = Vector3.ZERO
					return
		if Vector2(butcher.position.x - goal.x, butcher.position.z - goal.z).length() < 0.35: b_path.pop_front()
	var dir := goal - butcher.position
	dir.y = 0.0
	if dir.length() > 0.05:
		dir = dir.normalized()
		butcher.rotation.y = lerp_angle(butcher.rotation.y, atan2(dir.x, dir.z), minf(1.0, 8.0 * dt))
		butcher.velocity = dir * speed
		butcher.velocity.y = -2.0
		butcher.move_and_slide()
		# stuck? sidestep
		b_stuck += dt if butcher.position.distance_to(b_prev) < 0.01 else 0.0
		b_prev = butcher.position
		if b_stuck > 1.2:
			b_stuck = 0.0
			b_path = []
			if b_state == "patrol": b_wait = 0.5

# ------------------------------------------------ characters / apparitions
func _looking_at(p: Vector3, cos_min := 0.6) -> bool:
	var f := -cam.global_transform.basis.z
	var to := p + Vector3(0, 1.0, 0) - cam.global_position
	return f.dot(to.normalized()) > cos_min

func _update_characters(dt: float) -> void:
	# Girl (weeping angel): frozen while seen, creeps closer when you look away.
	var gd := girl.position.distance_to(player.position)
	var seen := _looking_at(girl.position) and _los(cam.global_position, girl.position + Vector3(0, 1.2, 0))
	var to_p := player.position - girl.position
	girl.rotation.y = lerp_angle(girl.rotation.y, atan2(to_p.x, to_p.z), minf(1.0, 3.0 * dt)) if not seen else girl.rotation.y
	if not seen and gd < 16.0 and gd > 1.3:
		girl.position += Vector3(to_p.x, 0, to_p.z).normalized() * 1.1 * dt
	if gd < 1.2:
		shake = 1.2
		post_mat.set_shader_parameter("flash", 0.5)
		play("stinger", -6.0)
		stamina = maxf(0.0, stamina - 0.4)
		girl.position = Vector3(3.2, 0, 3.9)
		say("Something cold touched your neck.")
	# Doll watches you.
	var dd := player.position - doll.global_position
	doll.rotation.y = lerp_angle(doll.rotation.y, atan2(dd.x, dd.z), minf(1.0, 2.0 * dt))
	# Ghost drifts through the dining room.
	ghost.position = Vector3(19.0 + sin(time * 0.4) * 1.6, 0.35 + sin(time * 1.3) * 0.1, 10.0 + cos(time * 0.3) * 2.4)
	ghost.rotation.y = time * 0.4 + PI / 2.0
	# Woman at the end of the hall: appears, stares, vanishes when you get close or look for long.
	if woman.visible:
		woman_life -= dt
		var wp := player.position - woman.position
		woman.rotation.y = atan2(wp.x, wp.z)
		if wp.length() < 4.5 or woman_life <= 0.0:
			woman.visible = false
			woman_t = rng.randf_range(30.0, 55.0)
			play("stinger", -10.0)
	else:
		woman_t -= dt
		if woman_t <= 0.0 and room_of.get(cell_key_at(player.position), {}).get("id", "") == "hall":
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			woman.position = Vector3(clampf(player.position.x + fwd.x * 10.0, 3.0, 26.0), 0, 6.0)
			woman.visible = true
			woman_life = 5.0
			say("...", 2.0)
	# Rat scurries around.
	rat_t -= dt
	if not rat.visible and rat_t <= 0.0:
		rat.visible = true
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		rat.position = Vector3(player.position.x - side * 7.0, 0.0, 5.3 + rng.randf() * 1.4)
		rat.set_meta("dir", side)
		rat.rotation.y = PI / 2.0 if side > 0.0 else -PI / 2.0
	elif rat.visible:
		var s: float = rat.get_meta("dir")
		rat.position.x += s * 3.4 * dt
		rat.position.y = absf(sin(time * 26.0)) * 0.012
		if absf(rat.position.x - player.position.x) > 10.0 and (rat.position.x - player.position.x) * s > 0.0:
			rat.visible = false
			rat_t = rng.randf_range(10.0, 22.0)

func _update_director(dt: float) -> void:
	scare_t -= dt
	if scare_t <= 0.0:
		scare_t = rng.randf_range(16.0, 32.0)
		var pick := rng.randi() % 3
		var pk := cell_key_at(player.position)
		match pick:
			0:
				for b in bulbs:
					if (b.pos as Vector3).distance_to(player.position) < 8.0:
						b.mode = "flicker"
						get_tree().create_timer(2.5).timeout.connect(func(): b.mode = "on")
			1:
				play("door", -4.0)
				for d in doors:
					if d.target > 0.0 and d.pos.distance_to(player.position) < 12.0:
						d.speed = 9.0
						d.close()
						noise(d.pos, 10.0)
						break
			2:
				play("stinger", -14.0)
				say("Footsteps. Not yours.", 3.0)
