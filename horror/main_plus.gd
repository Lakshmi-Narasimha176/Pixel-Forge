extends "res://horror/main.gd"
## THE LAST REVENGE - "Plus" layer on top of main.gd (main.gd is left untouched).
##
## Fixes and additions:
##  * Furniture that blocked doors (kitchen island, foyer table, study bookcase, living couch) moved.
##  * Player starts the run facing the house (old yaw faced the tunnel dead end).
##  * Wall-mounted room light switches. Flipping one ON shorts the whole house.
##  * Main breaker box mounted outside beside the tunnel-side entrance, with status lamp.
##  * Floating blood-wall slabs inside the house replaced by decals that sit ON the walls.
##  * Crying doll tears, more blood bags / raw meat, bath + corridor lights.
##  * Lots of extra 3D sound emitters and one-shots.
##  * Startup validator that reports any door whose approach lane is blocked.

# x, z, facing_x, facing_z, width, height, centre_y
const WALL_BLOOD := [
	[25.0, 7.16, 0.0, 1.0, 2.0, 2.0, 1.45],
	[26.84, 9.2, -1.0, 0.0, 2.0, 2.0, 1.5],
	[26.84, 11.8, -1.0, 0.0, 1.6, 1.8, 1.4],
	[21.9, 12.84, 0.0, -1.0, 1.8, 2.0, 1.5],
	[21.16, 8.2, 1.0, 0.0, 1.5, 1.8, 1.4],
	[7.0, 5.16, 0.0, 1.0, 1.8, 1.8, 1.4],
	[19.0, 5.16, 0.0, 1.0, 1.8, 1.8, 1.4],
	[10.0, 6.84, 0.0, -1.0, 1.6, 1.8, 1.4],
	[22.0, 6.84, 0.0, -1.0, 1.6, 1.8, 1.4],
	[1.16, 11.4, 1.0, 0.0, 2.0, 1.9, 1.4],
	[10.84, 8.0, -1.0, 0.0, 1.4, 1.8, 1.4],
	[6.0, 1.16, 0.0, 1.0, 1.8, 1.6, 1.5],
	[26.84, 3.0, -1.0, 0.0, 1.8, 1.8, 1.4],
	[14.0, 4.84, 0.0, -1.0, 1.6, 1.8, 1.4],
	[12.84, 2.0, -1.0, 0.0, 1.6, 1.8, 1.4],
	[20.84, 8.0, -1.0, 0.0, 1.4, 1.8, 1.4],
	[12.0, 12.84, 0.0, -1.0, 1.4, 1.8, 1.4],
]

# room id, label, x along wall, wall line coordinate (z), facing z (+1 / -1)
const SWITCHES := [
	["living", "Living Room Light Switch", 7.2, 7.0, 1.0],
	["bed", "Bedroom Light Switch", 5.4, 5.0, -1.0],
	["bath", "Bathroom Light Switch", 12.0, 5.0, -1.0],
	["study", "Study Light Switch", 14.2, 5.0, -1.0],
	["kitchen", "Kitchen Light Switch", 20.2, 5.0, -1.0],
	["dining", "Dining Room Light Switch", 20.0, 7.0, 1.0],
	["foyer", "Foyer Light Switch", 12.2, 7.0, 1.0],
	["slaughter", "Slaughterhouse Light Switch", 22.4, 7.0, 1.0],
]

# Free-standing blood-wall slabs that main.gd drops inside the rooms (they hide doorways).
const OLD_SLAB_POS := [
	Vector3(24.0, 0.0, 7.2), Vector3(25.8, 0.0, 10.0), Vector3(14.0, 0.0, 5.8), Vector3(8.0, 0.0, 7.8),
	Vector3(22.0, 0.0, 12.5), Vector3(26.4, 0.0, 8.5), Vector3(3.0, 0.0, 4.0), Vector3(17.0, 0.0, 4.0),
	Vector3(6.0, 0.0, 6.8), Vector3(12.0, 0.0, 6.8), Vector3(20.0, 0.0, 6.8), Vector3(4.0, 0.0, 11.8),
]
const OLD_TOILET_POS := Vector3(11.4, 0.0, 2.1)
const PICKUP_KINDS := ["bat_pickup", "walkie", "mira_key", "father_key", "meat", "bloodbag", "battery", "lore"]

