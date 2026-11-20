extends Node3D
## THE LAST REVENGE - A first-person survival-horror story built from Pixel-Forge GLB assets.
##
## Abel Crane (The Butcher / Father): Hunts by sight and sound in the slaughterhouse.
## Ada (Blood-Stained Ghost / Younger Sister): In the vintage living room, communicates by walkie-talkie.
## Mira (The Woman / Butcher's Wife): Haunts the horror corridor; her key is near its entrance.
## Pearl (Cursed Doll): Sits on dresser, weeping & crying with 3D audio, watching Nora.
## Lily (Horror Girl): Transparent coming-and-going apparition; holds Father's Key!
## Bat: Slay Lily with the bloody baseball bat to get Father's Key.
## Street Rat: Scurries and bites player dealing damage.
## Light Switches & Breaker: Turning room lights on shorts the house; main breaker restores power.
## Tunnel: The player begins inside it and must return there to escape.

const Story = preload("res://horror/story.gd")
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
	"walkie": "res://psx-style_horror_walkie-talkie.glb",
	"bible": "res://devils_bible_-_dark_fantasy_book.glb",
	"pig": "res://dead_pig.glb",
	"meat": "res://psx_raw_meat_pack__low-poly_2_types.glb",
	"bloodbag": "res://blood_bag.glb",
	"bloodwall": "res://abandoned_horror_wall_with_blood_splatter.glb",
	"clock": "res://vintage_wooden_wall_clock_-.glb",
	"fan": "res://old_rusty_ceiling_fan.glb",
	"bat": "res://baseball_bat_covered_in_blood.glb",
	"toilet": "res://old_wooden_toilet_house_2.glb",
	"swamp": "res://abandoned_shack_in_the_swamp.glb",
	"farm": "res://weathered_red_saltbox_farmhouse.glb",
	"corridor": "res://horror_corridor_5.glb",
	"parlor": "res://modular_vintage_living_room_-_game_ready_pbr.glb",
	"diorama": "res://textured_game_environment.glb",
	"room": "res://horror_room.glb",
	"tunnel": "res://tunnel.glb",
	"soviet": "res://horror_soviet_room.glb",
	"hook": "res://butcher_meat_hook_rail_-_cured_ham__sausages.glb",
	"mask": "res://jeson_horror_fan_art.glb",
}

# ---------------------------------------------------------------- floor plan
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
	{"i": 10, "j": 5, "s": "E", "k": "door", "lock": "slaughter", "n": "Slaughter room door (Father's Room)"},
	{"i": 13, "j": 4, "s": "N", "k": "door", "lock": "slaughter", "n": "Slaughter room back door"},
	{"i": 9, "j": 6, "s": "S", "k": "door", "tag": "tunnel_entry", "n": "Tunnel-side Dining Room Entrance"},
	{"i": 1, "j": 3, "s": "W", "k": "door", "lock": "corridor", "n": "Corridor door (Mira's Wing)"},
	{"i": 7, "j": 6, "s": "S", "k": "door", "lock": "front", "n": "Front door"},
]
const WINDOWS := [
	[2, 1, "N"], [4, 1, "N"], [1, 2, "W"], [5, 1, "N"], [8, 1, "N"], [11, 1, "N"], [13, 1, "N"],
	[1, 3, "W"], [13, 3, "E"], [2, 6, "S"], [4, 6, "S"], [10, 6, "S"], [12, 6, "S"], [13, 5, "E"],
]
const BULBS := [
	[3, 3, 1.0], [7, 3, 1.0], [11, 3, 1.0], [7, 5, 1.0], [11, 2, 0.9], [9, 5, 0.8],
	[2, 1, 0.8], [8, 1, 0.8], [3, 5, 0.8], [12, 5, 0.8]
]
const SIDE := {
	"N": {"dx": 0, "dz": -1, "rot": 0.0, "axis": "x"},
	"S": {"dx": 0, "dz": 1, "rot": PI, "axis": "x"},
	"E": {"dx": 1, "dz": 0, "rot": -PI / 2.0, "axis": "z"},
	"W": {"dx": -1, "dz": 0, "rot": PI / 2.0, "axis": "z"},
}

class MainDoor extends RefCounted:
	var pivot: Node3D
	var body: StaticBody3D
	var amount := 0.0
	var target := 0.0
	var dir := 1.0
	var speed := 2.6
	var locked := false
	var lock := ""
	var tag := ""
	var label := "Door"
	var pos := Vector3.ZERO
	var kind := "door"
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
var health := 100.0
var max_health := 100.0
var stamina := 1.0
var battery := 1.0
var flash_on := false
var has_father_key := false
var has_mira_key := false
var has_bible := false
var has_bat := false
var has_walkie := false
var blood_bags := 0
var entered_house := false
var lore_found: Array[String] = []
var pearl_comforted := false
var short_circuits := 0
var exhausted := false
var girl_hit_cd := 0.0
var girl_manifest_cd := 0.0
var rat_squeak_cd := 0.0
var bat_in_hand: Node3D = null
var bat_swinging := false
var bat_swing_t := 0.0
var house_power := true
var short_circuit_t := 0.0
var batteries := 0
var step_t := 0.0
var noise_cd := 0.0
var time := 0.0
var shake := 0.0
var rng := RandomNumberGenerator.new()

# butcher AI (Father: Abel Crane)
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
var b_stun := 0.0
var enraged := false
var butcher_confined := true

# apparitions & entities
var girl: CharacterBody3D       # Lily (Horror Girl - holds Father's Key)
var girl_model: Node3D
var girl_meshes: Array = []
var girl_alpha := 0.0
var girl_alive := true
var girl_flicker_t := 0.0
var ghost_alive := true
var woman_alive := true
var doll: Node3D                 # Pearl (Cursed Doll - weeping)
var p_doll_cry: AudioStreamPlayer3D
var p_girl: AudioStreamPlayer3D
var ghost: Node3D                # Ada (Sister Spirit - Living Room)
var woman: Node3D                # Mira (The Woman - Corridor)
var rat: CharacterBody3D         # Street Rat - bites player
var rat_bite_cd := 0.0
var rat_alive := true
var fan: Node3D                  # Rusted Fan - squeaking
var p_fan: AudioStreamPlayer3D
var clock: Node3D                # Vintage Wall Clock - ticking
var p_clock: AudioStreamPlayer3D
var tunnel_zone: Node3D

