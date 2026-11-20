extends RefCounted
## Procedural stand-ins for every model and every house-kit piece used by THE LAST REVENGE.
## main_plus.gd uses these ONLY when the real .glb file is missing or is an un-pulled Git LFS stub,
## so the game is always complete and playable. Real assets win automatically when they load.
##
## Orientation convention: characters face +Z, flashlight points +Z, clock face is on +Z.
## Kit pieces: the wall plane sits at local z = -1 (cell edge), cell origin at the centre.

static var _mats := {}
static var _texs := {}

# ------------------------------------------------------------------ textures / materials
static func _hash(x: int, y: int) -> float:
	return fposmod(sin(float(x) * 127.1 + float(y) * 311.7) * 43758.5453, 1.0)

static func _texel(kind: String, x: int, y: int) -> Color:
	var n := _hash(x, y) * 0.06
	var c := Color(0.3, 0.3, 0.3)
	if kind == "sprig":
		c = Color(0.30, 0.38, 0.30)
		if x % 16 < 2:
			c = Color(0.22, 0.30, 0.22)
		if absi((x % 32) - 16) + absi((y % 32) - 16) < 4:
			c = Color(0.52, 0.58, 0.42)
	elif kind == "floral":
		c = Color(0.42, 0.33, 0.30)
		if x % 16 < 2:
			c = Color(0.33, 0.25, 0.23)
		if absi((x % 32) - 16) + absi((y % 32) - 16) < 5:
			c = Color(0.62, 0.34, 0.34)
	elif kind == "floor":
		var row := floori(y / 16.0)
		var shade := 0.85 + _hash(row, 7) * 0.3
		c = Color(0.30 * shade, 0.20 * shade, 0.12 * shade)
		if y % 16 < 1 or x == int(_hash(row, 3) * 64.0):
			c = Color(0.08, 0.05, 0.03)
	return Color(c.r + n, c.g + n, c.b + n, 1.0)

static func _tex(kind: String) -> ImageTexture:
	if _texs.has(kind):
		return _texs[kind]
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			img.set_pixel(x, y, _texel(kind, x, y))
	var t := ImageTexture.create_from_image(img)
	_texs[kind] = t
	return t

static func _std(c: Color, rough := 0.85, metal := 0.0, emit := 0.0, alpha := 1.0) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(c.r, c.g, c.b, alpha)
	mt.roughness = rough
	mt.metallic = metal
	if emit > 0.0:
		mt.emission_enabled = true
		mt.emission = c
		mt.emission_energy_multiplier = emit
	if alpha < 1.0:
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mt

static func _kmat(key: String) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var mt := StandardMaterial3D.new()
	if key == "sprig" or key == "floral":
		mt.albedo_texture = _tex(key)
		mt.uv1_scale = Vector3(4.0, 3.0, 1.0)
		mt.roughness = 0.95
	elif key == "floor":
		mt.albedo_texture = _tex("floor")
		mt.uv1_scale = Vector3(2.0, 2.0, 1.0)
		mt.roughness = 0.6
	elif key == "ceiling":
		mt.albedo_color = Color(0.32, 0.31, 0.28)
		mt.roughness = 1.0
	elif key == "wood":
		mt.albedo_color = Color(0.22, 0.14, 0.09)
		mt.roughness = 0.7
	elif key == "glass":
		mt.albedo_color = Color(0.5, 0.65, 0.8, 0.22)
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mt.roughness = 0.1
	elif key == "concrete":
		mt.albedo_color = Color(0.26, 0.27, 0.28)
		mt.roughness = 1.0
	elif key == "brick":
		mt.albedo_color = Color(0.22, 0.17, 0.15)
		mt.roughness = 1.0
	else:
		mt.albedo_color = Color(0.5, 0.5, 0.5)
	_mats[key] = mt
	return mt