var _splat_tex: Array = []
var _emitters: Array = []
var p_ada: AudioStreamPlayer3D
var p_mira: AudioStreamPlayer3D
var p_rat: AudioStreamPlayer3D
var p_lily_g: AudioStreamPlayer3D
var p_hum: AudioStreamPlayer3D
var _breaker_lever: MeshInstance3D
var _breaker_lamp_mat: StandardMaterial3D
var _breaker_light: OmniLight3D
var _bulb_glow: Array = []
var _tears: Array = []
var _door_amt := {}
var _prev_power := false
var _prev_health := 100.0
var _flicker_settle_t := 0.0
var _chime_t := 45.0
var _event_t := 30.0
var _giggle_t := 8.0
var _static_t := 0.0
var _wind_lp := 0.0

# ------------------------------------------------------------------ lifecycle
func _ready() -> void:
	super()
	_plus_ready()

func _plus_ready() -> void:
	_build_wall_blood()
	_fix_dressing()
	_build_tears()
	_build_emitters()
	_prev_health = health
	_validate_paths()

func _physics_process(dt: float) -> void:
	super(dt)
	_plus_update(dt)

func _reset_run() -> void:
	super()
	# Face the house (-Z), not the tunnel dead end.
	yaw = 0.0
	pitch = 0.0
	player.position = Vector3(18.0, 0.05, 23.5)
	# Rooms start dark; hall + corridor are on the main circuit only.
	for b in bulbs:
		b.mode = "on" if (b.room == "hall" or b.room == "corridor") else "off"

# ------------------------------------------------------------------ furniture
func _build_furniture() -> void:
	var wood := Color(0.2, 0.13, 0.08)
	var dark := Color(0.1, 0.07, 0.05)
	var steel := Color(0.45, 0.46, 0.47)
	block(6.0, 2.5, 1.5, 2.1, 0.5, Color(0.35, 0.34, 0.3))      # bed
	block(2.2, 1.65, 1.5, 0.8, 2.0, Color(0.12, 0.08, 0.06))    # wardrobe
	block(1.75, 4.6, 1.1, 0.45, 0.8, wood)                       # dresser (Pearl)
	block(11.5, 1.65, 1.7, 0.8, 0.6, Color(0.55, 0.55, 0.52))   # tub
	block(16.0, 2.4, 1.8, 0.8, 0.78, wood)                       # desk (bat lies on it)
	block(13.75, 2.2, 0.35, 1.2, 2.0, dark)                      # bookcase west
	block(18.8, 3.9, 0.35, 1.2, 2.0, dark)                       # bookcase east (was blocking study->kitchen door)
	block(23.4, 1.55, 5.0, 0.65, 0.9, wood)                      # kitchen counter
	block(24.9, 3.6, 0.9, 1.4, 0.9, Color(0.4, 0.42, 0.42))     # island (was blocking kitchen door)
	block(4.2, 8.0, 2.2, 0.9, 0.5, Color(0.33, 0.12, 0.13))     # couch (was blocking living door)
	block(19.0, 10.0, 1.0, 2.5, 0.75, wood)                      # dining table
	block(24.0, 10.0, 1.6, 0.9, 0.9, steel)                      # altar
	block(24.0, 12.5, 2.4, 0.7, 0.9, steel)
	block(16.2, 7.6, 1.2, 0.45, 0.8, wood)                       # foyer table (was blocking foyer door)
	block(26.0, 10.2, 0.9, 0.9, 0.9, steel)                      # table under the 2nd blood bag

func _add_battery(pos: Vector3) -> void:
	var remap := {
		Vector3(22.0, 0.94, 4.4): Vector3(24.9, 0.94, 3.6),
		Vector3(14.0, 0.84, 7.5): Vector3(16.6, 0.84, 7.6),
		Vector3(4.6, 0.6, 1.55): Vector3(6.2, 0.58, 3.0),
	}
	for k in remap:
		if (k as Vector3).is_equal_approx(pos):
			pos = remap[k]
	super(pos)