# Required story objectives and optional mini-missions.
var missions := [
	{"id": "power", "text": "Switch on the master breaker beside the tunnel entrance", "required": true, "done": false},
	{"id": "enter", "text": "Follow the lanterns and enter the dining room", "required": true, "done": false},
	{"id": "bat", "text": "Find the bloody baseball bat in the study", "required": true, "done": false},
	{"id": "walkie", "text": "Find Ada's walkie-talkie in the vintage living room", "required": true, "done": false},
	{"id": "lily", "text": "Defeat Lily while she is visible to release Father's key", "required": true, "done": false},
	{"id": "father_key", "text": "Collect Father's slaughterhouse key", "required": true, "done": false},
	{"id": "bible", "text": "Unlock the slaughterhouse and take the Devil's Bible", "required": true, "done": false},
	{"id": "escape", "text": "Return to the underground tunnel and escape", "required": true, "done": false},
	{"id": "ada", "text": "Free Ada's blood-stained spirit with the bat", "required": false, "done": false},
	{"id": "mira_key", "text": "Find Mira's key beside the west corridor", "required": false, "done": false},
	{"id": "mira", "text": "Unlock the west corridor and free the Butcher's wife", "required": false, "done": false},
	{"id": "breaker", "text": "Restore power after causing a short circuit", "required": false, "done": false},
	{"id": "memories", "text": "Recover all four family memories", "required": false, "done": false},
	{"id": "pearl", "text": "Find Pearl's drawing, then comfort the crying doll", "required": false, "done": false},
	{"id": "rat", "text": "Stop the street rat terrorizing the house", "required": false, "done": false},
]

# ui
var hud_obj: Label
var hud_prompt: Label
var hud_msg: Label
var hud_warn: Label
var hud_controls: Label
var hud_missions: Label
var bar_health: ProgressBar
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
	_show_overlay("THE LAST REVENGE\n\n[ENTER]  Start The Hunt\n[G]  Asset Gallery\n\nCONTROLS:\nWASD: Move   |   Mouse: Look   |   Shift: Sprint   |   C: Crouch\nF: Flashlight   |   E: Interact   |   R: Radio   |   Q: Use Blood Bag\nLMB / T: Bat Attack   |   Esc: Pause\n\nLORE & OBJECTIVES:\n* Abel Crane, your father, hunts the Hollis house as the Butcher.\n* Mira is his wife. Your younger sister Ada is the blood-stained ghost in the living room.\n* Find the Bloody Bat, defeat Lily for Father's key, then search the slaughterhouse for the Devil's Bible.\n* Collect blood bags; use Q when hurt. Eat raw meat to restore health.\n* Room switches can short the whole house. Use the main breaker; every power change draws Lily near.\n* Begin in the tunnel, search the house, and escape back through it!")
	if autostart:
		autostart = false
		_start()
	if missing.size() > 0:
		hud_warn.text = "%d model(s) are Git LFS stubs - run `git lfs pull` and reopen the project." % missing.size()

# ---------------------------------------------------------------- helpers
func _kit(piece_name: String) -> PackedScene:
	if not kit_cache.has(piece_name):
		kit_cache[piece_name] = load(KIT + piece_name + ".glb")
	return kit_cache[piece_name]

func piece(piece_name: String, pos: Vector3, rot := 0.0) -> Node3D:
	var ps: PackedScene = _kit(piece_name)
	var n: Node3D
	if ps == null:
		if not missing.has(piece_name): missing.append(piece_name)
		n = Node3D.new()
	else:
		n = ps.instantiate()
	n.position = pos
	n.rotation.y = rot
	level_root.add_child(n)
	return n

func add_box(center: Vector3, box_size: Vector3, layer := 1, parent: Node = null) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = box_size
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

func fit(key_or_path: String, height := 0.0, target_length := 0.0, face_x := false) -> Node3D:
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
	elif target_length > 0.0:
		var m := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
		if m > 0.0: k = target_length / m
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
	env.ambient_light_color = Color(0.12, 0.14, 0.20)
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
				var d := MainDoor.new()
				d.kind = "door"
				d.label = e.def.n
				d.lock = e.def.get("lock", "")
				d.tag = e.def.get("tag", "")
				d.locked = d.lock != ""
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
			var l := OmniLight3D.new()
			l.position = Vector3(p.x, 2.5, p.z)
			l.light_color = Color(1.0, 0.82, 0.58)
			l.omni_range = 9.0
			l.light_energy = 1.6 * bulb_at[key]
			l.shadow_enabled = false
			level_root.add_child(l)
			var rm_id: String = room_of.get(key, {}).get("id", "hall")
			bulbs.append({"light": l, "base": l.light_energy, "mode": "on", "t": 0.0, "pos": p, "room": rm_id})
		else:
			piece("house_ceiling", p)

	# Build Room Light Switches
	_build_switches()

func _build_switches() -> void:
	# The whole-house breaker is outside, beside the tunnel-side dining room entrance.
	var breaker_pos := Vector3(19.15, 1.35, 13.18)
	var main_sw := _create_switch_node(breaker_pos, "Main Power Breaker")
	main_sw.rotation.y = PI
	interact.append({
		"kind": "main_switch",
		"node": main_sw,
		"pos": breaker_pos,
		"label": "Toggle Whole-House Main Breaker",
	})

	# Room switches placed on walls
	var sw_data := [
		{"room": "living", "pos": Vector3(2.1, 1.35, 7.9), "lbl": "Living Room Light Switch"},
		{"room": "bed", "pos": Vector3(2.1, 1.35, 3.9), "lbl": "Bedroom Light Switch"},
		{"room": "bath", "pos": Vector3(10.1, 1.35, 3.9), "lbl": "Bathroom Light Switch"},
		{"room": "kitchen", "pos": Vector3(20.1, 1.35, 3.9), "lbl": "Kitchen Light Switch"},
		{"room": "dining", "pos": Vector3(18.1, 1.35, 7.9), "lbl": "Dining Room Light Switch"},
		{"room": "slaughter", "pos": Vector3(22.1, 1.35, 7.9), "lbl": "Slaughterhouse Light Switch"},
	]
	for sw in sw_data:
		var node := _create_switch_node(sw.pos, sw.lbl)
		interact.append({
			"kind": "room_switch",
			"room": sw.room,
			"node": node,
			"pos": sw.pos,
			"label": "Flip " + sw.lbl,
			"on": true
		})