# ------------------------------------------------------------------ primitives
static func box(parent: Node3D, size: Vector3, pos: Vector3, mt: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mt
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mt: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mt
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func sph(parent: Node3D, r: float, pos: Vector3, mt: Material, sq := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mt
	mi.position = pos
	mi.scale = sq
	parent.add_child(mi)
	return mi

static func cap(parent: Node3D, r: float, h: float, pos: Vector3, mt: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0 + 0.001)
	cm.radial_segments = 8
	mi.mesh = cm
	mi.material_override = mt
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

# ------------------------------------------------------------------ house kit pieces
static func _wainscot(root: Node3D, w: float, cx: float, y0: float, h: float) -> void:
	var wd := _kmat("wood")
	for sz in [-1.11, -0.89]:
		box(root, Vector3(w, h, 0.04), Vector3(cx, y0 + h * 0.5, sz), wd)

static func _wall(root: Node3D, mk: String, opening: int) -> void:
	var wp := _kmat(mk)
	var wd := _kmat("wood")
	var z := -1.0
	if opening == 0:
		box(root, Vector3(2.0, 3.0, 0.2), Vector3(0, 1.5, z), wp)
		_wainscot(root, 2.0, 0.0, 0.0, 1.0)
	elif opening == 1:
		box(root, Vector3(0.5, 3.0, 0.2), Vector3(-0.75, 1.5, z), wp)
		box(root, Vector3(0.5, 3.0, 0.2), Vector3(0.75, 1.5, z), wp)
		box(root, Vector3(1.0, 0.7, 0.2), Vector3(0, 2.65, z), wp)
		box(root, Vector3(0.06, 2.3, 0.26), Vector3(-0.5, 1.15, z), wd)
		box(root, Vector3(0.06, 2.3, 0.26), Vector3(0.5, 1.15, z), wd)
		box(root, Vector3(1.06, 0.06, 0.26), Vector3(0, 2.3, z), wd)
		_wainscot(root, 0.5, -0.75, 0.0, 1.0)
		_wainscot(root, 0.5, 0.75, 0.0, 1.0)
	else:
		box(root, Vector3(0.5, 3.0, 0.2), Vector3(-0.75, 1.5, z), wp)
		box(root, Vector3(0.5, 3.0, 0.2), Vector3(0.75, 1.5, z), wp)
		box(root, Vector3(1.0, 1.0, 0.2), Vector3(0, 0.5, z), wp)
		box(root, Vector3(1.0, 1.0, 0.2), Vector3(0, 2.5, z), wp)
		_wainscot(root, 2.0, 0.0, 0.0, 1.0)

static func _window(root: Node3D) -> void:
	var wd := _kmat("wood")
	var z := -1.0
	box(root, Vector3(0.05, 1.05, 0.24), Vector3(-0.5, 1.5, z), wd)
	box(root, Vector3(0.05, 1.05, 0.24), Vector3(0.5, 1.5, z), wd)
	box(root, Vector3(1.05, 0.05, 0.24), Vector3(0, 2.0, z), wd)
	box(root, Vector3(1.05, 0.05, 0.24), Vector3(0, 1.0, z), wd)
	box(root, Vector3(0.03, 1.0, 0.1), Vector3(0, 1.5, z), wd)
	box(root, Vector3(1.0, 0.03, 0.1), Vector3(0, 1.5, z), wd)
	box(root, Vector3(0.96, 0.96, 0.01), Vector3(0, 1.5, z), _kmat("glass"))

static func _door_leaf(root: Node3D) -> void:
	var paint := _std(Color(0.78, 0.76, 0.70), 0.7)
	var inset := _std(Color(0.62, 0.60, 0.55), 0.8)
	var metal := _std(Color(0.55, 0.5, 0.35), 0.3, 0.8)
	box(root, Vector3(0.96, 2.1, 0.05), Vector3(0, 1.05, -1.0), paint)
	for yy in [0.55, 1.55]:
		box(root, Vector3(0.7, 0.8, 0.012), Vector3(0, yy, -1.03), inset)
		box(root, Vector3(0.7, 0.8, 0.012), Vector3(0, yy, -0.97), inset)
	sph(root, 0.03, Vector3(0.36, 1.0, -1.06), metal)
	sph(root, 0.03, Vector3(0.36, 1.0, -0.94), metal)

static func kit_piece(piece_name: String) -> Node3D:
	var root := Node3D.new()
	match piece_name:
		"house_wall":
			_wall(root, "sprig", 0)
		"house_wall_floral":
			_wall(root, "floral", 0)
		"house_wall_door":
			_wall(root, "sprig", 1)
		"house_wall_window":
			_wall(root, "sprig", 2)
		"house_window":
			_window(root)
		"house_door":
			_door_leaf(root)
		"house_corner":
			box(root, Vector3(0.3, 3.0, 0.3), Vector3(0, 1.5, 0), _kmat("wood"))
		"house_floor":
			box(root, Vector3(2.0, 0.08, 2.0), Vector3(0, -0.06, 0), _kmat("floor"))
		"house_ceiling":
			box(root, Vector3(2.0, 0.1, 2.0), Vector3(0, 3.05, 0), _kmat("ceiling"))
		"house_ceiling_light":
			box(root, Vector3(2.0, 0.1, 2.0), Vector3(0, 3.05, 0), _kmat("ceiling"))
			cyl(root, 0.03, 0.03, 0.25, Vector3(0, 2.9, 0), _std(Color(0.1, 0.1, 0.1)))
			sph(root, 0.09, Vector3(0, 2.75, 0), _std(Color(1.0, 0.85, 0.55), 0.4, 0.0, 1.5), Vector3(1, 1.2, 1))
		_:
			box(root, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), _std(Color(0.5, 0.1, 0.1)))
	return root

# ------------------------------------------------------------------ characters
static func _human(root: Node3D, h: float, bulk: float, skin: Color, cloth: Color, hair: Color, dress: bool, alpha := 1.0, emit := 0.0) -> void:
	var sk := _std(skin, 0.7, 0.0, emit, alpha)
	var cl := _std(cloth, 0.9, 0.0, emit, alpha)
	var hr := _std(hair, 0.9, 0.0, 0.0, alpha)
	var eye := _std(Color(1.0, 0.1, 0.05), 0.3, 0.0, 2.0)
	var leg_h := h * 0.46
	var torso_h := h * 0.30
	var head_r := h * 0.075
	if dress:
		cyl(root, bulk * 0.17, bulk * 0.36, h * 0.52, Vector3(0, h * 0.30, 0), cl)
	else:
		for sx in [-1.0, 1.0]:
			cyl(root, bulk * 0.07, bulk * 0.06, leg_h, Vector3(sx * bulk * 0.1, leg_h * 0.5, 0), cl)
	box(root, Vector3(bulk * 0.46, torso_h, bulk * 0.26), Vector3(0, leg_h + torso_h * 0.5, 0), cl)
	for sx in [-1.0, 1.0]:
		cyl(root, bulk * 0.05, bulk * 0.04, torso_h * 1.1, Vector3(sx * bulk * 0.3, leg_h + torso_h * 0.45, 0), sk, Vector3(0, 0, sx * 6.0))
	var head_y := leg_h + torso_h + head_r * 1.1
	sph(root, head_r, Vector3(0, head_y, 0), sk, Vector3(0.9, 1.1, 1.0))
	sph(root, head_r * 1.08, Vector3(0, head_y + head_r * 0.15, -head_r * 0.25), hr)
	for sx in [-1.0, 1.0]:
		sph(root, head_r * 0.12, Vector3(sx * head_r * 0.35, head_y, head_r * 0.85), eye)

static func _butcher(root: Node3D) -> void:
	_human(root, 1.95, 1.5, Color(0.75, 0.55, 0.5), Color(0.30, 0.10, 0.09), Color(0.75, 0.55, 0.5), false)
	var apron := _std(Color(0.78, 0.74, 0.68), 0.9)
	var blood := _std(Color(0.4, 0.0, 0.02), 0.3)
	box(root, Vector3(0.62, 0.95, 0.04), Vector3(0, 1.05, 0.2), apron)
	for p in [Vector3(-0.15, 1.2, 0.225), Vector3(0.12, 0.95, 0.225), Vector3(0.0, 0.75, 0.225)]:
		box(root, Vector3(0.18, 0.2, 0.01), p, blood)
	sph(root, 0.34, Vector3(0, 1.0, 0.04), _std(Color(0.30, 0.10, 0.09)), Vector3(1.0, 0.9, 0.85))
	# cleaver in the right hand
	cyl(root, 0.025, 0.025, 0.28, Vector3(0.46, 0.9, 0.3), _std(Color(0.2, 0.12, 0.08)), Vector3(90, 0, 0))
	box(root, Vector3(0.03, 0.26, 0.3), Vector3(0.46, 0.86, 0.58), _std(Color(0.6, 0.62, 0.65), 0.3, 0.9))
	box(root, Vector3(0.032, 0.1, 0.12), Vector3(0.46, 0.82, 0.66), blood)

static func _ghost(root: Node3D) -> void:
	_human(root, 1.7, 0.9, Color(0.82, 0.86, 0.92), Color(0.86, 0.9, 0.97), Color(0.08, 0.07, 0.1), true, 0.6, 0.7)
	var blood := _std(Color(0.5, 0.0, 0.02), 0.3)
	box(root, Vector3(0.22, 0.3, 0.012), Vector3(0.05, 1.1, 0.14), blood)
	box(root, Vector3(0.3, 0.4, 0.012), Vector3(-0.1, 0.6, 0.3), blood)
	box(root, Vector3(0.1, 0.5, 0.012), Vector3(0.2, 0.5, 0.32), blood)
	box(root, Vector3(0.36, 0.5, 0.06), Vector3(0, 1.25, -0.12), _std(Color(0.08, 0.07, 0.1), 0.9, 0.0, 0.0, 0.7))

static func _woman(root: Node3D) -> void:
	_human(root, 1.7, 1.0, Color(0.85, 0.75, 0.7), Color(0.12, 0.10, 0.14), Color(0.04, 0.03, 0.03), true)
	box(root, Vector3(0.42, 0.55, 0.07), Vector3(0, 1.2, -0.14), _std(Color(0.04, 0.03, 0.03), 0.9))
	box(root, Vector3(0.5, 0.18, 0.3), Vector3(0, 1.28, 0.0), _std(Color(0.25, 0.1, 0.12), 0.9))

static func _girl(root: Node3D) -> void:
	_human(root, 1.5, 0.8, Color(0.82, 0.85, 0.88), Color(0.86, 0.86, 0.8), Color(0.02, 0.02, 0.03), true)
	box(root, Vector3(0.24, 0.42, 0.04), Vector3(0, 1.1, 0.12), _std(Color(0.02, 0.02, 0.03), 0.9))
	box(root, Vector3(0.3, 0.7, 0.05), Vector3(0, 0.9, -0.1), _std(Color(0.02, 0.02, 0.03), 0.9))

static func _rat(root: Node3D) -> void:
	var fur := _std(Color(0.25, 0.22, 0.2), 1.0)
	var skin := _std(Color(0.55, 0.4, 0.4), 0.9)
	cap(root, 0.07, 0.3, Vector3(0, 0.09, 0), fur, Vector3(90, 0, 0))
	sph(root, 0.055, Vector3(0, 0.1, 0.19), fur, Vector3(0.9, 0.9, 1.4))
	cyl(root, 0.0, 0.03, 0.06, Vector3(0, 0.1, 0.27), skin, Vector3(90, 0, 0))
	for sx in [-1.0, 1.0]:
		sph(root, 0.03, Vector3(sx * 0.04, 0.16, 0.15), skin, Vector3(1, 1, 0.3))
		sph(root, 0.01, Vector3(sx * 0.03, 0.125, 0.235), _std(Color(1, 0.1, 0.05), 0.3, 0.0, 2.5))
		cyl(root, 0.012, 0.012, 0.05, Vector3(sx * 0.05, 0.025, 0.08), skin)
		cyl(root, 0.012, 0.012, 0.05, Vector3(sx * 0.05, 0.025, -0.08), skin)
	cyl(root, 0.004, 0.012, 0.28, Vector3(0, 0.07, -0.3), skin, Vector3(80, 0, 0))

static func _doll(root: Node3D) -> void:
	var porcelain := _std(Color(0.92, 0.9, 0.85), 0.3)
	var dress := _std(Color(0.75, 0.68, 0.5), 0.9)
	var black := _std(Color(0.03, 0.02, 0.02), 0.9)
	var eye := _std(Color(1.0, 0.1, 0.08), 0.3, 0.0, 2.0)
	cyl(root, 0.05, 0.14, 0.32, Vector3(0, 0.22, 0), dress)
	for sx in [-1.0, 1.0]:
		cyl(root, 0.025, 0.02, 0.1, Vector3(sx * 0.05, 0.04, 0), porcelain)
		cyl(root, 0.02, 0.018, 0.2, Vector3(sx * 0.1, 0.27, 0), porcelain, Vector3(0, 0, sx * 20.0))
		sph(root, 0.014, Vector3(sx * 0.035, 0.465, 0.082), eye)
	sph(root, 0.09, Vector3(0, 0.46, 0), porcelain)
	sph(root, 0.096, Vector3(0, 0.49, -0.02), black, Vector3(1, 0.85, 1))
	box(root, Vector3(0.004, 0.07, 0.004), Vector3(0.02, 0.48, 0.09), black, Vector3(0, 0, 25))

# ------------------------------------------------------------------ props
static func _flashlight(root: Node3D) -> void:
	var body := _std(Color(0.12, 0.12, 0.13), 0.4, 0.8)
	cyl(root, 0.022, 0.022, 0.18, Vector3(0, 0, -0.03), body, Vector3(90, 0, 0))
	cyl(root, 0.036, 0.024, 0.07, Vector3(0, 0, 0.09), body, Vector3(90, 0, 0))
	cyl(root, 0.03, 0.03, 0.004, Vector3(0, 0, 0.126), _std(Color(1.0, 0.95, 0.8), 0.2, 0.0, 2.0), Vector3(90, 0, 0))

static func _walkie(root: Node3D) -> void:
	var shell := _std(Color(0.15, 0.2, 0.15), 0.7)
	box(root, Vector3(0.07, 0.13, 0.03), Vector3(0, 0.065, 0), shell)
	cyl(root, 0.006, 0.006, 0.09, Vector3(0.025, 0.17, 0), _std(Color(0.05, 0.05, 0.05)))
	box(root, Vector3(0.05, 0.04, 0.005), Vector3(0, 0.1, 0.017), _std(Color(0.05, 0.05, 0.05)))
	cyl(root, 0.011, 0.011, 0.015, Vector3(-0.02, 0.14, 0.0), _std(Color(0.7, 0.1, 0.1)))

static func _bible(root: Node3D) -> void:
	box(root, Vector3(0.2, 0.045, 0.28), Vector3(0, 0.0225, 0), _std(Color(0.05, 0.04, 0.04), 0.6))
	box(root, Vector3(0.012, 0.047, 0.28), Vector3(-0.095, 0.0235, 0), _std(Color(0.18, 0.02, 0.02), 0.5))
	var cross := _std(Color(0.9, 0.05, 0.03), 0.3, 0.0, 2.0)
	box(root, Vector3(0.02, 0.003, 0.14), Vector3(0.0, 0.047, 0.0), cross)
	box(root, Vector3(0.09, 0.003, 0.02), Vector3(0.0, 0.047, -0.03), cross)

static func _bat(root: Node3D) -> void:
	var wood := _std(Color(0.45, 0.3, 0.17), 0.6)
	cyl(root, 0.045, 0.02, 0.62, Vector3(0, 0.55, 0), wood)
	cyl(root, 0.02, 0.026, 0.25, Vector3(0, 0.13, 0), wood)
	cyl(root, 0.027, 0.027, 0.18, Vector3(0, 0.12, 0), _std(Color(0.05, 0.05, 0.05), 0.9))
	sph(root, 0.03, Vector3(0, 0.0, 0), wood)
	var blood := _std(Color(0.35, 0.0, 0.02), 0.3)
	sph(root, 0.047, Vector3(0, 0.62, 0.0), blood, Vector3(1.0, 0.8, 1.0))
	sph(root, 0.04, Vector3(0.0, 0.45, 0.0), blood, Vector3(1.0, 0.5, 1.0))
	box(root, Vector3(0.012, 0.03, 0.012), Vector3(0.045, 0.68, 0.0), _std(Color(0.5, 0.5, 0.5), 0.4, 0.9))

static func _pig(root: Node3D) -> void:
	var pink := _std(Color(0.78, 0.52, 0.48), 0.8)
	var red := _std(Color(0.45, 0.02, 0.03), 0.4)
	cyl(root, 0.01, 0.01, 0.3, Vector3(0, 1.1, 0), _std(Color(0.2, 0.15, 0.1)))
	cap(root, 0.2, 0.85, Vector3(0, 0.62, 0), pink)
	sph(root, 0.13, Vector3(0, 0.18, 0.03), pink, Vector3(1, 0.9, 1.2))
	sph(root, 0.05, Vector3(0, 0.12, 0.14), _std(Color(0.9, 0.6, 0.6), 0.7), Vector3(1.2, 0.8, 0.6))
	for sx in [-1.0, 1.0]:
		cyl(root, 0.03, 0.04, 0.2, Vector3(sx * 0.12, 0.98, 0.0), pink, Vector3(0, 0, sx * 14.0))
		sph(root, 0.045, Vector3(sx * 0.1, 0.26, 0.0), pink, Vector3(0.6, 1.2, 0.3))
	box(root, Vector3(0.1, 0.5, 0.02), Vector3(0, 0.6, 0.19), red)

static func _meat(root: Node3D) -> void:
	box(root, Vector3(0.34, 0.015, 0.26), Vector3(0, 0.0075, 0), _std(Color(0.9, 0.9, 0.88), 0.4))
	box(root, Vector3(0.3, 0.06, 0.2), Vector3(0, 0.045, 0), _std(Color(0.62, 0.08, 0.08), 0.35))
	box(root, Vector3(0.22, 0.015, 0.1), Vector3(0.0, 0.08, 0.02), _std(Color(0.85, 0.7, 0.65), 0.5))
	box(root, Vector3(0.12, 0.05, 0.1), Vector3(0.1, 0.07, -0.03), _std(Color(0.5, 0.05, 0.06), 0.35))

static func _bloodbag(root: Node3D) -> void:
	var bag := _std(Color(0.5, 0.0, 0.03), 0.2, 0.0, 0.0, 0.88)
	sph(root, 0.1, Vector3(0, 0.1, 0), bag, Vector3(0.8, 1.0, 0.28))
	cyl(root, 0.012, 0.012, 0.03, Vector3(0, 0.215, 0), _std(Color(0.9, 0.9, 0.9), 0.4))
	cyl(root, 0.005, 0.005, 0.12, Vector3(0.04, 0.0, 0.0), _std(Color(0.8, 0.85, 0.8), 0.3, 0.0, 0.0, 0.6), Vector3(0, 0, 70))

static func _clock(root: Node3D) -> void:
	var wood := _std(Color(0.3, 0.18, 0.1), 0.6)
	var face := _std(Color(0.88, 0.84, 0.7), 0.5)
	var dark := _std(Color(0.05, 0.04, 0.04))
	box(root, Vector3(0.34, 0.7, 0.1), Vector3(0, 0.35, 0), wood)
	cyl(root, 0.14, 0.14, 0.02, Vector3(0, 0.52, 0.055), face, Vector3(90, 0, 0))
	box(root, Vector3(0.012, 0.1, 0.01), Vector3(0, 0.56, 0.07), dark)
	box(root, Vector3(0.08, 0.012, 0.01), Vector3(0.03, 0.52, 0.07), dark, Vector3(0, 0, 25))
	box(root, Vector3(0.2, 0.22, 0.01), Vector3(0, 0.18, 0.052), _std(Color(0.12, 0.07, 0.04)))
	cyl(root, 0.003, 0.003, 0.16, Vector3(0, 0.18, 0.06), _std(Color(0.7, 0.55, 0.2), 0.3, 0.9))
	sph(root, 0.04, Vector3(0, 0.1, 0.06), _std(Color(0.7, 0.55, 0.2), 0.3, 0.9), Vector3(1, 1, 0.3))

static func _fan(root: Node3D) -> void:
	var rust := _std(Color(0.36, 0.2, 0.1), 0.9, 0.6)
	var dark := _std(Color(0.12, 0.08, 0.06), 0.8, 0.5)
	cyl(root, 0.012, 0.012, 0.3, Vector3(0, 0.45, 0), dark)
	cyl(root, 0.1, 0.12, 0.12, Vector3(0, 0.24, 0), rust)
	for i in 4:
		var a := float(i) * 90.0
		var holder := Node3D.new()
		holder.rotation_degrees = Vector3(0, a, 0)
		root.add_child(holder)
		box(holder, Vector3(0.5, 0.012, 0.13), Vector3(0.38, 0.2, 0.0), rust, Vector3(0, 0, -6))
		box(holder, Vector3(0.12, 0.01, 0.02), Vector3(0.12, 0.215, 0.0), dark)

static func _toilet(root: Node3D) -> void:
	var plank := _std(Color(0.28, 0.2, 0.12), 0.95)
	var dark := _std(Color(0.1, 0.07, 0.05), 0.95)
	for sx in [-0.5, 0.5]:
		box(root, Vector3(0.06, 2.0, 1.0), Vector3(sx, 1.0, 0), plank)
	box(root, Vector3(1.0, 2.0, 0.06), Vector3(0, 1.0, -0.5), plank)
	box(root, Vector3(0.44, 1.8, 0.04), Vector3(-0.25, 0.95, 0.5), plank)
	box(root, Vector3(0.44, 1.8, 0.04), Vector3(0.25, 0.95, 0.5), dark)
	box(root, Vector3(0.06, 0.12, 0.05), Vector3(0.0, 1.5, 0.53), dark)
	box(root, Vector3(1.3, 0.06, 1.2), Vector3(0, 2.15, 0.0), plank, Vector3(-8, 0, 0))
	box(root, Vector3(0.8, 0.45, 0.8), Vector3(0, 0.22, -0.05), dark)

static func _hook(root: Node3D) -> void:
	var steel := _std(Color(0.35, 0.36, 0.38), 0.4, 0.9)
	var ham := _std(Color(0.45, 0.14, 0.1), 0.6)
	var saus := _std(Color(0.4, 0.15, 0.1), 0.7)
	box(root, Vector3(3.4, 0.06, 0.1), Vector3(0, 0.72, 0), steel)
	for i in 6:
		var x := -1.4 + float(i) * 0.56
		cyl(root, 0.006, 0.006, 0.2, Vector3(x, 0.6, 0), steel)
		if i % 2 == 0:
			sph(root, 0.12, Vector3(x, 0.4, 0), ham, Vector3(1.0, 1.4, 0.9))
		else:
			cap(root, 0.04, 0.4, Vector3(x, 0.4, 0), saus)

# ------------------------------------------------------------------ big environment pieces
static func _corridor(root: Node3D) -> void:
	# along local Z (18 long), 2.4 wide, 2.8 high
	var paper := _kmat("floral")
	var wd := _kmat("wood")
	var dark := _std(Color(0.08, 0.06, 0.05), 0.9)
	var blood := _std(Color(0.3, 0.0, 0.02), 0.3)
	box(root, Vector3(2.4, 0.05, 18.0), Vector3(0, -0.025, 0), _kmat("floor"))
	box(root, Vector3(2.4, 0.08, 18.0), Vector3(0, 2.84, 0), _kmat("ceiling"))
	for sx in [-1.2, 1.2]:
		box(root, Vector3(0.1, 2.8, 18.0), Vector3(sx, 1.4, 0), paper)
		box(root, Vector3(0.04, 0.9, 18.0), Vector3(sx * 0.96, 0.45, 0), wd)
	box(root, Vector3(2.4, 2.8, 0.1), Vector3(0, 1.4, -9.0), paper)
	for i in 6:
		var z := -7.0 + float(i) * 2.8
		var sx := -1.14 if i % 2 == 0 else 1.14
		box(root, Vector3(0.04, 0.5, 0.38), Vector3(sx, 1.7, z), wd)
		box(root, Vector3(0.03, 0.4, 0.28), Vector3(sx * 0.995, 1.7, z), dark)
		box(root, Vector3(0.05, 0.14, 0.1), Vector3(-sx * 0.98, 2.2, z + 1.2), _std(Color(1.0, 0.8, 0.45), 0.4, 0.0, 1.2))
	for z in [-3.0, 2.0, 6.5]:
		box(root, Vector3(0.012, 0.6, 0.5), Vector3(1.14, 1.2, z), blood)
		box(root, Vector3(0.012, 0.9, 0.1), Vector3(1.14, 0.8, z + 0.1), blood)

static func _tunnel(root: Node3D) -> void:
	# along local X (14 long), 2.6 wide, 3.2 high
	var conc := _kmat("concrete")
	var brick := _kmat("brick")
	var pipe := _std(Color(0.25, 0.2, 0.16), 0.7, 0.7)
	var lamp := _std(Color(1.0, 0.55, 0.2), 0.4, 0.0, 1.5)
	box(root, Vector3(14.0, 0.05, 2.6), Vector3(0, -0.025, 0), conc)
	box(root, Vector3(14.0, 0.1, 2.6), Vector3(0, 3.2, 0), conc)
	for sz in [-1.3, 1.3]:
		box(root, Vector3(14.0, 3.2, 0.1), Vector3(0, 1.6, sz), brick)
		cyl(root, 0.06, 0.06, 14.0, Vector3(0, 2.7, sz * 0.9), pipe, Vector3(0, 0, 90))
	for i in 5:
		var x := -5.6 + float(i) * 2.8
		box(root, Vector3(0.1, 0.16, 0.1), Vector3(x, 2.5, 1.2), lamp)
		box(root, Vector3(0.5, 0.012, 0.9), Vector3(x + 0.6, 0.006, -0.3), _std(Color(0.05, 0.08, 0.1), 0.05, 0.0, 0.0, 0.8))
	box(root, Vector3(0.1, 3.2, 2.6), Vector3(-7.0, 1.6, 0), brick)

static func _parlor(root: Node3D) -> void:
	var rug := _std(Color(0.38, 0.08, 0.1), 0.95)
	var rug_b := _std(Color(0.7, 0.55, 0.3), 0.95)
	var sofa := _std(Color(0.3, 0.12, 0.14), 0.9)
	var wd := _kmat("wood")
	box(root, Vector3(4.0, 0.015, 3.0), Vector3(0, 0.008, 0), rug_b)
	box(root, Vector3(3.7, 0.02, 2.7), Vector3(0, 0.012, 0), rug)
	# sofa along the south side
	box(root, Vector3(2.0, 0.4, 0.85), Vector3(-0.2, 0.2, 1.1), sofa)
	box(root, Vector3(2.0, 0.55, 0.2), Vector3(-0.2, 0.62, 1.45), sofa)
	for sx in [-1.2, 0.8]:
		box(root, Vector3(0.2, 0.3, 0.85), Vector3(sx, 0.45, 1.1), sofa)
	# armchairs
	for sx in [-1.6, 1.6]:
		box(root, Vector3(0.8, 0.4, 0.8), Vector3(sx, 0.2, -0.6), sofa, Vector3(0, sx * 12.0, 0))
		box(root, Vector3(0.8, 0.5, 0.15), Vector3(sx, 0.6, -0.95), sofa, Vector3(0, sx * 12.0, 0))
	# coffee table with candle
	box(root, Vector3(0.9, 0.05, 0.5), Vector3(0, 0.38, 0.0), wd)
	for sx in [-0.4, 0.4]:
		for sz in [-0.2, 0.2]:
			box(root, Vector3(0.05, 0.36, 0.05), Vector3(sx, 0.18, sz), wd)
	cyl(root, 0.025, 0.025, 0.14, Vector3(0.2, 0.47, 0.0), _std(Color(0.9, 0.88, 0.8), 0.6))
	sph(root, 0.02, Vector3(0.2, 0.56, 0.0), _std(Color(1.0, 0.7, 0.3), 0.3, 0.0, 3.0), Vector3(0.7, 1.4, 0.7))
	# tall bookshelf (also sets the model height to 2.6)
	box(root, Vector3(1.4, 2.6, 0.35), Vector3(-1.4, 1.3, -1.35), wd)
	for i in 5:
		box(root, Vector3(1.3, 0.3, 0.25), Vector3(-1.4, 0.4 + float(i) * 0.45, -1.3), _std(Color(0.15 + 0.1 * float(i % 3), 0.08, 0.06), 0.9))
	# floor lamp
	cyl(root, 0.015, 0.015, 1.6, Vector3(1.7, 0.8, 0.9), _std(Color(0.1, 0.1, 0.1), 0.4, 0.8))
	cyl(root, 0.1, 0.2, 0.28, Vector3(1.7, 1.7, 0.9), _std(Color(1.0, 0.8, 0.5), 0.6, 0.0, 0.9))
	# picture frame
	box(root, Vector3(0.7, 0.5, 0.04), Vector3(0.4, 1.6, -1.45), _std(Color(0.35, 0.25, 0.1), 0.5, 0.5))
	box(root, Vector3(0.6, 0.4, 0.045), Vector3(0.4, 1.6, -1.45), _std(Color(0.1, 0.12, 0.13), 0.6))

static func _diorama(root: Node3D) -> void:
	var steel := _std(Color(0.4, 0.42, 0.44), 0.4, 0.9)
	var wd := _kmat("wood")
	var blood := _std(Color(0.3, 0.0, 0.02), 0.25)
	box(root, Vector3(2.0, 0.05, 1.4), Vector3(0, 0.025, 0), _std(Color(0.18, 0.18, 0.19), 0.5))
	box(root, Vector3(1.6, 0.04, 0.9), Vector3(0, 0.92, 0), steel)
	for sx in [-0.7, 0.7]:
		for sz in [-0.35, 0.35]:
			box(root, Vector3(0.06, 0.9, 0.06), Vector3(sx, 0.45, sz), steel)
	box(root, Vector3(0.5, 0.01, 0.4), Vector3(0.1, 0.945, 0.0), blood)
	box(root, Vector3(0.03, 0.18, 0.3), Vector3(-0.4, 1.03, 0.1), steel, Vector3(0, 0, 8))
	cyl(root, 0.28, 0.25, 0.7, Vector3(1.4, 0.35, 0.3), wd)
	cyl(root, 0.22, 0.2, 0.5, Vector3(-1.4, 0.25, -0.3), _std(Color(0.2, 0.25, 0.2), 0.8, 0.5))
	for sx in [-1.0, 1.0]:
		box(root, Vector3(0.08, 1.8, 0.08), Vector3(sx * 1.0, 0.9, -1.0), wd)
	box(root, Vector3(2.1, 0.08, 0.08), Vector3(0, 1.76, -1.0), wd)

static func _tree_like(root: Node3D) -> void:
	box(root, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), _std(Color(0.3, 0.3, 0.3)))

static func build(key: String) -> Node3D:
	var root := Node3D.new()
	match key:
		"butcher":
			_butcher(root)
		"ghost":
			_ghost(root)
		"woman":
			_woman(root)
		"girl":
			_girl(root)
		"rat":
			_rat(root)
		"doll":
			_doll(root)
		"flashlight":
			_flashlight(root)
		"walkie":
			_walkie(root)
		"bible":
			_bible(root)
		"bat":
			_bat(root)
		"pig":
			_pig(root)
		"meat":
			_meat(root)
		"bloodbag":
			_bloodbag(root)
		"clock":
			_clock(root)
		"fan":
			_fan(root)
		"toilet":
			_toilet(root)
		"hook":
			_hook(root)
		"corridor":
			_corridor(root)
		"tunnel":
			_tunnel(root)
		"parlor":
			_parlor(root)
		"diorama":
			_diorama(root)
		"bloodwall":
			box(root, Vector3(4.8, 2.6, 0.1), Vector3(0, 1.3, 0), _kmat("sprig"))
			box(root, Vector3(1.4, 1.2, 0.11), Vector3(0.4, 1.4, 0), _std(Color(0.3, 0.0, 0.02), 0.3))
		_:
			_tree_like(root)
	return root