func _build_items() -> void:
	super()
	_extra_pickup("bloodbag", Vector3(5.6, 0.56, 3.3), 0.32, "bloodbag", "Collect Blood Bag")
	_extra_pickup("bloodbag", Vector3(15.8, 0.86, 7.6), 0.32, "bloodbag", "Collect Blood Bag")
	_extra_pickup("bloodbag", Vector3(22.9, 0.94, 12.5), 0.32, "bloodbag", "Collect Blood Bag")
	_extra_pickup("meat", Vector3(19.0, 0.78, 9.1), 0.65, "meat", "Eat Raw Meat (+15 HP)")
	_extra_pickup("meat", Vector3(12.0, 0.62, 1.7), 0.5, "meat", "Eat Raw Meat (+15 HP)")

func _extra_pickup(model_key: String, pos: Vector3, length: float, kind: String, label: String) -> void:
	var n := fit(model_key, 0.0, length)
	n.position = pos
	add_child(n)
	interact.append({"kind": kind, "node": n, "pos": pos, "label": label})

# ------------------------------------------------------------------ dressing fixes
func _fix_dressing() -> void:
	for c in get_children():
		if not (c is Node3D):
			continue
		var n3 := c as Node3D
		for p in OLD_SLAB_POS:
			if n3.position.is_equal_approx(p):
				n3.queue_free()
		if n3.position.is_equal_approx(OLD_TOILET_POS):
			# It overlapped the tub; move it to the NE corner and give it a small collider.
			n3.position = Vector3(12.2, 0.0, 2.9)
			add_box(Vector3(12.2, 1.0, 2.9), Vector3(1.0, 2.0, 1.0), 1, self)

func _make_splatter_texture(seed_v: int) -> ImageTexture:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for n in range(5 + int(r.randi() % 4)):
		var cx := r.randf_range(24.0, 104.0)
		var cy := r.randf_range(20.0, 70.0)
		var rad := r.randf_range(6.0, 18.0)
		for y in range(maxi(0, int(cy - rad)), mini(s, int(cy + rad) + 1)):
			for x in range(maxi(0, int(cx - rad)), mini(s, int(cx + rad) + 1)):
				var d := Vector2(x - cx, y - cy).length()
				if d <= rad * (0.75 + 0.25 * r.randf()):
					img.set_pixel(x, y, Color(0.30, 0.0, 0.01, 0.92))
		var dx := int(cx + r.randf_range(-rad * 0.4, rad * 0.4))
		var dlen := int(r.randf_range(18.0, 50.0))
		for y in range(int(cy), mini(s, int(cy) + dlen)):
			for x in range(maxi(0, dx - 1), mini(s, dx + 2)):
				img.set_pixel(x, y, Color(0.26, 0.0, 0.01, 0.9))
	return ImageTexture.create_from_image(img)

func _splat(i: int) -> ImageTexture:
	while _splat_tex.size() <= i:
		_splat_tex.append(_make_splatter_texture(100 + _splat_tex.size() * 37))
	return _splat_tex[i]

func _add_wall_blood(x: float, z: float, fx: float, fz: float, w: float, h: float, y: float, tex_i: int) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	mi.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = _splat(tex_i)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.25
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = Vector3(x, y, z)
	mi.rotation.y = atan2(fx, fz)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level_root.add_child(mi)

func _build_wall_blood() -> void:
	for i in WALL_BLOOD.size():
		var d: Array = WALL_BLOOD[i]
		_add_wall_blood(d[0], d[1], d[2], d[3], d[4], d[5], d[6], i % 4)

func _build_tears() -> void:
	for sx in [-0.04, 0.04]:
		var tear := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.012
		sm.height = 0.03
		tear.mesh = sm
		var tm := _mat(Color(0.5, 0.0, 0.02), 0.2)
		tm.emission_enabled = true
		tm.emission = Color(0.7, 0.0, 0.03)
		tear.material_override = tm
		tear.position = Vector3(sx, 0.4, 0.08)
		doll.add_child(tear)
		_tears.append(tear)
	var eyes := OmniLight3D.new()
	eyes.light_color = Color(1.0, 0.1, 0.08)
	eyes.light_energy = 0.35
	eyes.omni_range = 1.6
	eyes.position = Vector3(0.0, 0.4, 0.12)
	doll.add_child(eyes)