func _create_switch_node(pos: Vector3, _lbl_text: String) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.18, 0.05)
	base.mesh = bm
	base.material_override = _mat(Color(0.2, 0.2, 0.22), 0.5, 0.5)
	root.add_child(base)

	var lever := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.04, 0.08, 0.06)
	lever.mesh = lm
	lever.material_override = _mat(Color(0.8, 0.2, 0.1), 0.3, 0.8)
	lever.position.z = 0.03
	root.add_child(lever)
	add_child(root)
	return root

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
	# Hanging dead pigs in the Slaughterhouse
	for p in [[22.6, 8.0], [25.6, 11.8], [22.4, 11.0]]:
		var pig := fit("pig", 1.25)
		pig.position = Vector3(p[0], 3.0 - 1.55, p[1])
		add_child(pig)

	# Meat hook rail hung from the ceiling of the Slaughterhouse
	var hook := fit("hook", 0, 3.4)
	hook.position = Vector3(24.0, 2.5, 10.5)
	add_child(hook)

	# Blood-soaked walls continue through the house, not just the slaughter room.
	for bpos in [
		Vector3(24.0, 0, 7.2), Vector3(25.8, 0, 10.0), Vector3(14.0, 0, 5.8), Vector3(8.0, 0, 7.8),
		Vector3(22.0, 0, 12.5), Vector3(26.4, 0, 8.5), Vector3(3.0, 0, 4.0), Vector3(17.0, 0, 4.0),
		Vector3(6.0, 0, 6.8), Vector3(12.0, 0, 6.8), Vector3(20.0, 0, 6.8), Vector3(4.0, 0, 11.8),
	]:
		var bw := fit("bloodwall", 0, 4.8)
		bw.position = bpos
		add_child(bw)
	for pool in [
		[Vector3(23.4, 0.018, 9.0), Vector2(2.2, 1.2)], [Vector3(25.2, 0.018, 11.4), Vector2(1.4, 2.0)],
		[Vector3(15.0, 0.018, 6.2), Vector2(1.6, 0.8)], [Vector3(7.0, 0.018, 5.5), Vector2(1.0, 1.5)],
		[Vector3(4.5, 0.018, 9.2), Vector2(1.5, 1.1)], [Vector3(16.2, 0.018, 2.6), Vector2(0.8, 1.3)],
		[Vector3(20.0, 0.018, 5.8), Vector2(1.0, 0.7)], [Vector3(5.6, 0.018, 2.4), Vector2(1.2, 0.8)],
	]:
		_add_blood_pool(pool[0], pool[1])

	# Vintage wooden wall clock (with functional ticking sound)
	clock = fit("clock", 0, 0.6)
	clock.position = Vector3(1.17, 1.8, 9.6)
	clock.rotation.y = PI / 2.0
	add_child(clock)
	p_clock = AudioStreamPlayer3D.new()
	p_clock.unit_size = 2.0
	p_clock.max_distance = 18.0
	clock.add_child(p_clock)

	# Old rusty ceiling fan (spinning with creaking sound)
	fan = fit("fan", 0, 1.3)
	fan.position = Vector3(23.0, 2.4, 3.0)
	add_child(fan)
	p_fan = AudioStreamPlayer3D.new()
	p_fan.unit_size = 2.5
	p_fan.max_distance = 22.0
	fan.add_child(p_fan)

	# Wooden outhouse / toilet inside bathroom
	var toilet := fit("toilet", 2.2)
	toilet.position = Vector3(11.4, 0, 2.1)
	toilet.rotation.y = PI
	add_child(toilet)

	# Vintage Living Room set (Ada's parlor domain)
	var parlor := fit("parlor", 2.7)
	parlor.position = Vector3(5.0, 0, 9.8)
	add_child(parlor)

	# Horror Corridor 5 (Mira's domain extending West from hallway)
	var corr := fit("corridor", 2.8)
	corr.position = Vector3(-3.5, 0, 6.0)
	corr.rotation.y = PI / 2.0
	add_child(corr)

	# Underground Tunnel (The secret exit route)
	var tunnel := fit("tunnel", 3.0)
	tunnel.position = Vector3(25.0, -0.2, 18.0)
	add_child(tunnel)

	# Underground Tunnel Exit trigger
	tunnel_zone = Node3D.new()
	tunnel_zone.position = Vector3(25.0, 0, 26.0)
	add_child(tunnel_zone)
	interact.append({
		"kind": "tunnel_exit",
		"pos": Vector3(25.0, 0.8, 26.0),
		"label": "Escape Through Tunnel to Surface"
	})

	# A readable, unobstructed route from the spawn tunnel to the unlocked dining entrance.
	for lamp_pos in [Vector3(24.0, 0, 20.0), Vector3(22.0, 0, 17.5), Vector3(20.0, 0, 15.2), Vector3(19.2, 0, 14.0)]:
		_add_path_lantern(lamp_pos)

