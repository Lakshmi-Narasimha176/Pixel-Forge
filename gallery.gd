extends Node3D
## ASSET GALLERY - every character and environment GLB in the repository, live.
## Characters sway / turn in real time, props spin, environments are scaled so you can fly inside them.
## WASD fly, Q/E down/up, SHIFT fast, mouse look (click), 1-3 jump to Characters / Props / Environments, TAB or BACKSPACE back to the game.

const ENTRIES := {
	"characters": [
		["Butcher", "res://horror_butcher_fat_killer_bloody_cleaver.glb", 1.95, 0.0, true],
		["Ghost (blood-stained spirit)", "res://horror_ghost_character_-_blood_stained_spirit.glb", 1.7, 0.0, true],
		["Woman", "res://horror_woman.glb", 1.7, 0.0, false],
		["Horror girl", "res://a_horror_girl_character.glb", 1.68, 0.0, false],
		["Cursed porcelain doll", "res://cursed_porcelain_doll_-_antique_horror_prop.glb", 0.9, 0.0, false],
		["Street rat", "res://street_rat.glb", 0.0, 0.5, true],
		["Hockey mask & book (fan art)", "res://jeson_horror_fan_art.glb", 0.0, 1.4, false],
	],
	"props": [
		["Flashlight", "res://horror_game_flashlight_download_game-ready.glb", 0.0, 0.5, true],
		["Walkie-talkie", "res://psx-style_horror_walkie-talkie.glb", 0.3, 0.0, false],
		["Devil's Bible", "res://devils_bible_-_dark_fantasy_book.glb", 0.6, 0.0, false],
		["Bloody bat", "res://baseball_bat_covered_in_blood.glb", 0.0, 1.0, false],
		["Dead pig", "res://dead_pig.glb", 1.4, 0.0, false],
		["Raw meat pack", "res://psx_raw_meat_pack__low-poly_2_types.glb", 0.0, 0.8, false],
		["Blood bag", "res://blood_bag.glb", 0.0, 0.5, false],
		["Wall clock", "res://vintage_wooden_wall_clock_-.glb", 0.0, 0.8, false],
		["Rusty ceiling fan", "res://old_rusty_ceiling_fan.glb", 0.0, 1.6, false],
		["Meat hook rail", "res://butcher_meat_hook_rail_-_cured_ham__sausages.glb", 0.0, 4.0, false],
		["Wooden outhouse", "res://old_wooden_toilet_house_2.glb", 2.3, 0.0, false],
	],
	"environments": [
		["Blood-splatter wall", "res://abandoned_horror_wall_with_blood_splatter.glb", 0.0, 5.0, false],
		["Soviet room", "res://horror_soviet_room.glb", 0.0, 6.0, false],
		["Horror room (animated)", "res://horror_room.glb", 0.0, 8.0, false],
		["Slaughterhouse diorama", "res://textured_game_environment.glb", 0.0, 6.0, false],
		["Horror corridors", "res://horror_corridor_5.glb", 0.0, 16.0, false],
		["Vintage living room set", "res://modular_vintage_living_room_-_game_ready_pbr.glb", 0.0, 20.0, false],
		["Tunnel", "res://tunnel.glb", 0.0, 20.0, false],
	],
}
const KIT := "res://PSX_Anomaly_Horror_Modular_Kit_Free_Sampler/GLB/House/"

var cam: Camera3D
var yaw := 0.0
var pitch := 0.0
var spinners: Array = []
var swayers: Array = []
var rows := {}
var info: Label
var missing: Array = []
var time := 0.0

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

