extends "res://horror/main_plus.gd"
## THE LAST REVENGE - "Cinematic" layer on top of main_plus.gd (main.gd and main_plus.gd stay untouched).
##
## Adds:
##  * Menu fly-around of the Hollis house, animated intro with title card, subtitles and letterbox bars.
##  * Memory flashbacks for the four family pages (uses horror_room.glb and horror_soviet_room.glb).
##  * Cutscenes: Butcher reveal, Devil's Bible, Lily's key, freed spirits (Ada, Mira, Pearl), kill-cam, endings + credits.
##  * Stormy atmosphere: night sky with stars and moon, rain, lightning, thunder, window light shafts, depth of field.
##  * Location and chapter title cards, character aura lights, sprint FOV kick, Butcher footstep tremor.
##  * Layered audio: danger music, freezer hum, Butcher groans, slaughterhouse clanks, book sounds.
##  * Bonus missions: smash the Butcher's mask relic, hear Ada's last words on the walkie.
## Press F2 in game to toggle the heavy cinematic effects on slower machines.

const CineData = preload("res://horror/cine_data.gd")
const FB_ORIGIN := Vector3(400.0, 0.0, 400.0)
const SKY_SHADER := "res://horror/night_sky.gdshader"

static var _intro_seen := false

# --- cinematic UI
var cine_layer: CanvasLayer
var cine_fade: ColorRect
var cine_bar_top: ColorRect
var cine_bar_bot: ColorRect
var cine_sub: RichTextLabel
var cine_title: Label
var cine_title2: Label
var cine_loc: Label
var cine_loc2: Label
var cine_credits: Label
var cine_skip: Label
var hud_layer: CanvasLayer
var cine_cam: Camera3D

# --- cutscene core
var _cs := ""
var _ct := 0.0
var _cs_dur := 1.0
var _cs_ctx: Dictionary = {}
var _cs_prev_state := "play"
var _bars_t := 0.0
var _bars_target := 0.0
var _fade_a := 0.0
var _fade_goal := 0.0
var _fade_speed := 1.0
var _cclock := 0.0
var _menu_t := 0.0
var _subs: Array = []
var _sub_clock := 0.0
var _sub_id := 0
var _sub_cur_id := -1
var _card_t := 0.0
var _card_dur := 1.0
var _loc_t := 0.0
var _loc_seen := {}
var _cards_shown := {}
var _credits_on := false
var _end_text := ""
var _fb_root: Node3D
var _fb_scale := 1.0
var _fb_spin: Node3D
var _orbs: Array = []
var _key_pos := Vector3.ZERO

# --- watchers (previous values)
var _p_confined := true
var _p_bible := false
var _p_girl := true
var _p_ghost := true
var _p_woman := true
var _p_pearl := false
var _mask_smashed := false

# --- atmosphere
var fx_on := true
var _env: Environment
var _moon: DirectionalLight3D
var _sky_mat: ShaderMaterial
var _amb_base := 0.55
var _shafts: Array = []
var _rain: GPUParticles3D
var p_rain: AudioStreamPlayer
var p_evil: AudioStreamPlayer
var p_freezer: AudioStreamPlayer
var p_music: AudioStreamPlayer
var _ltn_next := 14.0
var _ltn_t := -1.0
var _ltn_amp := 1.0
var _thunder_in := -1.0
var _th_lp := 0.0
var _rain_lp := 0.0
var _groan_t := 9.0
var _clank_t := 12.0
var _auras: Array = []

# ------------------------------------------------------------------ lifecycle
func _ready() -> void:
	_cine_build_ui()
	super()
	_cine_post_ready()

func _exit_tree() -> void:
	_cs_cleanup()
	super()

func _reset_run() -> void:
	super()
	_p_confined = butcher_confined
	_p_bible = has_bible
	_p_girl = girl_alive
	_p_ghost = ghost_alive
	_p_woman = woman_alive
	_p_pearl = pearl_comforted
	_mask_smashed = false
	_cards_shown.clear()
	_loc_seen.clear()

func _cine_post_ready() -> void:
	cine_cam = Camera3D.new()
	cine_cam.fov = 70.0
	cine_cam.near = 0.05
	cine_cam.far = 160.0
	cine_cam.attributes = CameraAttributesPractical.new()
	add_child(cine_cam)
	for c in get_children():
		if c is CanvasLayer and (c as CanvasLayer).layer == 10:
			hud_layer = c
		elif c is DirectionalLight3D and _moon == null:
			_moon = c
	_upgrade_environment()
	_build_window_shafts()
	_build_rain()
	_build_extra_audio()
	_build_auras()
	missions.append({"id": "mask", "text": "Smash the Butcher's hockey-mask relic with the bat", "required": false, "done": false})
	missions.append({"id": "ada_voice", "text": "Use the walkie beside Ada to hear her last words", "required": false, "done": false})
	hud_controls.text += "   [F2] Cinematic FX"
	if state == "menu":
		overlay.color = Color(0, 0, 0, 0.55)
		overlay_label.text += "\n\nF2  Toggle rain, lightning and depth of field (for slower PCs)"
		cine_cam.make_current()
	_apply_fx_quality()