func _add_blood_pool(pos: Vector3, pool_size: Vector2) -> void:
	var pool := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = pool_size
	pool.mesh = mesh
	var material := _mat(Color(0.24, 0.002, 0.006, 0.9), 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool.material_override = material
	pool.position = pos
	pool.rotation.y = rng.randf() * TAU
	level_root.add_child(pool)

func _add_path_lantern(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	level_root.add_child(root)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.035
	post_mesh.bottom_radius = 0.055
	post_mesh.height = 1.15
	post.mesh = post_mesh
	post.material_override = _mat(Color(0.09, 0.07, 0.05), 0.8, 0.4)
	post.position.y = 0.575
	root.add_child(post)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.09
	lamp_mesh.height = 0.18
	lamp.mesh = lamp_mesh
	var glow_material := _mat(Color(1.0, 0.52, 0.16), 0.4)
	glow_material.emission_enabled = true
	glow_material.emission = Color(1.0, 0.24, 0.04)
	glow_material.emission_energy_multiplier = 2.0
	lamp.material_override = glow_material
	lamp.position.y = 1.18
	root.add_child(lamp)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.42, 0.16)
	light.light_energy = 0.85
	light.omni_range = 5.0
	light.position.y = 1.18
	root.add_child(light)

func _build_characters() -> void:
	# 1. The Butcher (Father: Abel Crane)
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
	p_butcher.unit_size = 3.5
	p_butcher.max_distance = 32.0
	butcher.add_child(p_butcher)

	var carry := OmniLight3D.new()
	carry.light_color = Color(1.0, 0.25, 0.15)
	carry.light_energy = 0.0
	carry.omni_range = 3.5
	carry.position.y = 1.6
	butcher.add_child(carry)
	butcher.set_meta("eye_light", carry)

	# 2. Lily (Horror Girl - Possessed Youngest Sister)
	# Transparent coming and going motion; holds Father's Key!
	girl = CharacterBody3D.new()
	girl.collision_layer = 4
	girl.collision_mask = 1
	var g_cs := CollisionShape3D.new()
	var g_cap := CapsuleShape3D.new()
	g_cap.radius = 0.32
	g_cap.height = 1.65
	g_cs.shape = g_cap
	g_cs.position.y = 0.82
	girl.add_child(g_cs)
	girl_model = fit("girl", 1.68)
	girl.add_child(girl_model)
	girl_meshes.clear()
	for mesh in girl_model.find_children("*", "MeshInstance3D", true, false):
		var apparition_mesh := mesh as MeshInstance3D
		apparition_mesh.transparency = 0.5
		girl_meshes.append(apparition_mesh)
	girl.position = Vector3(4.2, 0, 5.9)
	add_child(girl)
	p_girl = AudioStreamPlayer3D.new()
	p_girl.unit_size = 3.0
	p_girl.max_distance = 24.0
	girl.add_child(p_girl)

	# 3. Pearl (Cursed Porcelain Doll - in bedroom, continuously weeping)
	doll = fit("doll", 0.55)
	doll.position = Vector3(1.75, 0.8, 4.6)
	add_child(doll)
	p_doll_cry = AudioStreamPlayer3D.new()
	p_doll_cry.unit_size = 2.0
	p_doll_cry.max_distance = 16.0
	doll.add_child(p_doll_cry)
	interact.append({
		"kind": "pearl",
		"node": doll,
		"pos": Vector3(1.75, 1.1, 4.6),
		"label": "Comfort the Crying Porcelain Doll",
	})

	# 4. Ada (Ghost - Sister spirit in Vintage Living Room)
	ghost = fit("ghost", 1.7, 0, true)
	ghost.position = Vector3(5.2, 0.35, 9.5)
	add_child(ghost)

	# 5. Mira (The Woman - Mother in Horror Corridor)
	woman = fit("woman", 1.7)
	woman.position = Vector3(-3.2, 0, 6.0)
	woman.visible = true
	add_child(woman)

	# 6. Street Rat (Runs and bites human)
	rat = CharacterBody3D.new()
	rat.collision_layer = 4
	rat.collision_mask = 1
	var r_cs := CollisionShape3D.new()
	var r_box := BoxShape3D.new()
	r_box.size = Vector3(0.3, 0.2, 0.5)
	r_cs.shape = r_box
	r_cs.position.y = 0.1
	rat.add_child(r_cs)
	var r_mesh := fit("rat", 0, 0.45, true)
	rat.add_child(r_mesh)
	rat.position = Vector3(15.0, 0, 3.8)
	add_child(rat)

func _build_items() -> void:
	# 1. Bloody Baseball Bat (Weapon pickup)
	var bat_pickup := fit("bat", 0, 0.9)
	bat_pickup.position = Vector3(15.2, 0.1, 2.5)
	bat_pickup.rotation.z = 1.2
	add_child(bat_pickup)
	interact.append({
		"kind": "bat_pickup",
		"node": bat_pickup,
		"pos": Vector3(15.2, 0.3, 2.5),
		"label": "Take Bloody Baseball Bat (Weapon)"
	})

	# 2. Walkie-Talkie (Ada's communication device in Vintage Living Room)
	var walkie := fit("walkie", 0, 0.26)
	walkie.position = Vector3(5.2, 0.55, 9.4)
	add_child(walkie)
	interact.append({
		"kind": "walkie",
		"node": walkie,
		"pos": Vector3(5.2, 0.55, 9.4),
		"label": "Take Ada's Walkie-Talkie"
	})

	# 3. Mira's Key (in Horror Corridor area)
	# Mira key torus
	var tm := TorusMesh.new()
	tm.inner_radius = 0.03
	tm.outer_radius = 0.06
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = _mat(Color(0.8, 0.3, 0.3), 0.3, 0.8)
	mi.position = Vector3(1.4, 0.6, 5.8)
	add_child(mi)
	interact.append({
		"kind": "mira_key",
		"node": mi,
		"pos": Vector3(1.4, 0.6, 5.8),
		"label": "Take Mira's Corridor Key"
	})

	# 4. Raw Meat Pack (Kitchen counter - can be eaten to heal HP)
	var meat := fit("meat", 0, 0.65)
	meat.position = Vector3(23.4, 0.92, 1.55)
	add_child(meat)
	interact.append({
		"kind": "meat",
		"node": meat,
		"pos": Vector3(23.4, 0.92, 1.55),
		"label": "Eat Raw Meat (+15 HP)"
	})

	# 5. Blood Bags (collect now, use with Q when injured)
	var bb1 := fit("bloodbag", 0, 0.32)
	bb1.position = Vector3(11.2, 0.85, 1.6)
	add_child(bb1)
	interact.append({
		"kind": "bloodbag",
		"node": bb1,
		"pos": Vector3(11.2, 0.85, 1.6),
		"label": "Collect Blood Bag"
	})

	var bb2 := fit("bloodbag", 0, 0.32)
	bb2.position = Vector3(26.0, 0.92, 10.2)
	add_child(bb2)
	interact.append({
		"kind": "bloodbag",
		"node": bb2,
		"pos": Vector3(26.0, 0.92, 10.2),
		"label": "Collect Blood Bag"
	})

	# 6. Devil's Bible (Altar in Slaughterhouse)
	var bible := fit("bible", 0.34)
	bible.position = Vector3(24.0, 0.93, 10.0)
	add_child(bible)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.1, 0.05)
	glow.light_energy = 2.2
	glow.omni_range = 5.0
	glow.position = Vector3(24.0, 1.4, 10.0)
	add_child(glow)
	interact.append({
		"kind": "bible",
		"node": bible,
		"pos": Vector3(24.0, 1.1, 10.0),
		"label": "Seize the Devil's Bible",
		"glow": glow
	})

	# 7. Flashlight Batteries scattered
	var bspots := [
		Vector3(4.6, 0.6, 1.55), Vector3(11.3, 0.66, 1.65), Vector3(14.0, 0.84, 7.5),
		Vector3(22.0, 0.94, 4.4), Vector3(19.0, 0.78, 10.0), Vector3(27.0, 0.05, 12.4)
	]
	bspots.shuffle()
	for i in 4: _add_battery(bspots[i])
	_build_lore_pages()

func _build_lore_pages() -> void:
	var placements := {
		"abel_ledger": [Vector3(24.0, 0.94, 12.5), 0.2],
		"ada_note": [Vector3(4.8, 0.54, 8.0), -0.4],
		"mira_letter": [Vector3(1.25, 0.18, 6.5), 0.5],
		"pearl_drawing": [Vector3(6.0, 0.54, 2.5), -0.2],
	}
	for page in Story.LORE_PAGES:
		var placement: Array = placements[page.id]
		_add_lore_page(page, placement[0], placement[1])

func _add_lore_page(page: Dictionary, pos: Vector3, angle: float) -> void:
	var paper := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.34, 0.012, 0.46)
	paper.mesh = mesh
	var material := _mat(Color(0.72, 0.65, 0.48), 0.95)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.14, 0.06)
	material.emission_energy_multiplier = 0.35
	paper.material_override = material
	paper.position = pos
	paper.rotation.y = angle
	level_root.add_child(paper)
	interact.append({
		"kind": "lore",
		"node": paper,
		"pos": pos + Vector3(0, 0.08, 0),
		"label": "Read " + page.title,
		"page": page,
	})