# ------------------------------------------------------------------ switches / breaker / bulbs
func _add_bulb(c: Vector3, room_id: String, energy: float) -> void:
	var l := OmniLight3D.new()
	l.position = Vector3(c.x, 2.5, c.z)
	l.light_color = Color(1.0, 0.82, 0.58)
	l.omni_range = 7.0
	l.light_energy = 1.6 * energy
	l.shadow_enabled = false
	level_root.add_child(l)
	var bulb_mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	bulb_mesh.mesh = sm
	var em := _mat(Color(1.0, 0.9, 0.6), 0.4)
	em.emission_enabled = true
	em.emission = Color(1.0, 0.8, 0.45)
	bulb_mesh.material_override = em
	bulb_mesh.position = Vector3(c.x, 2.45, c.z)
	level_root.add_child(bulb_mesh)
	var entry := {"light": l, "base": l.light_energy, "mode": "off", "t": 0.0, "pos": Vector3(c.x, 0.0, c.z), "room": room_id}
	bulbs.append(entry)
	_bulb_glow.append({"mat": em, "bulb": entry})

func _make_wall_switch(pos: Vector3, face_z: float) -> Dictionary:
	var root := Node3D.new()
	root.position = pos
	if face_z < 0.0:
		root.rotation.y = PI
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.14, 0.22, 0.03)
	plate.mesh = pm
	plate.material_override = _mat(Color(0.75, 0.72, 0.62), 0.6)
	root.add_child(plate)
	var lever := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.04, 0.09, 0.04)
	lever.mesh = lm
	lever.material_override = _mat(Color(0.8, 0.15, 0.1), 0.4, 0.4)
	lever.position = Vector3(0.0, 0.0, 0.035)
	lever.rotation.x = -0.55
	root.add_child(lever)
	add_child(root)
	return {"root": root, "lever": lever}

func _build_switches() -> void:
	_add_bulb(Vector3(11.0, 0.0, 3.0), "bath", 0.8)
	_add_bulb(Vector3(-4.5, 0.0, 6.0), "corridor", 0.6)
	_build_breaker_box()
	for sw in SWITCHES:
		var wall_z: float = sw[3]
		var face: float = sw[4]
		var pos := Vector3(sw[2], 1.35, wall_z + face * 0.15)
		var parts := _make_wall_switch(pos, face)
		interact.append({
			"kind": "room_switch",
			"room": sw[0],
			"node": parts.root,
			"lever": parts.lever,
			"pos": pos,
			"label": "Flip " + str(sw[1]),
			"on": false,
		})

func _build_breaker_box() -> void:
	# Outside, on the dining-room wall right beside the tunnel-side entrance door (x=18, z=13).
	var pos := Vector3(17.2, 1.3, 13.17)
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.5, 0.1)
	box.mesh = bm
	box.material_override = _mat(Color(0.22, 0.24, 0.22), 0.5, 0.6)
	root.add_child(box)
	_breaker_lever = MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.06, 0.22, 0.06)
	_breaker_lever.mesh = lm
	_breaker_lever.material_override = _mat(Color(0.85, 0.12, 0.08), 0.35, 0.5)
	_breaker_lever.position = Vector3(0.0, 0.0, 0.07)
	root.add_child(_breaker_lever)
	var lamp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.03
	sm.height = 0.06
	lamp.mesh = sm
	_breaker_lamp_mat = _mat(Color(1.0, 0.1, 0.05), 0.3)
	_breaker_lamp_mat.emission_enabled = true
	_breaker_lamp_mat.emission = Color(1.0, 0.1, 0.05)
	_breaker_lamp_mat.emission_energy_multiplier = 2.5
	lamp.material_override = _breaker_lamp_mat
	lamp.position = Vector3(0.11, 0.19, 0.06)
	root.add_child(lamp)
	_breaker_light = OmniLight3D.new()
	_breaker_light.light_color = Color(1.0, 0.1, 0.05)
	_breaker_light.light_energy = 0.6
	_breaker_light.omni_range = 3.5
	_breaker_light.position = Vector3(0.0, 0.2, 0.5)
	root.add_child(_breaker_light)
	interact.append({
		"kind": "main_switch",
		"node": root,
		"pos": pos + Vector3(0.0, 0.0, 0.1),
		"label": "Toggle Whole-House Main Breaker",
	})