func _fit(path: String, height: float, length: float, face_x: bool) -> Node3D:
	var holder := Node3D.new()
	var ps = null
	if ResourceLoader.exists(path): ps = load(path)
	if ps == null:
		missing.append(path.get_file())
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.5, 0.5)
		mi.mesh = bm
		mi.position.y = 0.25
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
	return holder

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.055, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.6)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.12, 0.12, 0.13)
	fm.roughness = 1.0
	floor_mesh.material_override = fm
	floor_mesh.position.y = -0.01
	add_child(floor_mesh)
	var z_row := {"characters": 0.0, "props": -8.0, "environments": -26.0}
	for cat in ENTRIES:
		var x := 0.0
		var z: float = z_row[cat]
		rows[cat] = Vector3(0.0, 1.7, z + 6.0)
		for e in ENTRIES[cat]:
			var node := _fit(e[1], e[2], e[3], e[4])
			var half := 1.2
			if cat == "environments": half = maxf(e[3], 6.0) * 0.5 + 1.5
			x += half
			node.position = Vector3(x, 0.0, z)
			add_child(node)
			if cat == "environments":
				# environments stay put (walk inside them); the rest turn on a pedestal
				pass
			else:
				spinners.append(node)
			if cat == "characters": swayers.append(node)
			var lab := Label3D.new()
			lab.text = e[0]
			lab.font_size = 42
			lab.pixel_size = 0.004
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.no_depth_test = true
			lab.position = Vector3(x, (e[2] if e[2] > 0.0 else 1.2) + 0.5 if cat != "environments" else 3.2, z)
			add_child(lab)
			x += half + 0.8
		if cat == "environments": rows[cat] = Vector3(0.0, 2.5, z + 14.0)
	# the kit house pieces
	var kz := 8.0
	var kx := 0.0
	for p in ["house_wall", "house_wall_floral", "house_wall_door", "house_wall_window", "house_door", "house_window", "house_corner", "house_floor", "house_ceiling_light"]:
		var ps = load(KIT + p + ".glb") if ResourceLoader.exists(KIT + p + ".glb") else null
		if ps != null:
			var n: Node3D = ps.instantiate()
			n.position = Vector3(kx, 0, kz)
			add_child(n)
			spinners.append(n)
		kx += 3.0
	cam = Camera3D.new()
	cam.fov = 70
	cam.far = 500
	add_child(cam)
	_jump("characters")
	var hud := CanvasLayer.new()
	add_child(hud)
	info = Label.new()
	info.position = Vector2(20, 16)
	info.add_theme_font_size_override("font_size", 18)
	info.text = "ASSET GALLERY   WASD fly  Q/E down/up  SHIFT fast  mouse look (click)  1 Characters  2 Props  3 Environments  TAB back to the game"
	hud.add_child(info)
	if missing.size() > 0:
		var w := Label.new()
		w.position = Vector2(20, 44)
		w.add_theme_color_override("font_color", Color(1, 0.5, 0.3))
		w.text = "%d model(s) are Git LFS stubs - run `git lfs pull`, then reopen the project." % missing.size()
		hud.add_child(w)

func _jump(cat: String) -> void:
	cam.position = rows[cat]
	yaw = 0.0
	pitch = -0.05 if cat != "environments" else -0.25

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.5, 1.5)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: _jump("characters")
			KEY_2: _jump("props")
			KEY_3: _jump("environments")
			KEY_TAB, KEY_BACKSPACE: get_tree().change_scene_to_file("res://horror/main.tscn")
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(dt: float) -> void:
	time += dt
	for n in spinners: (n as Node3D).rotation.y += dt * 0.6
	for i in swayers.size():
		var n: Node3D = swayers[i]
		n.rotation.z = sin(time * 1.2 + i) * 0.03
		n.position.y = sin(time * 1.7 + i) * 0.02
	var speed := 14.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 5.0
	var f := Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var r := Vector3(cos(yaw), 0, -sin(yaw))
	var v := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): v += f
	if Input.is_physical_key_pressed(KEY_S): v -= f
	if Input.is_physical_key_pressed(KEY_D): v += r
	if Input.is_physical_key_pressed(KEY_A): v -= r
	if Input.is_physical_key_pressed(KEY_E): v += Vector3.UP
	if Input.is_physical_key_pressed(KEY_Q): v -= Vector3.UP
	cam.position += v * speed * dt
	cam.rotation = Vector3(pitch, yaw, 0)