func _add_battery(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
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
	interact.append({"kind": "battery", "node": mi, "pos": pos, "label": "Take Battery (+50%)"})

func _spawn_father_key(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.04
	tm.outer_radius = 0.08
	mi.mesh = tm
	var mat := _mat(Color(1.0, 0.85, 0.2), 0.2, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	interact.append({
		"kind": "father_key",
		"node": mi,
		"pos": pos,
		"label": "Take Father's Slaughterhouse Key"
	})
	say("Lily dropped Father's Brass Key! Take it.")
	play("stinger", -4.0)

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
	cam.far = 140
	cam.position.y = 1.62
	player.add_child(cam)

	flash = SpotLight3D.new()
	flash.light_color = Color(1.0, 0.94, 0.82)
	flash.light_energy = 6.0
	flash.spot_range = 30.0
	flash.spot_angle = 32.0
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

	# First-person Bloody Baseball Bat (hidden until equipped)
	bat_in_hand = fit("bat", 0, 0.75)
	bat_in_hand.position = Vector3(0.3, -0.25, -0.45)
	bat_in_hand.rotation = Vector3(0.2, -0.4, 0.3)
	bat_in_hand.visible = false
	cam.add_child(bat_in_hand)

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
	snd["stinger"] = _wav(func(t, _d): return (sin(TAU * 110.0 * t) + sin(TAU * 116.5 * t) + sin(TAU * 185.0 * t) * 0.7 + r.randf_range(-1, 1) * 0.4) * exp(-t * 2.0) * 0.35, 1.8)
	snd["door"] = _wav(func(t, d): return sin(TAU * (150.0 + 90.0 * sin(t * 3.0)) * t) * sin(PI * t / d) * 0.35 + r.randf_range(-1, 1) * 0.05, 0.8)
	snd["click"] = _wav(func(t, _d): return r.randf_range(-1, 1) * exp(-t * 120.0), 0.06)
	snd["drone"] = _wav(func(t, _d): return (sin(TAU * 41.0 * t) + sin(TAU * 41.5 * t) + sin(TAU * 61.5 * t) * 0.5 + r.randf_range(-1, 1) * 0.05) * 0.2, 4.0, true)

	# New sound effects:
	snd["clock_tick"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * exp(-t * 220.0) + sin(TAU * 1200.0 * t) * exp(-t * 80.0)) * 0.6, 0.1)
	snd["fan_creak"] = _wav(func(t, _d): return (sin(TAU * (80.0 + 30.0 * sin(t * 8.0)) * t) * (0.3 + 0.7 * absf(sin(t * 4.0)))) * 0.4, 1.5, true)
	snd["doll_cry"] = _wav(func(t, _d): return (sin(TAU * (320.0 + 80.0 * sin(t * 5.0) + 40.0 * sin(t * 13.0)) * t) * (0.4 + 0.6 * sin(t * 2.5))) * 0.35, 2.5, true)
	snd["rat_squeak"] = _wav(func(t, _d): return sin(TAU * (2200.0 + 400.0 * sin(t * 40.0)) * t) * exp(-t * 12.0) * 0.5, 0.18)
	snd["rat_bite"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * exp(-t * 30.0) + sin(TAU * 2400.0 * t) * exp(-t * 20.0)) * 0.7, 0.25)
	snd["bat_swing"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * 0.5 + sin(TAU * (120.0 + 300.0 * t / 0.3) * t)) * sin(PI * t / 0.3) * 0.6, 0.3)
	snd["ghost_hit"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * exp(-t * 8.0) + sin(TAU * 650.0 * t) * exp(-t * 14.0)) * 0.8, 0.4)
	snd["spark"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * (1.0 if sin(t * 120.0) > 0.3 else 0.1) * exp(-t * 6.0)) * 0.8, 0.5)
	snd["radio"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * 0.4 + sin(TAU * 880.0 * t) * 0.2) * exp(-t * 4.0), 0.6)
	snd["eat"] = _wav(func(t, _d): return (r.randf_range(-1, 1) * exp(-t * 40.0) + sin(TAU * 200.0 * t) * exp(-t * 20.0)) * 0.6, 0.35)
	snd["heal"] = _wav(func(t, _d): return sin(TAU * (220.0 + 110.0 * t) * t) * exp(-t * 3.0) * 0.6, 0.6)

	p_heart = AudioStreamPlayer.new(); p_heart.stream = snd["heart"]; add_child(p_heart)
	p_sfx = AudioStreamPlayer.new(); add_child(p_sfx)
	p_amb = AudioStreamPlayer.new(); p_amb.stream = snd["drone"]; p_amb.volume_db = -10.0; add_child(p_amb)

	# Start 3D ambient emitters
	p_fan.stream = snd["fan_creak"]
	p_fan.volume_db = -6.0
	p_fan.play()

	p_doll_cry.stream = snd["doll_cry"]
	p_doll_cry.volume_db = -4.0
	p_doll_cry.play()

func play(sname: String, vol := 0.0) -> void:
	if not snd.has(sname): return
	var p := AudioStreamPlayer.new()
	p.stream = snd[sname]
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
	hud_missions = _label("", Vector2(24, 52), 15, Color(0.95, 0.8, 0.4))

	hud_prompt = _label("", Vector2(0, 0), 22, Color(1, 1, 1))
	hud_prompt.set_anchors_preset(Control.PRESET_CENTER)
	hud_prompt.position = Vector2(-160, 60)

	hud_msg = _label("", Vector2(0, 0), 20, Color(0.9, 0.85, 0.6))
	hud_msg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud_msg.position = Vector2(-380, -140)

	hud_warn = _label("", Vector2(24, 690), 14, Color(1, 0.5, 0.3))

	# Bars: Health, Stamina, Flashlight Battery
	var lbl_hp := _label("HEALTH", Vector2(24, 595), 12, Color(1, 0.3, 0.3))
	bar_health = ProgressBar.new(); bar_health.max_value = 100.0; bar_health.show_percentage = false
	bar_health.position = Vector2(24, 615); bar_health.size = Vector2(180, 8)
	var sb_hp := StyleBoxFlat.new(); sb_hp.bg_color = Color(0.85, 0.15, 0.15)
	bar_health.add_theme_stylebox_override("fill", sb_hp)

	var lbl_stam := _label("STAMINA", Vector2(24, 627), 12, Color(0.4, 0.8, 1.0))
	bar_stam = ProgressBar.new(); bar_stam.max_value = 1.0; bar_stam.show_percentage = false
	bar_stam.position = Vector2(24, 645); bar_stam.size = Vector2(180, 8)

	var lbl_batt := _label("BATTERY", Vector2(24, 657), 12, Color(0.9, 0.9, 0.3))
	bar_batt = ProgressBar.new(); bar_batt.max_value = 1.0; bar_batt.show_percentage = false
	bar_batt.position = Vector2(24, 675); bar_batt.size = Vector2(180, 8)

	# Bottom Controls Helper Bar
	hud_controls = _label(
		"[WASD] Move   [Shift] Sprint   [C] Crouch   [F] Flashlight   [E] Interact   [LMB / T] Bat Attack   [Esc] Pause",
		Vector2(0, -32),
		14,
		Color(1, 1, 0.8, 0.85)
	)
	hud_controls.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for n in [hud_obj, hud_missions, hud_prompt, hud_msg, hud_warn, lbl_hp, bar_health, lbl_stam, bar_stam, lbl_batt, bar_batt, hud_controls]:
		hud.add_child(n)

	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.6)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.size = Vector2(4, 4)
	dot.position = Vector2(-2, -2)
	hud.add_child(dot)

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label = _label("", Vector2(0, 0), 22, Color(0.9, 0.85, 0.8))
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