func _sync_breaker() -> void:
	if _breaker_lever == null:
		return
	_breaker_lever.rotation.x = -0.6 if house_power else 0.6
	var c := Color(0.1, 1.0, 0.25) if house_power else Color(1.0, 0.1, 0.05)
	_breaker_lamp_mat.albedo_color = c
	_breaker_lamp_mat.emission = c
	_breaker_light.light_color = c

func _update_bulb_glow() -> void:
	for g in _bulb_glow:
		var lit: bool = house_power and g.bulb.mode != "off"
		(g.mat as StandardMaterial3D).emission_energy_multiplier = 1.0 if lit else 0.0

func _toggle_main_power() -> void:
	super()
	play("breaker", 2.0)

func _flip_room_switch(it: Dictionary) -> void:
	if not house_power:
		play("click", -4.0)
		say("There is no current. Reset the main breaker first.")
		return
	it.on = not it.on
	play("switch")
	var lever = it.get("lever", null)
	if lever != null:
		(lever as Node3D).rotation.x = 0.55 if it.on else -0.55
	for b in bulbs:
		if b.room == it.room:
			b.mode = "on" if it.on else "off"
	if it.on:
		_trigger_short_circuit()
	else:
		say("Light switch OFF.")

func _interact() -> void:
	var it = _find_focus()
	if it == null:
		return
	if it.kind == "room_switch":
		_flip_room_switch(it)
		return
	super()
	if PICKUP_KINDS.has(it.kind) and it.get("taken", false):
		play("pickup", -4.0)
		if it.kind == "bloodbag":
			play("squish", -2.0)

func _bat_attack() -> void:
	var before := [girl_alive, ghost_alive, woman_alive, rat_alive, b_stun]
	var was_ready := has_bat and not bat_swinging
	super()
	if not was_ready:
		return
	if before[0] != girl_alive or before[1] != ghost_alive or before[2] != woman_alive or before[3] != rat_alive or b_stun > before[4]:
		play("bat_hit", 2.0)

# ------------------------------------------------------------------ audio
func _w_clock(t: float, _d: float) -> float:
	var u := fmod(t, 0.5)
	var f := 1250.0 if t < 0.5 else 980.0
	return (rng.randf_range(-1.0, 1.0) * exp(-u * 260.0) * 0.5 + sin(TAU * f * u) * exp(-u * 90.0)) * 0.55

func _w_fan(t: float, _d: float) -> float:
	var rev := fmod(t, 0.6)
	var click := rng.randf_range(-1.0, 1.0) * exp(-rev * 70.0) * 0.45
	var whir := sin(TAU * 50.0 * t) * 0.18 + sin(TAU * 100.0 * t) * 0.08
	var squeak := sin(TAU * (950.0 + 260.0 * sin(TAU * t / 2.4)) * t) * 0.05 * (0.5 + 0.5 * sin(TAU * t / 1.2))
	return click + whir + squeak

func _w_cry(t: float, _d: float) -> float:
	var tl := fmod(t, 1.2)
	var u := minf(tl / 1.0, 1.0)
	var env := pow(maxf(0.0, sin(PI * u)), 1.4)
	var phase := TAU * (430.0 * tl + 170.0 * (1.0 - cos(PI * u)) / PI)
	var tone := sin(phase) + 0.45 * sin(phase * 2.0) + 0.2 * sin(phase * 3.0)
	var vib := 1.0 + 0.12 * sin(TAU * 7.0 * t)
	return tone * env * vib * 0.28 + rng.randf_range(-1.0, 1.0) * env * 0.02

func _w_whisper(t: float, _d: float) -> float:
	var trem := 0.5 + 0.5 * sin(TAU * 0.5 * t)
	return (rng.randf_range(-1.0, 1.0) * 0.10 + sin(TAU * 330.0 * t) * 0.05 + sin(TAU * 332.5 * t) * 0.05 + sin(TAU * 497.0 * t) * 0.03) * trem