# ------------------------------------------------------------------ UI construction
func _cine_label(font_size: int, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cine_layer.add_child(l)
	return l

func _cine_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cine_layer.add_child(r)
	return r

func _cine_build_ui() -> void:
	cine_layer = CanvasLayer.new()
	cine_layer.layer = 20
	add_child(cine_layer)
	cine_fade = _cine_rect(Color(0, 0, 0, 0))
	cine_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	cine_bar_top = _cine_rect(Color.BLACK)
	cine_bar_bot = _cine_rect(Color.BLACK)
	cine_sub = RichTextLabel.new()
	cine_sub.bbcode_enabled = true
	cine_sub.fit_content = true
	cine_sub.scroll_active = false
	cine_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cine_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cine_sub.add_theme_font_size_override("normal_font_size", 24)
	cine_sub.add_theme_font_size_override("bold_font_size", 24)
	cine_sub.add_theme_color_override("default_color", Color(0.96, 0.95, 0.92))
	cine_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	cine_sub.add_theme_constant_override("outline_size", 7)
	cine_layer.add_child(cine_sub)
	cine_title = _cine_label(72, Color(0.95, 0.9, 0.82))
	cine_title2 = _cine_label(24, Color(0.85, 0.3, 0.25))
	cine_loc = _cine_label(30, Color(0.95, 0.92, 0.85), HORIZONTAL_ALIGNMENT_LEFT)
	cine_loc2 = _cine_label(17, Color(0.8, 0.78, 0.72), HORIZONTAL_ALIGNMENT_LEFT)
	cine_credits = _cine_label(26, Color(0.92, 0.9, 0.86))
	cine_credits.visible = false
	cine_skip = _cine_label(14, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_RIGHT)
	cine_skip.text = "[ENTER] Skip"
	cine_skip.visible = false
	for l in [cine_title, cine_title2, cine_loc, cine_loc2]:
		(l as Label).modulate.a = 0.0

# ------------------------------------------------------------------ atmosphere set-up
func _upgrade_environment() -> void:
	for c in get_children():
		if c is WorldEnvironment:
			_env = (c as WorldEnvironment).environment
	if _env == null:
		return
	if ResourceLoader.exists(SKY_SHADER):
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = load(SKY_SHADER)
		var sky := Sky.new()
		sky.sky_material = _sky_mat
		_env.sky = sky
		_env.background_mode = Environment.BG_SKY
	_amb_base = _env.ambient_light_energy
	_env.ssr_enabled = true
	_env.ssr_max_steps = 32
	_env.ssil_enabled = true
	_env.ssil_radius = 2.0
	_env.ssil_intensity = 0.9
	_env.glow_hdr_threshold = 0.9

func _build_window_shafts() -> void:
	var count := 0
	for w in WINDOWS:
		var sd: Dictionary = SIDE[w[2]]
		var out := Vector3(float(sd.dx), 0.0, float(sd.dz))
		var wc := cell_center(w[0], w[1]) + out * (CELL * 0.5) + Vector3(0.0, 1.5, 0.0)
		var l := SpotLight3D.new()
		l.light_color = Color(0.5, 0.62, 1.0)
		l.light_energy = 2.2
		l.spot_range = 10.0
		l.spot_angle = 26.0
		l.light_volumetric_fog_energy = 1.6
		l.shadow_enabled = count < 5
		add_child(l)
		l.look_at_from_position(wc + out * 2.6 + Vector3(0.0, 1.5, 0.0), wc - out * 2.2 + Vector3(0.0, -1.4, 0.0), Vector3.UP)
		_shafts.append(l)
		count += 1

func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.amount = 900
	_rain.lifetime = 0.9
	_rain.preprocess = 1.0
	_rain.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 28, 40))
	_rain.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(14.0, 0.5, 14.0)
	pm.direction = Vector3(0.12, -1.0, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0.0, -6.0, 0.0)
	_rain.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.012, 0.55)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.65, 0.75, 1.0, 0.28)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.material = mm
	_rain.draw_pass_1 = qm
	add_child(_rain)

func _build_auras() -> void:
	_auras.append(_add_aura(ghost, Color(0.45, 0.85, 1.0), 0.9, 4.5))
	_auras.append(_add_aura(woman, Color(0.75, 0.5, 1.0), 0.8, 4.5))
	_auras.append(_add_aura(girl, Color(0.7, 1.0, 0.85), 0.7, 3.5))