func radio_message(msg: String) -> void:
	play("radio", 0.0)
	say(msg, 7.0)

func _use_walkie() -> void:
	if not has_walkie:
		say("You need Ada's walkie-talkie to reach her.")
		return
	if not girl_alive:
		radio_message("Ada (radio): Lily's curse is broken. The Father's key is yours. Get the Devil's Bible and come back to the tunnel.")
	elif not has_bat:
		radio_message("Ada (radio): Nora, find the bloody bat. Lily is flickering between the hall and the living room.")
	elif not has_mira_key:
		radio_message("Ada (radio): Mira's key is close to the corridor entrance. She is Abel's wife. Don't let her draw you in.")
	elif not has_bible:
		radio_message("Ada (radio): Father's room is behind the slaughterhouse door. Take the Devil's Bible from the altar.")
	else:
		radio_message("Ada (radio): Abel heard you take the book! Run through the tunnel, Nora!")

func _use_blood_bag() -> void:
	if blood_bags <= 0:
		say("You have no blood bags. Collect one from the house.")
		return
	if health >= max_health:
		say("You are already at full health. Save the blood bag for later.")
		return
	blood_bags -= 1
	health = minf(max_health, health + 35.0)
	play("heal")
	say("Used a collected blood bag (+35 HP). Blood bags remaining: %d." % blood_bags)

func complete_mission(mid: String) -> void:
	for m in missions:
		if m.id == mid and not m.done:
			m.done = true
			play("stinger", -12.0)
			say("OBJECTIVE COMPLETE: " + m.text, 5.0)

# ------------------------------------------------------------------- run
func _reset_run() -> void:
	# Start inside the tunnel facing back toward the house; escape uses this same route.
	player.position = Vector3(25.0, 0.05, 22.0)
	player.velocity = Vector3.ZERO
	yaw = 0.0
	pitch = 0.0
	health = 100.0
	stamina = 1.0
	battery = 1.0
	flash_on = false
	flash.visible = false
	has_father_key = false
	butcher_confined = true
	has_mira_key = false
	has_bible = false
	has_bat = false
	has_walkie = false
	blood_bags = 0
	batteries = 0
	enraged = false
	house_power = true
	girl_alive = true
	ghost_alive = true
	ghost.visible = true
	woman_alive = true
	woman.visible = true
	rat_alive = true
	b_state = "patrol"
	b_path = []
	butcher.position = Vector3(24.0, 0.05, 8.6)
	b_wait = 20.0
	for d in doors:
		d.target = 0.0
		d.amount = 0.0
		d.locked = d.lock != ""
	for m in missions: m.done = false
	post_mat.set_shader_parameter("flash", 0.0)
	post_mat.set_shader_parameter("desat", 0.0)

func _start() -> void:
	overlay.visible = false
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	p_amb.play()
	say("The radio whispers from the living room: 'Nora... come find me.'", 7.0)

func _die() -> void:
	state = "dead"
	play("stinger")
	post_mat.set_shader_parameter("flash", 0.85)
	_show_overlay("YOU DIED\n\nThe Butcher butchered your flesh.\n\n[ENTER] Try Again     [G] Gallery")

func _win() -> void:
	state = "won"
	complete_mission("escape")
	_show_overlay("YOU ESCAPED\n\nYou fled through the collapsing underground tunnel.\nThe Devil's Bible burns behind you in the ruins of the Hollis estate.\n\n[ENTER] Play Again     [G] Gallery")

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
	elif event is InputEventMouseButton and event.pressed and state == "play":
		if event.button_index == MOUSE_BUTTON_LEFT:
			_bat_attack()
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
					_show_overlay("PAUSED\n\n[ENTER] Resume     [G] Gallery")
				elif state == "pause":
					state = "play"
					overlay.visible = false
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			KEY_F:
				if state == "play": _toggle_flash()
			KEY_E:
				if state == "play": _interact()
			KEY_R:
				if state == "play": _use_walkie()
			KEY_Q:
				if state == "play": _use_blood_bag()
			KEY_T, KEY_B:
				if state == "play": _bat_attack()
	if event is InputEventKey and event.pressed and (event.physical_keycode == KEY_ENTER) and state == "pause":
		state = "play"; overlay.visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_flash() -> void:
	if not flash_on and battery <= 0.0:
		play("click", -12.0)
		return
	flash_on = not flash_on
	flash.visible = flash_on
	play("click")

func _bat_can_hit(target: Vector3, max_distance: float, fwd: Vector3) -> bool:
	var to_target := target - player.position
	var distance := to_target.length()
	return distance > 0.05 and distance <= max_distance and fwd.dot(to_target / distance) > 0.4