func _w_mourn(t: float, _d: float) -> float:
	var f := 196.0 + 12.0 * sin(TAU * 0.25 * t)
	var env := 0.55 + 0.45 * sin(TAU * 0.25 * t - 1.0)
	return (sin(TAU * f * t) * 0.18 + sin(TAU * f * 2.01 * t) * 0.07) * env

func _w_giggle(t: float, _d: float) -> float:
	var burst := fmod(t, 0.16)
	var on := 1.0 if (burst < 0.09 and t < 0.8) else 0.0
	var f := 900.0 + 500.0 * sin(TAU * 3.0 * t) + 200.0 * (t / 0.8)
	return sin(TAU * f * t) * on * exp(-burst * 14.0) * 0.4

func _w_scurry(t: float, _d: float) -> float:
	var st := fmod(t, 1.0 / 14.0)
	return rng.randf_range(-1.0, 1.0) * exp(-st * 120.0) * 0.35 * (0.6 + 0.4 * sin(TAU * 3.0 * t))

func _w_chain(t: float, _d: float) -> float:
	var s := 0.5 + 0.5 * sin(TAU * 0.4 * t)
	var squeal := sin(TAU * (520.0 + 140.0 * sin(TAU * 0.8 * t)) * t) * 0.07 * s * s
	var clank := rng.randf_range(-1.0, 1.0) * exp(-fmod(t, 1.25) * 40.0) * 0.18
	return squeal + clank

func _w_drip(t: float, _d: float) -> float:
	var f := 1100.0 + 1400.0 * exp(-t * 60.0)
	return sin(TAU * f * t) * exp(-t * 45.0) * 0.45

func _w_wind(t: float, _d: float) -> float:
	_wind_lp = _wind_lp * 0.985 + rng.randf_range(-1.0, 1.0) * 0.015
	return _wind_lp * (3.2 + 1.6 * sin(TAU * t / 4.0))

func _w_hum50(t: float, _d: float) -> float:
	return (sin(TAU * 100.0 * t) * 0.18 + sin(TAU * 200.0 * t) * 0.06 + sin(TAU * 300.0 * t) * 0.03) * 0.7

func _w_static(t: float, _d: float) -> float:
	return rng.randf_range(-1.0, 1.0) * exp(-t * 7.0) * (0.5 + 0.5 * sin(TAU * 38.0 * t)) * 0.5