func _add_aura(parent: Node3D, color: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = Vector3(0.0, 1.1, 0.0)
	l.shadow_enabled = false
	parent.add_child(l)
	return l

func _w_thunder(t: float, _d: float) -> float:
	_th_lp = _th_lp * 0.97 + rng.randf_range(-1.0, 1.0) * 0.03
	var env := exp(-t * 0.9) * minf(t * 6.0, 1.0)
	var roll := 0.6 + 0.4 * sin(TAU * 3.0 * t + 4.0 * sin(TAU * 0.4 * t))
	return _th_lp * 7.0 * env * roll

func _w_rain(t: float, _d: float) -> float:
	var n := rng.randf_range(-1.0, 1.0)
	var o := n - _rain_lp
	_rain_lp = n
	return (n * 0.12 + o * 0.12) * (0.78 + 0.22 * sin(TAU * 0.25 * t))

func _build_extra_audio() -> void:
	snd["thunder"] = _wav(_w_thunder, 4.0)
	snd["rain"] = _wav(_w_rain, 4.0, true)
	_recorded_sound("book_close", "res://assets/audio/interaction/bookClose.ogg")
	_recorded_sound("latch", "res://assets/audio/interaction/metalLatch.ogg")
	_recorded_sound("groan1", "res://assets/audio/enemy/zombienoise1.ogg")
	_recorded_sound("groan2", "res://assets/audio/enemy/zombienoise2.ogg")
	_recorded_sound("groan3", "res://assets/audio/enemy/zombienoise3.ogg")
	_recorded_sound("rush", "res://assets/audio/enemy/fastzombie1.ogg")
	_recorded_sound("clank1", "res://assets/audio/interaction/impactMetal_heavy_000.ogg")
	_recorded_sound("clank2", "res://assets/audio/interaction/impactMetal_medium_002.ogg")
	_recorded_sound("clank3", "res://assets/audio/interaction/impactMetal_light_001.ogg")
	_recorded_sound("evil", "res://assets/audio/ambient/evil_0.ogg", true)
	_recorded_sound("freezer", "res://assets/audio/ambient/freezer_0.ogg", true)
	_recorded_sound("music", "res://assets/audio/music/ambient_horror_0.ogg", true)
	p_rain = _loop_player("rain", -14.0)
	p_evil = _loop_player("evil", -60.0)
	p_freezer = _loop_player("freezer", -60.0)
	p_music = _loop_player("music", -60.0)

func _loop_player(sname: String, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if snd.has(sname):
		p.stream = snd[sname]
	p.volume_db = vol
	add_child(p)
	if p.stream != null:
		p.play()
	return p

# ------------------------------------------------------------------ helpers
func _ease(u: float) -> float:
	var x := clampf(u, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _hand(t: float, amp: float) -> Vector3:
	return Vector3(sin(t * 1.7), sin(t * 2.3 + 1.0), sin(t * 1.3 + 2.0)) * amp

func _cam_to(pos: Vector3, target: Vector3, fov := 70.0, roll := 0.0) -> void:
	var tgt := target
	if pos.distance_to(tgt) < 0.05:
		tgt = pos + Vector3(0.0, 0.0, -1.0)
	cine_cam.look_at_from_position(pos, tgt, Vector3.UP)
	cine_cam.rotation.z += roll
	cine_cam.fov = fov

func _dof(on: bool, dist := 8.0, amount := 0.08) -> void:
	var a := cine_cam.attributes as CameraAttributesPractical
	if a == null:
		return
	var enable := on and fx_on
	a.dof_blur_far_enabled = enable
	a.dof_blur_far_distance = dist
	a.dof_blur_far_transition = dist * 1.2
	a.dof_blur_near_enabled = enable
	a.dof_blur_near_distance = 0.6
	a.dof_blur_near_transition = 0.5
	a.dof_blur_amount = amount

func _sub_add(delay: float, dur: float, who: String, text: String) -> void:
	_sub_id += 1
	_subs.append({"id": _sub_id, "at": _sub_clock + delay, "dur": dur, "who": who, "text": text})

func _sub_lines(lines: Array) -> void:
	for s in lines:
		_sub_add(float(s[0]), float(s[1]), str(s[2]), str(s[3]))

func _card_show(title: String, sub: String, dur := 4.0) -> void:
	cine_title.text = title
	cine_title2.text = sub
	_card_t = dur
	_card_dur = dur

func _loc_show(title: String, sub: String) -> void:
	cine_loc.text = title
	cine_loc2.text = sub
	_loc_t = 4.6

func _make_orb(color: Color, size := 0.12) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2.0
	mi.mesh = sm
	var m := _mat(color, 0.3)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 3.0
	mi.material_override = m
	root.add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 1.8
	l.omni_range = 5.0
	root.add_child(l)
	add_child(root)
	_orbs.append(root)
	return root

func _ghostify(n: Node) -> void:
	for mesh in n.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).transparency = 0.5

func _location_id() -> String:
	var p := player.position
	var rm = room_of.get(cell_key_at(p), null)
	if rm != null:
		return str(rm.id)
	if p.x < 1.0 and p.x > -12.0 and absf(p.z - 6.0) < 2.5:
		return "corridor"
	if p.z > 17.0:
		return "tunnel"
	if p.z > 13.5:
		return "yard"
	return ""

func _indoors() -> bool:
	return room_of.has(cell_key_at(player.position))

# ------------------------------------------------------------------ input
func _input(event: InputEvent) -> void:
	if state == "cinematic":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
				_ct = _cs_dur
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		fx_on = not fx_on
		_apply_fx_quality()
		if state == "play":
			say("Cinematic FX: " + ("ON" if fx_on else "OFF (rain, lightning, depth of field)"), 3.0)
		return
	super(event)

func _apply_fx_quality() -> void:
	if _env != null:
		_env.ssil_enabled = fx_on
		_env.ssr_enabled = fx_on
	for s in _shafts:
		(s as SpotLight3D).visible = fx_on
	if _rain != null:
		_rain.visible = fx_on
	if cine_cam != null:
		_dof(false)

# ------------------------------------------------------------------ per-frame (render)
func _process(dt: float) -> void:
	_cclock += dt
	_cine_ui_update(dt)
	if state == "cinematic":
		_cs_tick(dt)
	elif state == "menu" and cine_cam != null:
		_menu_cam_tick(dt)
	_atmosphere_tick(dt)

func _menu_cam_tick(dt: float) -> void:
	_menu_t += dt
	var a := 0.6 + _menu_t * 0.045
	var center := Vector3(14.0, 1.5, 8.0)
	var pos := center + Vector3(cos(a) * 27.0, 5.5 + sin(_menu_t * 0.2) * 0.6, sin(a) * 22.0)
	_cam_to(pos, center + Vector3(0.0, 2.0, 0.0), 58.0)

func _cine_ui_update(dt: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	_bars_t = move_toward(_bars_t, _bars_target, dt * 1.4)
	var bh := vp.y * 0.115 * _ease(_bars_t)
	cine_bar_top.position = Vector2.ZERO
	cine_bar_top.size = Vector2(vp.x, bh)
	cine_bar_bot.position = Vector2(0.0, vp.y - bh)
	cine_bar_bot.size = Vector2(vp.x, bh)
	if state != "cinematic":
		_fade_a = move_toward(_fade_a, _fade_goal, dt * _fade_speed)
		cine_fade.color.a = _fade_a
	cine_skip.visible = state == "cinematic" and _cs != "death"
	cine_skip.position = Vector2(vp.x - 224.0, vp.y - bh - 30.0)
	cine_skip.size = Vector2(200.0, 20.0)

	# Subtitles
	_sub_clock += dt
	var cur = null
	for s in _subs:
		if _sub_clock >= float(s.at) and _sub_clock < float(s.at) + float(s.dur):
			cur = s
			break
	if cur != null:
		if int(cur.id) != _sub_cur_id:
			_sub_cur_id = int(cur.id)
			var col: String = CineData.SPEAKER_COLORS.get(str(cur.who), "#ffffff")
			cine_sub.text = "[center][color=%s][b]%s[/b][/color]   %s[/center]" % [col, str(cur.who), str(cur.text)]
		var age: float = _sub_clock - float(cur.at)
		cine_sub.modulate.a = clampf(minf(age / 0.25, (float(cur.dur) - age) / 0.3), 0.0, 1.0)
	else:
		if _sub_cur_id != -1:
			_sub_cur_id = -1
			cine_sub.text = ""
		while _subs.size() > 0 and _sub_clock > float(_subs[0].at) + float(_subs[0].dur):
			_subs.pop_front()
	var sw := minf(1000.0, vp.x * 0.8)
	cine_sub.size = Vector2(sw, 70.0)
	cine_sub.position = Vector2((vp.x - sw) * 0.5, vp.y - bh - (110.0 if bh > 1.0 else 235.0))

	# Centre title card with typewriter text
	cine_title.position = Vector2(0.0, vp.y * 0.38 - 50.0)
	cine_title.size = Vector2(vp.x, 100.0)
	cine_title2.position = Vector2(0.0, vp.y * 0.38 + 50.0)
	cine_title2.size = Vector2(vp.x, 40.0)
	if _card_t > 0.0:
		_card_t -= dt
		var el := _card_dur - _card_t
		var a := clampf(minf(el / 0.6, _card_t / 0.9), 0.0, 1.0)
		cine_title.modulate.a = a
		cine_title2.modulate.a = a
		cine_title.visible_characters = int(el / 0.07)
	else:
		cine_title.modulate.a = 0.0
		cine_title2.modulate.a = 0.0

	# Lower-third location card
	cine_loc.position = Vector2(64.0, vp.y * 0.72)
	cine_loc.size = Vector2(vp.x * 0.6, 40.0)
	cine_loc2.position = Vector2(64.0, vp.y * 0.72 + 40.0)
	cine_loc2.size = Vector2(vp.x * 0.6, 24.0)
	if _loc_t > 0.0:
		_loc_t -= dt
		var la := clampf(minf((4.6 - _loc_t) / 0.5, _loc_t / 0.8), 0.0, 1.0)
		cine_loc.modulate.a = la
		cine_loc2.modulate.a = la
	else:
		cine_loc.modulate.a = 0.0
		cine_loc2.modulate.a = 0.0

# ------------------------------------------------------------------ atmosphere (per frame)
func _atmosphere_tick(dt: float) -> void:
	var cam3d := get_viewport().get_camera_3d()
	var in_flashback := state == "cinematic" and _cs == "flashback"
	if _rain != null and cam3d != null:
		_rain.global_position = cam3d.global_position + Vector3(0.0, 9.0, 0.0)
		var raining := fx_on and not in_flashback and not (state == "cinematic" and _cs == "ending" and _ct > 8.0)
		_rain.emitting = raining and (state == "menu" or state == "cinematic" or not _indoors())
	_lightning_tick(dt, not in_flashback)

	# Rain bed: loud outside, muffled inside.
	var indoors := state != "menu" and state != "cinematic" and _indoors()
	var rain_db := -30.0 if in_flashback else (-24.0 if indoors else -13.0)
	p_rain.volume_db = lerpf(p_rain.volume_db, rain_db, minf(1.0, 2.0 * dt))

	# Layered music: menu theme, danger drone that follows the Butcher's threat, freezer hum in the slaughterhouse.
	var music_db := -60.0
	var evil_db := -60.0
	var freezer_db := -60.0
	if state == "menu":
		music_db = -12.0
	elif state == "play":
		music_db = -26.0
		evil_db = -34.0 + threat * 26.0
		if _location_id() == "slaughter":
			freezer_db = -14.0
	elif state == "cinematic":
		music_db = -16.0
	p_music.volume_db = lerpf(p_music.volume_db, music_db, minf(1.0, 1.5 * dt))
	p_evil.volume_db = lerpf(p_evil.volume_db, evil_db, minf(1.0, 2.0 * dt))
	p_freezer.volume_db = lerpf(p_freezer.volume_db, freezer_db, minf(1.0, 2.0 * dt))

	# Aura pulses
	for i in _auras.size():
		var l := _auras[i] as OmniLight3D
		if l != null and l.visible:
			l.light_energy = (0.8 + 0.35 * sin(_cclock * (1.3 + i * 0.4) + i)) * (0.7 + 0.3 * float(i == 2))

func _lightning_tick(dt: float, allowed: bool) -> void:
	_ltn_next -= dt
	if _ltn_next <= 0.0 and allowed and fx_on and state != "pause":
		_ltn_next = rng.randf_range(16.0, 38.0)
		_ltn_t = 0.0
		_ltn_amp = rng.randf_range(0.6, 1.0)
		_thunder_in = rng.randf_range(0.5, 3.0)
	var lvl := 0.0
	if _ltn_t >= 0.0:
		_ltn_t += dt
		if _ltn_t > 0.9:
			_ltn_t = -1.0
		else:
			lvl = (1.0 if fmod(_ltn_t, 0.19) < 0.075 else 0.12) * (1.0 - _ltn_t / 0.9) * _ltn_amp
	if _thunder_in >= 0.0:
		_thunder_in -= dt
		if _thunder_in < 0.0:
			_thunder_in = -1.0
			play("thunder", -4.0)
	if _env != null:
		_env.ambient_light_energy = _amb_base + lvl * 1.1
	for s in _shafts:
		(s as SpotLight3D).light_energy = 2.2 * (1.0 + lvl * 5.0)
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("storm", lvl)

# ------------------------------------------------------------------ start / retry
func _start() -> void:
	super()
	overlay.color = Color(0, 0, 0, 0.85)
	if cine_cam == null:
		_fade_a = 1.0
		_fade_goal = 0.0
		_fade_speed = 0.8
		cine_fade.color.a = 1.0
		return
	if not _intro_seen:
		_intro_seen = true
		_cs_start("intro")
	else:
		cam.make_current()
		_fade_a = 1.0
		_fade_goal = 0.0
		_fade_speed = 0.9

# ------------------------------------------------------------------ overrides that trigger cinematics
func _spawn_father_key(pos: Vector3) -> void:
	_key_pos = pos
	super(pos)

func _collect_lore(it: Dictionary) -> void:
	var page: Dictionary = it.page
	if lore_found.has(page.id):
		return
	super(it)
	# Safe readable lore reading: do not black out screen with broken (400,400) camera
	play("book", -2.0)
	play("stinger", -12.0)

func _close_reading() -> void:
	if state == "reading":
		play("book_close", -4.0)
	super()

func _die() -> void:
	var killer := butcher.global_position + Vector3(0.0, 1.8, 0.0)
	var from := cam.global_position
	super()
	if cine_cam == null:
		return
	_end_text = overlay_label.text
	_cs_start_forced("death", {"from": from, "killer": killer})

func _win() -> void:
	super()
	if cine_cam == null:
		return
	_end_text = overlay_label.text
	_cs_start_forced("ending", {"true": _family_at_peace()})

func _cs_start_forced(cs_name: String, ctx: Dictionary) -> void:
	state = "play"
	_cs_start(cs_name, ctx)

func _bat_attack() -> void:
	var before := b_stun
	super()
	if _mask_smashed and b_stun > before and b_stun < 5.0:
		b_stun = 5.0

func _interact() -> void:
	var it = _find_focus()
	if it != null and it.kind == "mask" and not it.get("taken", false):
		if has_bat:
			it.taken = true
			(it.node as Node3D).visible = false
			_mask_smashed = true
			play("bat_hit", 3.0)
			play("ghost_hit", -6.0)
			shake = 0.9
			complete_mission("mask")
			say("You smashed the Butcher's mask relic. Abel's grip on the house weakens: bat stuns last longer.", 7.0)
		else:
			say("The relic hums with Abel's hatred. Something heavy could break it.", 5.0)
			play("stinger", -8.0)
		return
	super()

func _use_walkie() -> void:
	if has_walkie and ghost_alive and not mission_done("ada_voice") and player.position.distance_to(ghost.position) < 4.5:
		play("radio")
		complete_mission("ada_voice")
		_sub_lines(CineData.ADA_VOICE_SUBS)
		return
	super()

func _update_ui(dt: float) -> void:
	super(dt)
	hud_missions.text += "\nBONUS: Mask %s  Ada's Voice %s  Memories %d/4" % [
		"[X]" if mission_done("mask") else "[ ]", "[X]" if mission_done("ada_voice") else "[ ]", lore_found.size()]

func _update_player(dt: float) -> void:
	super(dt)
	var spd := Vector2(player.velocity.x, player.velocity.z).length()
	var target_fov := 72.0 + clampf((spd - 2.2) / 2.1, 0.0, 1.0) * 7.0
	cam.fov = lerpf(cam.fov, target_fov, minf(1.0, 6.0 * dt))
	cam.rotation.z += sin(_cclock * 1.1) * 0.002 * (1.0 + threat * 3.0)
	if flash_on and girl_alive and girl.visible and girl.position.distance_to(player.position) < 6.0:
		flash.light_energy = 6.0 * (1.0 if rng.randf() > 0.35 else 0.15)

func _physics_process(dt: float) -> void:
	if state == "reading":
		if rat != null: rat.velocity = Vector3.ZERO
		return
	super(dt)
	if state == "cinematic":
		_unpause_audio()
		return
	if state != "play" or cine_cam == null:
		return
	_cine_watch()
	_play_fx(dt)

func _unpause_audio() -> void:
	for p in [p_amb, p_fan, p_doll_cry, p_girl, p_butcher]:
		p.stream_paused = false
	for e in _emitters:
		(e as AudioStreamPlayer3D).stream_paused = false

func _cine_watch() -> void:
	if _p_confined and not butcher_confined:
		_p_confined = false
		_cs_start("reveal")
		return
	if not _p_bible and has_bible:
		_p_bible = true
		_cs_start("bible")
		return
	if _p_girl and not girl_alive:
		_p_girl = false
		_cs_start("free", {"id": "lily", "pos": _key_pos})
		return
	if _p_ghost and not ghost_alive:
		_p_ghost = false
		_cs_start("free", {"id": "ada", "pos": ghost.global_position + Vector3(0.0, 0.9, 0.0)})
		return
	if _p_woman and not woman_alive:
		_p_woman = false
		_cs_start("free", {"id": "mira", "pos": woman.global_position + Vector3(0.0, 1.0, 0.0)})
		return
	if not _p_pearl and pearl_comforted:
		_p_pearl = true
		_cs_start("free", {"id": "pearl", "pos": doll.global_position + Vector3(0.0, 0.3, 0.0)})
		return
	for mid in CineData.CHAPTER_CARDS:
		if mission_done(mid) and not _cards_shown.has(mid):
			_cards_shown[mid] = true
			var c: Array = CineData.CHAPTER_CARDS[mid]
			_card_show(str(c[0]), str(c[1]), 4.5)
	var loc := _location_id()
	if loc != "" and not _loc_seen.has(loc) and CineData.ROOM_TITLES.has(loc) and _card_t <= 0.0:
		_loc_seen[loc] = true
		var r: Array = CineData.ROOM_TITLES[loc]
		_loc_show(str(r[0]), str(r[1]))

func _play_fx(dt: float) -> void:
	var dist_b := butcher.position.distance_to(player.position)
	# Footsteps of a chasing Butcher shake the camera.
	if b_state == "chase" and dist_b < 8.0 and b_stun <= 0.0:
		shake = maxf(shake, 0.14 * (1.0 - dist_b / 8.0))
	# Butcher groans and rushes.
	_groan_t -= dt
	if _groan_t <= 0.0:
		if b_state == "chase" and snd.has("rush"):
			_groan_t = rng.randf_range(5.0, 8.0)
			play_at("rush", butcher.position + Vector3(0.0, 1.5, 0.0), -2.0)
		else:
			_groan_t = rng.randf_range(9.0, 16.0)
			var gname := "groan%d" % (1 + rng.randi() % 3)
			if snd.has(gname):
				play_at(gname, butcher.position + Vector3(0.0, 1.5, 0.0), -3.0)
	# Hook rail clanks while the player is in the slaughterhouse.
	_clank_t -= dt
	if _clank_t <= 0.0:
		_clank_t = rng.randf_range(8.0, 15.0)
		if _location_id() == "slaughter":
			var cname := "clank%d" % (1 + rng.randi() % 3)
			if snd.has(cname):
				play_at(cname, Vector3(24.5, 2.4, 10.5), -4.0)

# ------------------------------------------------------------------ cutscene core
func _cs_start(cs_name: String, ctx: Dictionary = {}) -> void:
	if state == "cinematic" or cine_cam == null:
		return
	_cs = cs_name
	_ct = 0.0
	_cs_ctx = ctx
	_cs_prev_state = state
	state = "cinematic"
	_subs.clear()
	_credits_on = false
	if hud_layer != null:
		hud_layer.visible = false
	overlay.visible = false
	cine_cam.make_current()
	_bars_target = 1.0
	match cs_name:
		"intro": _cs_begin_intro()
		"flashback": _cs_begin_flashback()
		"reveal": _cs_begin_reveal()
		"bible": _cs_begin_bible()
		"free": _cs_begin_free()
		"death": _cs_begin_death()
		"ending": _cs_begin_ending()

func _cs_tick(dt: float) -> void:
	_ct += dt
	match _cs:
		"intro": _cs_step_intro(_ct)
		"flashback": _cs_step_flashback(_ct)
		"reveal": _cs_step_reveal(_ct)
		"bible": _cs_step_bible(_ct)
		"free": _cs_step_free(_ct)
		"death": _cs_step_death(_ct)
		"ending": _cs_step_ending(_ct)
	if _ct >= _cs_dur:
		_cs_finish()

func _cs_cleanup() -> void:
	if _fb_root != null and is_instance_valid(_fb_root):
		_fb_root.queue_free()
	_fb_root = null
	_fb_spin = null
	for o in _orbs:
		if is_instance_valid(o):
			(o as Node).queue_free()
	_orbs.clear()

func _cs_finish() -> void:
	var finished := _cs
	_cs = ""
	var ctx := _cs_ctx
	_cs_cleanup()
	_dof(false)
	post_mat.set_shader_parameter("flashback", 0.0)
	post_mat.set_shader_parameter("glitch", 0.0)
	_bars_target = 0.0
	_subs.clear()
	_credits_on = false
	cine_credits.visible = false
	_fade_a = cine_fade.color.a
	_fade_goal = 0.0
	_fade_speed = 2.0
	if hud_layer != null:
		hud_layer.visible = true
	match finished:
		"flashback":
			state = "reading"
			_show_overlay(str(ctx.get("text", "")))
		"death":
			state = "dead"
			_show_overlay(_end_text)
		"ending":
			state = "won"
			_show_overlay(_end_text)
		_:
			state = "play"
			cam.make_current()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# ------------------------------------------------------------------ cutscene: intro
func _cs_begin_intro() -> void:
	_cs_dur = 15.0
	player.position = Vector3(18.0, 0.05, 23.5)
	yaw = 0.0
	pitch = 0.0
	_fade_a = 1.0
	cine_fade.color.a = 1.0
	_card_show("THE LAST REVENGE", "A Hollis family nightmare", 4.2)
	_sub_lines(CineData.INTRO_SUBS)
	_dof(true, 7.0)

func _cs_step_intro(t: float) -> void:
	var fa := 1.0
	if t >= 2.4:
		fa = 1.0 - _ease((t - 2.4) / 2.0)
	_fade_a = fa
	cine_fade.color.a = fa
	var eu := _ease((t - 2.4) / 8.0)
	var push := _ease((t - 10.4) / 4.6)
	var pos := Vector3(18.0 + sin(t * 0.6) * 0.05, lerpf(0.22, 1.62, eu), 23.5 - push * 0.9)
	var tgt := Vector3(18.0, lerpf(2.2, 1.55, eu), 12.0)
	_cam_to(pos + _hand(t, 0.012 * (1.0 - eu) + 0.004), tgt, lerpf(88.0, 70.0, eu), lerpf(0.35, 0.0, eu))
	if t >= 14.9:
		player.position = Vector3(18.0, 0.05, 22.6)
		yaw = 0.0
		pitch = 0.0

# ------------------------------------------------------------------ cutscene: memory flashbacks
func _cs_begin_flashback() -> void:
	var fb: Dictionary = CineData.FLASHBACKS[_cs_ctx.id]
	_cs_dur = float(fb.dur)
	_fb_root = Node3D.new()
	_fb_root.position = FB_ORIGIN
	add_child(_fb_root)
	var set_node := fit(str(fb.set), float(fb.height))
	_fb_root.add_child(set_node)
	var sz: Vector3 = set_node.get_meta("size", Vector3(5.0, 3.0, 5.0))
	_fb_scale = clampf(minf(sz.x, sz.z) * 0.3 / 2.2, 0.5, 1.2)
	for c in fb.cast:
		var n := fit(str(c.m), float(c.get("h", 0.0)), float(c.get("len", 0.0)), bool(c.get("fx", false)))
		n.position = c.pos
		n.rotation.y = float(c.get("yaw", 0.0))
		_fb_root.add_child(n)
		if bool(c.get("ghost", false)):
			_ghostify(n)
		if bool(c.get("spin", false)):
			_fb_spin = n
	var l := OmniLight3D.new()
	l.light_color = fb.light
	l.light_energy = float(fb.energy)
	l.omni_range = 9.0
	l.position = Vector3(0.0, 2.3, 0.0)
	_fb_root.add_child(l)
	_sub_lines(fb.subs)
	post_mat.set_shader_parameter("flashback", 1.0)
	post_mat.set_shader_parameter("desat", 0.0)
	_dof(true, 3.5, 0.1)
	cine_fade.color.a = 1.0
	_fade_a = 1.0
	play("book", -4.0)

func _cs_step_flashback(t: float) -> void:
	var fb: Dictionary = CineData.FLASHBACKS[_cs_ctx.id]
	var u := clampf(t / _cs_dur, 0.0, 1.0)
	var orb: Dictionary = fb.orbit
	var a := lerpf(float(orb.a0), float(orb.a1), _ease(u))
	var r := lerpf(float(orb.r0), float(orb.r1), u) * _fb_scale / 0.68
	var h := lerpf(float(orb.h0), float(orb.h1), u)
	var tgt: Vector3 = FB_ORIGIN + fb.target
	var pos := FB_ORIGIN + Vector3(cos(a) * r, h, sin(a) * r)
	_cam_to(pos + _hand(t, 0.01), tgt + Vector3(0.0, sin(t * 0.8) * 0.03, 0.0), lerpf(62.0, 48.0, u))
	var fa := 0.0
	if t < 0.8:
		fa = 1.0 - t / 0.8
	elif t > _cs_dur - 0.9:
		fa = (t - (_cs_dur - 0.9)) / 0.9
	_fade_a = fa
	cine_fade.color.a = fa
	post_mat.set_shader_parameter("glitch", 0.35 if (t < 0.5 or t > _cs_dur - 0.5) else 0.0)
	if _fb_spin != null:
		_fb_spin.rotation.y += 0.03

# ------------------------------------------------------------------ cutscene: Butcher reveal
func _cs_begin_reveal() -> void:
	_cs_dur = 4.6
	var head := butcher.global_position + Vector3(0.0, 1.7, 0.0)
	var eye := cam.global_position
	_cs_ctx["anchored"] = eye.distance_to(head) < 26.0 and _los(eye, head)
	_cs_ctx["eye"] = eye
	_sub_lines(CineData.REVEAL_SUBS)
	play("butcher_growl", -2.0)
	play("stinger", -4.0)
	post_mat.set_shader_parameter("flash", 0.5)
	var carry: OmniLight3D = butcher.get_meta("eye_light")
	carry.light_energy = 2.5
	_dof(true, 4.0, 0.1)

func _cs_step_reveal(t: float) -> void:
	var u := clampf(t / _cs_dur, 0.0, 1.0)
	var head := butcher.global_position + Vector3(0.0, lerpf(1.6, 1.95, _ease(u)), 0.0)
	if bool(_cs_ctx.get("anchored", false)):
		var eye: Vector3 = _cs_ctx.eye
		_cam_to(eye + _hand(t, 0.01), head, lerpf(70.0, 34.0, _ease(u)))
	else:
		var facing := Vector3(sin(butcher.rotation.y), 0.0, cos(butcher.rotation.y))
		var dist := lerpf(3.6, 2.2, _ease(u))
		_cam_to(butcher.global_position + facing * dist + Vector3(0.0, lerpf(0.5, 1.1, u), 0.0) + _hand(t, 0.012), head, lerpf(56.0, 40.0, _ease(u)))
	if t > 3.6:
		shake = maxf(shake, 0.8)

# ------------------------------------------------------------------ cutscene: Devil's Bible
func _cs_begin_bible() -> void:
	_cs_dur = 4.0
	_cs_ctx["eye"] = cam.global_position
	_sub_lines(CineData.BIBLE_SUBS)
	play("ritual", 0.0)
	post_mat.set_shader_parameter("glitch", 0.5)
	_dof(true, 5.0, 0.1)

func _cs_step_bible(t: float) -> void:
	var eye: Vector3 = _cs_ctx.eye
	var bible_pos := Vector3(24.0, 1.0, 10.0)
	var head := butcher.global_position + Vector3(0.0, 1.8, 0.0)
	var tgt := bible_pos.lerp(head, _ease((t - 1.9) / 0.5))
	var fov := lerpf(70.0, 42.0, _ease(t / 1.8))
	if t > 2.3:
		fov = lerpf(40.0, 82.0, _ease((t - 2.3) / 0.7))
	post_mat.set_shader_parameter("glitch", 0.5 if t < 0.8 else (0.3 if t > 2.3 else 0.0))
	_cam_to(eye + _hand(t, 0.01 if t < 2.3 else 0.05), tgt, fov)

# ------------------------------------------------------------------ cutscene: freed spirits / Lily's key
func _cs_begin_free() -> void:
	_cs_dur = 4.2
	var info: Dictionary = CineData.FREED[_cs_ctx.id]
	_sub_lines(info.lines)
	var orb := _make_orb(info.color)
	orb.position = _cs_ctx.pos
	_cs_ctx["orb"] = orb
	var away: Vector3 = player.position - _cs_ctx.pos
	away.y = 0.0
	if away.length() < 0.2:
		away = Vector3(0.0, 0.0, 1.0)
	_cs_ctx["a0"] = atan2(away.z, away.x)
	play("heal", -2.0)
	_dof(true, 2.6, 0.1)

func _cs_step_free(t: float) -> void:
	var u := clampf(t / _cs_dur, 0.0, 1.0)
	var base: Vector3 = _cs_ctx.pos
	var orb := _cs_ctx.orb as Node3D
	if orb != null:
		orb.position = base + Vector3(sin(t * 2.0) * 0.12, _ease(u) * 2.4, cos(t * 1.7) * 0.12)
		(orb.get_child(1) as OmniLight3D).light_energy = 1.8 * (1.0 - _ease((u - 0.7) / 0.3) * 0.8)
	var a := float(_cs_ctx.a0) + _ease(u) * 0.9
	var r := lerpf(2.6, 1.8, u)
	var pos := base + Vector3(cos(a) * r, 0.5 + u * 0.9, sin(a) * r)
	_cam_to(pos + _hand(t, 0.008), base + Vector3(0.0, _ease(u) * 1.8, 0.0), lerpf(62.0, 46.0, u))

# ------------------------------------------------------------------ cutscene: death
func _cs_begin_death() -> void:
	_cs_dur = 4.6
	var killer: Vector3 = _cs_ctx.killer
	_cs_ctx["dir"] = (killer - Vector3(0.0, killer.y, 0.0)) - (_cs_ctx.from - Vector3(0.0, _cs_ctx.from.y, 0.0))
	post_mat.set_shader_parameter("flash", 0.9)
	post_mat.set_shader_parameter("glitch", 0.4)
	_fade_a = 0.0
	cine_fade.color = Color(0, 0, 0, 0)
	_dof(true, 2.5, 0.12)

func _cs_step_death(t: float) -> void:
	var from: Vector3 = _cs_ctx.from
	var killer: Vector3 = _cs_ctx.killer
	var fall := _ease(t / 0.7)
	var away := (from - killer)
	away.y = 0.0
	if away.length() > 0.01:
		away = away.normalized()
	var pos := from + away * 0.45 * fall
	pos.y = lerpf(from.y, 0.28, fall)
	_cam_to(pos, killer, lerpf(72.0, 56.0, fall), fall * 1.2)
	post_mat.set_shader_parameter("flash", maxf(0.0, 0.9 - t * 0.3))
	post_mat.set_shader_parameter("desat", clampf(t * 0.3, 0.0, 0.9))
	post_mat.set_shader_parameter("glitch", 0.4 if t < 0.8 else 0.0)
	var fa := clampf((t - 2.8) / 1.6, 0.0, 1.0)
	_fade_a = fa
	cine_fade.color = Color(0, 0, 0, fa)

# ------------------------------------------------------------------ cutscene: ending + credits
func _cs_begin_ending() -> void:
	_cs_dur = 31.0
	var good: bool = bool(_cs_ctx.get("true", false))
	_cs_ctx["good"] = good
	_sub_lines(CineData.ENDING_TRUE_SUBS if good else CineData.ENDING_BAD_SUBS)
	player.position = Vector3(18.0, 0.05, 22.6)
	if good:
		butcher.visible = false
		var spots := {
			Color(0.45, 0.9, 1.0): Vector3(5.2, 0.9, 9.5),
			Color(0.8, 0.55, 1.0): Vector3(-6.5, 1.2, 6.0),
			Color(0.7, 1.0, 0.85): Vector3(4.2, 1.0, 5.9),
			Color(1.0, 0.55, 0.7): Vector3(1.75, 0.9, 4.6),
		}
		for col in spots:
			var o := _make_orb(col, 0.16)
			o.position = spots[col]
			o.visible = false
	else:
		butcher.position = Vector3(18.0, 0.05, 14.6)
		butcher.rotation.y = 0.0
		var carry: OmniLight3D = butcher.get_meta("eye_light")
		carry.light_energy = 2.4
	_cs_ctx["amb0"] = _env.ambient_light_color if _env != null else Color(0.12, 0.14, 0.2)
	_dof(true, 30.0, 0.05)
	cine_credits.text = ""
	for line in CineData.CREDITS:
		cine_credits.text += "%s\n%s\n\n" % [str(line[0]), str(line[1])]
	cine_fade.color = Color(0, 0, 0, 1)
	_fade_a = 1.0

func _cs_step_ending(t: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	var good: bool = bool(_cs_ctx.get("good", false))
	var fa := 1.0 - clampf(t / 1.5, 0.0, 1.0)
	if t > _cs_dur - 1.2:
		fa = (t - (_cs_dur - 1.2)) / 1.2
	_fade_a = fa
	cine_fade.color = Color(0, 0, 0, fa)
	var u := _ease(t / 16.0)
	var pos := Vector3(18.0, lerpf(1.3, 10.0, u), lerpf(25.5, 34.0, u))
	_cam_to(pos + _hand(t, 0.02), Vector3(14.0, lerpf(1.6, 4.0, u), 8.0), lerpf(60.0, 48.0, u))
	# Dawn arrives only when the family is at peace.
	var dawn := 0.0
	if good:
		dawn = _ease((t - 2.0) / 12.0)
	if _sky_mat != null:
		_sky_mat.set_shader_parameter("dawn", dawn)
	if _moon != null:
		_moon.light_color = Color(0.45, 0.55, 0.9).lerp(Color(1.0, 0.72, 0.45), dawn)
		_moon.light_energy = lerpf(0.08, 0.7, dawn)
	if _env != null:
		_amb_base = lerpf(0.55, 1.0, dawn)
		_env.ambient_light_color = (_cs_ctx.amb0 as Color).lerp(Color(0.5, 0.42, 0.34), dawn)
		_env.fog_light_color = Color(0.05, 0.055, 0.07).lerp(Color(0.55, 0.45, 0.38), dawn)
	if good:
		var i := 0
		for o in _orbs:
			var node := o as Node3D
			node.visible = t > 5.0 + i * 0.8
			var start: Vector3 = node.position if node.get_meta("start", null) == null else node.get_meta("start")
			if node.get_meta("start", null) == null:
				node.set_meta("start", start)
			var k := maxf(0.0, t - 5.0 - i * 0.8)
			node.position = start + Vector3(sin(k * 1.3 + i) * 0.5, k * 1.6, cos(k + i) * 0.5)
			i += 1
	# Credits roll after the crane shot.
	if t >= 16.0:
		cine_credits.visible = true
		cine_credits.position = Vector2(0.0, vp.y + 20.0 - (t - 16.0) * 78.0)
		cine_credits.size = Vector2(vp.x, 600.0)