func _bat_attack() -> void:
	if not has_bat or bat_swinging: return
	bat_swinging = true
	bat_swing_t = 0.35
	play("bat_swing", -2.0)
	noise(player.position, 6.0)

	# Raycast forward to check hit
	var fwd := -cam.global_transform.basis.z
	# 1. Hit Lily (Horror Girl)
	if girl_alive and _bat_can_hit(girl.position + Vector3(0, 0.8, 0), 2.5, fwd):
		girl_alive = false
		play("ghost_hit", 4.0)
		say("You struck Lily! Her spirit dissolves into ash...")
		_spawn_father_key(girl.position + Vector3(0, 0.4, 0))
		girl.visible = false
		complete_mission("lily")
		radio_message("Ada (radio): Lily is free now... take Father's key and burn the Bible.")
		return

	# Blood-stained ghost and the Butcher's wife are spirits too; the bat can free them.
	if ghost_alive and _bat_can_hit(ghost.position + Vector3(0, 0.8, 0), 2.7, fwd):
		ghost_alive = false
		ghost.visible = false
		play("ghost_hit", 4.0)
		say("Ada's blood-stained spirit breaks apart and is finally at peace.")
		complete_mission("ada")
		return
	if woman_alive and _bat_can_hit(woman.position + Vector3(0, 0.8, 0), 2.7, fwd):
		woman_alive = false
		woman.visible = false
		play("ghost_hit", 4.0)
		say("Mira's apparition fades. The Butcher's wife is free.")
		complete_mission("mira")
		return

	# 2. Hit Street Rat
	if rat_alive and _bat_can_hit(rat.position + Vector3(0, 0.2, 0), 2.0, fwd):
		rat_alive = false
		rat.visible = false
		play("rat_squeak", 4.0)
		say("You crushed the vicious street rat!")
		return

	# 3. Hit Butcher (Father) -> Stun him!
	if _bat_can_hit(butcher.position + Vector3(0, 0.9, 0), 2.6, fwd):
		b_stun = 3.0
		play("ghost_hit", 4.0)
		shake = 1.0
		say("You staggered the Butcher with the bat! RUN!", 4.0)
		noise(player.position, 14.0)

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
		if cs < 0.84: continue
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
			var d: MainDoor = it.door
			if d.locked:
				if d.lock == "slaughter":
					if has_father_key:
						d.locked = false
						butcher_confined = false
						for o in doors: if o.lock == "slaughter": o.locked = false
						say("You unlocked Father's Slaughterhouse! The Butcher is awake!")
						play("door")
						play("stinger", 2.0)
						b_state = "chase"
						b_last_seen = player.position
					else:
						say("Locked by Abel Crane (Father). Lily holds Father's key! Defeat her with the bat.")
						play("click", -6.0)
						return
				elif d.lock == "corridor":
					if has_mira_key:
						d.locked = false
						say("Mira's key unlocks the corridor wing.")
						play("click")
					else:
						say("Locked. Mira's corridor key is needed.")
						play("click", -6.0)
						return
				elif d.lock == "front":
					say("The front door is sealed. The tunnel is the only way out.")
					play("click", -6.0)
					return
			if d.target > 0.0: d.close()
			else: d.open_from(player.position)
			play("door")
			noise(d.pos, 6.0)

		"bat_pickup":
			has_bat = true
			it.taken = true
			(it.node as Node3D).visible = false
			bat_in_hand.visible = true
			play("click")
			complete_mission("bat")
			say("Picked up Bloody Baseball Bat! Press LMB or T to attack.")

		"walkie":
			has_walkie = true
			it.taken = true
			(it.node as Node3D).visible = false
			play("radio")
			complete_mission("walkie")
			radio_message("Ada (radio): Nora... I'm trapped here with the others. Slay Lily to release Father's key.")

		"mira_key":
			has_mira_key = true
			it.taken = true
			(it.node as Node3D).visible = false
			play("click")
			complete_mission("mira_key")
			say("Found Mira's Corridor Key! It smells of dried lavender.")

		"father_key":
			has_father_key = true
			it.taken = true
			(it.node as Node3D).visible = false
			play("click")
			say("Found Father's Brass Key! You can now unlock the Slaughterhouse.")

		"meat":
			it.taken = true
			(it.node as Node3D).visible = false
			health = minf(max_health, health + 15.0)
			play("eat")
			say("Ate raw meat pack (+15 HP). You swallow down the nausea.")

		"bloodbag":
			it.taken = true
			(it.node as Node3D).visible = false
			blood_bags += 1
			play("click")
			say("Collected a blood bag. Press Q to use it. Bags: %d." % blood_bags)

		"battery":
			it.taken = true
			(it.node as Node3D).visible = false
			battery = minf(1.0, battery + 0.5)
			batteries += 1
			play("click")
			say("Battery +50%")

		"bible":
			it.taken = true
			(it.node as Node3D).visible = false
			(it.glow as OmniLight3D).visible = false
			has_bible = true
			enraged = true
			complete_mission("bible")
			for b in bulbs: b.mode = "flicker"
			play("stinger", 4.0)
			b_state = "chase"
			b_last_seen = player.position
			say("The Butcher roars in fury! ESCAPE THROUGH THE TUNNEL!", 8.0)
			radio_message("Ada (radio): RUN NORA! THE TUNNEL UNDER THE SLAUGHTERHOUSE!")

		"room_switch":
			if not house_power:
				play("click")
				say("There is no current. Reset the main breaker first.")
				return
			it.on = not it.on
			play("click")
			for b in bulbs:
				if b.room == it.room:
					b.mode = "on" if it.on else "off"
			# Turning a room light on blows the fuse for the whole house.
			if it.on:
				_trigger_short_circuit()
			else:
				say("Flipped light switch: " + ("ON" if it.on else "OFF"))

		"main_switch":
			house_power = not house_power
			play("spark")
			girl_flicker_t = 3.5
			if house_power:
				say("Main Breaker ENGAGED. House power restored.")
				complete_mission("breaker")
				for b in bulbs:
					if b.mode != "off":
						b.mode = "flicker"
				play("stinger", -8.0)
			else:
				say("Main Breaker TRIPPED. The house plunges into darkness.")

		"tunnel_exit":
			if has_bible:
				_win()
			else:
				say("You cannot leave without the Devil's Bible! It holds your family's souls.")

func _trigger_short_circuit() -> void:
	house_power = false
	short_circuit_t = 12.0
	play("spark", 4.0)
	shake = 1.4
	post_mat.set_shader_parameter("flash", 0.7)
	say("SHORT CIRCUIT! The fuse blew - entire house current is OFF! Reset at Main Breaker.", 6.0)
	# Preserve individual room switch states while the whole house loses power.
	# Lily flickers into existence during darkness!
	girl_flicker_t = 5.0

# -------------------------------------------------------------- main loop
func _physics_process(dt: float) -> void:
	time += dt
	if fan != null: fan.rotation.y += dt * 1.6
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
	if not house_power:
		for b in bulbs: (b.light as OmniLight3D).light_energy = 0.0
		return

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

func _animate_idle(_dt: float) -> void:
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

	if sprint: stamina = maxf(0.0, stamina - 0.22 * dt)
	else: stamina = minf(1.0, stamina + 0.14 * dt)

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

	# Flashlight logic
	if flash_on:
		battery = maxf(0.0, battery - 0.0042 * dt)
		if battery <= 0.0:
			flash_on = false
			flash.visible = false
		elif battery < 0.2:
			flash.light_energy = 6.0 * (1.0 if rng.randf() > 0.25 else 0.1)
		else: flash.light_energy = 6.0

	# First-person bat swing animation
	if bat_swinging:
		bat_swing_t -= dt
		if bat_swing_t <= 0.0:
			bat_swinging = false
			bat_in_hand.position = Vector3(0.3, -0.25, -0.45)
			bat_in_hand.rotation = Vector3(0.2, -0.4, 0.3)
		else:
			var swing_prog := 1.0 - (bat_swing_t / 0.35)
			bat_in_hand.position = Vector3(0.3 - sin(swing_prog * PI) * 0.4, -0.25 + sin(swing_prog * PI) * 0.2, -0.45 - sin(swing_prog * PI) * 0.3)
			bat_in_hand.rotation = Vector3(0.2 + swing_prog * 1.5, -0.4 - swing_prog * 1.2, 0.3 - swing_prog * 1.0)

	var eye := 1.0 if crouch else 1.62
	cam.position.y = lerpf(cam.position.y, eye + sin(time * 9.0) * 0.02 * float(moving), minf(1.0, 9.0 * dt))
	shake = maxf(0.0, shake - dt * 1.6)
	cam.rotation = Vector3(pitch + (rng.randf() - 0.5) * shake * 0.03, yaw, sin(time * 5.0) * 0.003 * float(moving))
	player.rotation = Vector3.ZERO

	# Check player death
	if health <= 0.0: _die()