func _build_audio() -> void:
	super()
	# Synthesised fallbacks (always available) ...
	snd["clock_tick"] = _wav(_w_clock, 1.0)   # tick + tock inside one second; main.gd replays it every second
	snd["fan_creak"] = _wav(_w_fan, 2.4, true)
	snd["doll_cry"] = _wav(_w_cry, 3.6, true)
	snd["whisper"] = _wav(_w_whisper, 4.0, true)
	snd["mourn"] = _wav(_w_mourn, 4.0, true)
	snd["giggle"] = _wav(_w_giggle, 0.9)
	snd["scurry"] = _wav(_w_scurry, 1.0, true)
	snd["chain"] = _wav(_w_chain, 2.5, true)
	snd["drip"] = _wav(_w_drip, 2.3, true)
	snd["wind"] = _wav(_w_wind, 4.0, true)
	snd["power_hum"] = _wav(_w_hum50, 1.0, true)
	snd["static"] = _wav(_w_static, 0.5)
	snd["door_close"] = _wav(func(t, _d): return (sin(TAU * 70.0 * t) * exp(-t * 14.0) + rng.randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.6) * 0.8, 0.45)
	snd["creak"] = _wav(func(t, d): return sin(TAU * (210.0 + 140.0 * sin(t * 5.0) + 60.0 * t) * t) * sin(PI * t / d) * 0.3 + rng.randf_range(-1.0, 1.0) * 0.03, 0.9)
	snd["switch"] = _wav(func(t, _d): return (rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) + sin(TAU * 1800.0 * t) * exp(-t * 60.0) * 0.5) * 0.8, 0.12)
	snd["breaker"] = _wav(func(t, _d): return (sin(TAU * 60.0 * t) * exp(-t * 9.0) + rng.randf_range(-1.0, 1.0) * exp(-t * 30.0) * 0.7 + sin(TAU * 330.0 * t) * exp(-t * 22.0) * 0.4) * 0.9, 0.7)
	snd["bat_hit"] = _wav(func(t, _d): return (sin(TAU * 95.0 * t) * exp(-t * 16.0) + rng.randf_range(-1.0, 1.0) * exp(-t * 45.0)) * 0.95, 0.4)
	snd["hurt"] = _wav(func(t, _d): return (sin(TAU * 75.0 * t) * exp(-t * 12.0) + rng.randf_range(-1.0, 1.0) * exp(-t * 28.0) * 0.5) * 0.9, 0.35)
	snd["pickup"] = _wav(func(t, _d): return (sin(TAU * 520.0 * t) * exp(-t * 20.0) + sin(TAU * 780.0 * t) * exp(-t * 26.0) * 0.5) * 0.4, 0.25)
	snd["squish"] = _wav(func(t, _d): return sin(TAU * (180.0 - 120.0 * t) * t) * exp(-t * 14.0) * 0.8 + rng.randf_range(-1.0, 1.0) * exp(-t * 50.0) * 0.3, 0.3)
	snd["thump"] = _wav(func(t, _d): return (sin(TAU * 48.0 * t) * exp(-t * 7.0) + rng.randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.4) * 0.9, 0.6)
	snd["chime"] = _wav(func(t, _d): return (sin(TAU * 196.0 * t) + sin(TAU * 392.0 * t) * 0.5 + sin(TAU * 588.0 * t) * 0.25) * exp(-t * 1.1) * 0.45, 3.5)
	# ... replaced by the recorded library files when they exist.
	_recorded_sound("door", "res://assets/audio/interaction/doorOpen_1.ogg")
	_recorded_sound("door_close", "res://assets/audio/interaction/doorClose_1.ogg")
	_recorded_sound("creak", "res://assets/audio/interaction/creak2.ogg")
	_recorded_sound("switch", "res://assets/audio/ui/switch_003.ogg")
	_recorded_sound("breaker", "res://assets/audio/interaction/impactMetal_heavy_001.ogg")
	_recorded_sound("bat_hit", "res://assets/audio/melee/impactPunch_heavy_001.ogg")
	_recorded_sound("hurt", "res://assets/audio/melee/impactSoft_heavy_001.ogg")
	_recorded_sound("pickup", "res://assets/audio/interaction/bookPlace1.ogg")
	_recorded_sound("thump", "res://assets/audio/interaction/impactWood_heavy_002.ogg")
	_recorded_sound("chime", "res://assets/audio/ui/bong_001.ogg")
	# Re-point the 3D emitters main.gd already created at the improved streams.
	p_fan.stream = snd["fan_creak"]
	p_fan.play()
	p_doll_cry.stream = snd["doll_cry"]
	p_doll_cry.play()

func _emitter(parent: Node, stream_name: String, pos: Vector3, vol: float, unit: float, maxd: float, autoplay := true) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = snd[stream_name]
	p.volume_db = vol
	p.unit_size = unit
	p.max_distance = maxd
	p.position = pos
	parent.add_child(p)
	if autoplay:
		p.play()
	_emitters.append(p)
	return p

func _build_emitters() -> void:
	p_ada = _emitter(ghost, "whisper", Vector3(0, 1.2, 0), -7.0, 2.5, 14.0)
	p_mira = _emitter(woman, "mourn", Vector3(0, 1.3, 0), -6.0, 2.5, 16.0)
	_emitter(self, "chain", Vector3(24.5, 2.6, 10.5), -5.0, 2.5, 16.0)
	_emitter(self, "drip", Vector3(11.0, 1.8, 2.6), -3.0, 2.0, 12.0)
	_emitter(self, "wind", Vector3(18.0, 2.0, 16.0), -6.0, 6.0, 24.0)
	p_hum = _emitter(self, "power_hum", Vector3(17.2, 1.3, 13.4), -10.0, 1.5, 8.0)
	p_rat = _emitter(rat, "scurry", Vector3(0, 0.1, 0), -2.0, 1.5, 10.0, false)
	p_lily_g = _emitter(girl, "giggle", Vector3(0, 1.4, 0), -3.0, 3.0, 20.0, false)

# ------------------------------------------------------------------ per-frame
func _plus_update(dt: float) -> void:
	var paused := state != "play"
	for e in _emitters:
		(e as AudioStreamPlayer3D).stream_paused = paused or (e == p_hum and not house_power)
	if paused:
		return

	_sync_breaker()
	_update_bulb_glow()
	if house_power and not _prev_power:
		_flicker_settle_t = 3.2
	_prev_power = house_power
	if _flicker_settle_t > 0.0:
		_flicker_settle_t -= dt
		if _flicker_settle_t <= 0.0 and not has_bible:
			for b in bulbs:
				if b.mode == "flicker":
					b.mode = "on"

	# doors: thud when they finish closing
	for d in doors:
		var prev: float = _door_amt.get(d, 0.0)
		if d.kind == "door" and prev > 0.04 and d.amount <= 0.04 and d.target == 0.0:
			play_at("door_close", d.pos, 1.0)
		_door_amt[d] = d.amount

	# damage grunt
	if health < _prev_health - 0.5:
		play("hurt", -3.0)
	_prev_health = health

	# Pearl's blood tears
	var ph := fmod(time * 0.7, 1.0)
	for i in _tears.size():
		var tr := _tears[i] as MeshInstance3D
		var pp := fmod(ph + 0.5 * i, 1.0)
		tr.position.y = 0.41 - pp * 0.28
		tr.visible = not pearl_comforted

	# Lily's giggle
	_giggle_t -= dt
	if _giggle_t <= 0.0:
		_giggle_t = rng.randf_range(6.0, 12.0)
		if girl_alive and girl.position.distance_to(player.position) < 16.0:
			p_lily_g.play()

	# Walkie static gets worse when Lily is near
	if has_walkie and girl_alive and girl.visible:
		var gd := girl.position.distance_to(player.position)
		if gd < 9.0:
			_static_t -= dt
			if _static_t <= 0.0:
				_static_t = clampf(gd / 9.0, 0.25, 1.0) * 1.6
				play("static", -14.0 + (9.0 - gd))

	# Rat scurry only while it moves
	var rat_moving := rat_alive and Vector2(rat.velocity.x, rat.velocity.z).length() > 0.3
	if rat_moving and not p_rat.playing:
		p_rat.play()
	elif not rat_moving and p_rat.playing:
		p_rat.stop()

	# Freed spirits go quiet
	if not ghost_alive and p_ada.playing:
		p_ada.stop()
	if not woman_alive and p_mira.playing:
		p_mira.stop()

	# Wall-clock chime
	_chime_t -= dt
	if _chime_t <= 0.0:
		_chime_t = rng.randf_range(70.0, 110.0)
		if clock != null:
			play_at("chime", clock.global_position, -2.0)

	# Random house events
	_event_t -= dt
	if _event_t <= 0.0:
		_event_t = rng.randf_range(22.0, 45.0)
		var pos := Vector3(rng.randf_range(2.0, 26.0), 1.2, rng.randf_range(2.0, 12.0))
		match rng.randi() % 3:
			0:
				play_at("creak", pos, -4.0)
			1:
				play_at("thump", pos, -2.0)
			_:
				if girl_alive:
					play_at("giggle", pos, -6.0)

# ------------------------------------------------------------------ validator
func _validate_paths() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var bad := PackedStringArray()
	var checked := 0
	for d in doors:
		if d.kind != "door":
			continue
		var n := Vector3(sin(d.rot), 0.0, cos(d.rot))
		for side in [-1.0, 1.0]:
			var shape := CapsuleShape3D.new()
			shape.radius = 0.28
			shape.height = 1.7
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = shape
			q.collision_mask = 1
			q.transform = Transform3D(Basis.IDENTITY, Vector3(d.pos.x, 0.95, d.pos.z) + n * side * 0.85)
			checked += 1
			if not space.intersect_shape(q, 1).is_empty():
				bad.append("%s (%s side)" % [d.label, "+" if side > 0.0 else "-"])
	if bad.size() > 0:
		push_warning("[PathCheck] Blocked door lanes: " + ", ".join(bad))
		print("[PathCheck] Blocked door lanes: ", ", ".join(bad))
		hud_warn.text += "  PathCheck: %d blocked door lane(s) - see Output." % bad.size()
	else:
		print("[PathCheck] All %d door approach lanes are clear." % checked)