func _update_ui(dt: float) -> void:
	hud_obj.text = "THE LAST REVENGE | Flashlight: %s | Bat: %s | Blood Bags: %d" % ["ON" if flash_on else "OFF", "EQUIPPED" if has_bat else "NONE", blood_bags]
	bar_health.value = health
	bar_stam.value = stamina
	bar_batt.value = battery

	# Build missions summary
	var m_str := "MISSIONS:\n"
	for m in missions:
		m_str += "%s %s\n" % ["[X]" if m.done else "[ ]", m.text]
	hud_missions.text = m_str

	var f = _find_focus()
	if f == null: hud_prompt.text = ""
	elif f.kind == "door":
		var d: MainDoor = f.door
		hud_prompt.text = "[E] %s %s%s" % ["Close" if d.target > 0.0 else "Open", d.label, " (LOCKED)" if d.locked else ""]
	else:
		hud_prompt.text = "[E] " + f.label

	if msg_t > 0.0:
		msg_t -= dt
		if msg_t <= 0.0: hud_msg.text = ""

	# Threat: Heartbeat + color drain scale with Butcher's proximity
	var dist_b := butcher.position.distance_to(player.position)
	var t := clampf(1.0 - dist_b / 14.0, 0.0, 1.0) if b_state != "patrol" or dist_b < 9.0 else 0.0
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
	if butcher_confined:
		var p_room: String = room_of.get(cell_key_at(player.position), {}).get("id", "")
		if p_room != "slaughter": return false
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
	if not house_power: return false
	for b in bulbs:
		if (b.pos as Vector3).distance_to(p) < 6.5 and b.mode != "off" and b.base > 0.0: return true
	return false

func _update_butcher(dt: float) -> void:
	if b_stun > 0.0:
		b_stun -= dt
		butcher.velocity = Vector3.ZERO
		return

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

	# Butcher kill attack
	if butcher.position.distance_to(player.position) < 1.1 and state == "play":
		health -= 100.0
		_die()

	# Presentation: Stride bob, lean, red eyes
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
	if butcher_confined:
		var s_cells := ["11,4", "11,5", "12,4", "12,5", "13,4", "13,5"]
		var dest: String = s_cells[rng.randi() % s_cells.size()]
		b_path = nav_path(cell_key_at(butcher.position), dest)
		if b_path.size() > 1: b_path.pop_front()
		return
	var keys := cells.keys()
	var pk: String = player_cell_bias(keys)
	b_path = nav_path(cell_key_at(butcher.position), pk)
	if b_path.size() > 1: b_path.pop_front()

func player_cell_bias(keys: Array) -> String:
	if rng.randf() < 0.4: return cell_key_at(player.position)
	return keys[rng.randi() % keys.size()]

func _walk_to(target: Vector3, speed: float, dt: float) -> void:
	var goal := target
	if b_state == "chase" or b_state == "investigate" or b_path.size() == 0:
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
			if dr.locked:
				b_path = []
				b_wait = 2.0
				butcher.velocity = Vector3.ZERO
				return
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
	# 1. Lily (Horror Girl - transparent coming and going motion)
	if girl_alive:
		if girl_flicker_t > 0.0:
			girl_flicker_t -= dt
			# Intense flickering with a translucent surface between appearances.
			girl.visible = (sin(time * 24.0) > 0.0)
			for apparition_mesh in girl_meshes:
				(apparition_mesh as MeshInstance3D).transparency = 0.48
		else:
			# Gentle coming and going transparent motion
			girl_alpha = 0.52 + sin(time * 2.0) * 0.32
			girl.visible = (girl_alpha > 0.3)
			for apparition_mesh in girl_meshes:
				(apparition_mesh as MeshInstance3D).transparency = 1.0 - girl_alpha

		var gd := girl.position.distance_to(player.position)
		var seen := _looking_at(girl.position) and _los(cam.global_position, girl.position + Vector3(0, 1.2, 0))
		var to_p := player.position - girl.position

		if not seen and gd < 18.0 and gd > 1.3:
			girl.position += Vector3(to_p.x, 0, to_p.z).normalized() * 1.2 * dt
			girl.rotation.y = lerp_angle(girl.rotation.y, atan2(to_p.x, to_p.z), minf(1.0, 4.0 * dt))

		if gd < 1.2:
			shake = 1.2
			post_mat.set_shader_parameter("flash", 0.5)
			play("stinger", -4.0)
			health = maxf(0.0, health - 15.0)
			say("Lily's ghostly cold hand tore into your chest (-15 HP)!")
			girl.position = Vector3(4.2, 0, 5.9)

	# 2. Pearl (Cursed Doll watches player & cries)
	var dd := player.position - doll.global_position
	doll.rotation.y = lerp_angle(doll.rotation.y, atan2(dd.x, dd.z), minf(1.0, 2.0 * dt))

	# 3. Ada (Ghost drifts through Living Room)
	if ghost_alive:
		ghost.position = Vector3(5.2 + sin(time * 0.5) * 1.4, 0.35 + sin(time * 1.2) * 0.1, 9.5 + cos(time * 0.4) * 1.8)
		ghost.rotation.y = time * 0.5 + PI / 2.0

	# 4. Mira (The Woman in Horror Corridor)
	if woman_alive:
		var wp := player.position - woman.position
		woman.rotation.y = atan2(wp.x, wp.z)

	# 5. Street Rat (Runs toward player and bites!)
	if rat_alive:
		var rd := rat.position.distance_to(player.position)
		if rd < 8.0:
			var rdir := (player.position - rat.position).normalized()
			rat.position += Vector3(rdir.x, 0, rdir.z) * 2.2 * dt
			rat.rotation.y = atan2(rdir.x, rdir.z)

		rat_bite_cd -= dt
		if rd < 0.9 and rat_bite_cd <= 0.0:
			rat_bite_cd = 2.5
			health = maxf(0.0, health - 5.0)
			play("rat_bite", 2.0)
			play("rat_squeak", 0.0)
			shake = 0.5
			post_mat.set_shader_parameter("flash", 0.25)
			say("The street rat bit your ankle! (-5 HP)", 3.0)

func _update_director(dt: float) -> void:
	# Periodic clock tick sound
	if clock != null and int(time) != int(time - dt):
		p_clock.stream = snd["clock_tick"]
		p_clock.play()

	# Random house fright events
	if rng.randf() < 0.003:
		play("door", -4.0)
		say("A door slammed in the darkness...", 3.0)
