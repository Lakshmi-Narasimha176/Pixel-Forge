extends Node
## Centralized, immersive 3D/2D horror audio manager for THE LAST REVENGE.
## Manages surface footsteps, dynamic horror ambience, boss & combat tracks,
## jumpscares, weapons, interactions, UI, spatial 3D audio, and low-health heartbeat.

signal low_health_mode_changed(active: bool)

# Audio Buses
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_AMBIENT := "Ambient"
const BUS_UI := "UI"

# Stream players
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _ambient_fade_tween: Tween
var _heartbeat_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
const SFX_POOL_SIZE: int = 16

# Sound asset libraries (loaded into memory for instant zero-latency playback)
var _footsteps: Dictionary = {} # surface -> Array[AudioStream]
var _last_footstep_index: Dictionary = {} # surface -> int
var _ambient_tracks: Dictionary = {}
var _music_tracks: Dictionary = {}
var _jumpscares: Array[AudioStream] = []
var _enemy_sfx: Dictionary = {}
var _weapon_sfx: Dictionary = {}
var _interaction_sfx: Dictionary = {}
var _ui_sfx: Dictionary = {}
var _player_sfx: Dictionary = {}

var _is_low_health: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_dedicated_players()
	_load_sound_assets()

	# Connect to global GameState signals
	if GameState:
		GameState.health_changed.connect(_on_health_changed)
		GameState.player_resurrected.connect(func(_cnt): set_low_health_mode(false))
		GameState.player_died.connect(func(): set_low_health_mode(false))


# ─────────────────────────────────────────────────────────────
# Bus Management & Volume Controls
# ─────────────────────────────────────────────────────────────

func _setup_audio_buses() -> void:
	_ensure_bus(BUS_MUSIC, BUS_MASTER)
	_ensure_bus(BUS_SFX, BUS_MASTER)
	_ensure_bus(BUS_AMBIENT, BUS_MASTER)
	_ensure_bus(BUS_UI, BUS_MASTER)


func _ensure_bus(bus_name: String, parent_bus: String = "Master") -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, parent_bus)
	return idx


func set_master_volume(linear: float) -> void:
	_set_bus_linear_volume(BUS_MASTER, linear)
	if GameState:
		GameState.master_volume = linear


func set_music_volume(linear: float) -> void:
	_set_bus_linear_volume(BUS_MUSIC, linear)


func set_sfx_volume(linear: float) -> void:
	_set_bus_linear_volume(BUS_SFX, linear)


func set_ambient_volume(linear: float) -> void:
	_set_bus_linear_volume(BUS_AMBIENT, linear)


func apply_volume(linear: float) -> void:
	set_master_volume(linear)


func _set_bus_linear_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var clamped := clampf(linear, 0.0, 1.0)
		var db := linear_to_db(maxf(clamped, 0.0001))
		AudioServer.set_bus_volume_db(idx, db)


# ─────────────────────────────────────────────────────────────
# Dedicated Audio Players & SFX Pool
# ─────────────────────────────────────────────────────────────

func _create_dedicated_players() -> void:
	# Music Player
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	# Ambient Player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = BUS_AMBIENT
	_ambient_player.volume_db = -6.0
	add_child(_ambient_player)

	# Heartbeat Player (Looping low-health audio)
	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.name = "HeartbeatPlayer"
	_heartbeat_player.bus = BUS_SFX
	_heartbeat_player.volume_db = -8.0
	add_child(_heartbeat_player)

	# Fixed SFX Player Pool for low RAM / CPU allocation
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)


func _get_pooled_player(bus: String = BUS_SFX) -> AudioStreamPlayer:
	var p := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	p.stop()
	p.bus = bus
	p.pitch_scale = 1.0
	p.volume_db = 0.0
	return p


# ─────────────────────────────────────────────────────────────
# Asset Loading
# ─────────────────────────────────────────────────────────────

func _load_sound_assets() -> void:
	# Footsteps by surface
	_footsteps["concrete"] = _load_dir("res://assets/audio/footsteps/concrete")
	_footsteps["wood"] = _load_dir("res://assets/audio/footsteps/wood")
	_footsteps["grass"] = _load_dir("res://assets/audio/footsteps/grass")
	_footsteps["dirt"] = _load_dir("res://assets/audio/footsteps/dirt")
	_footsteps["carpet"] = _load_dir("res://assets/audio/footsteps/carpet")
	_footsteps["stone"] = _footsteps["concrete"]
	_footsteps["metal"] = _load_matching("res://assets/audio/interaction", "impactMetal")

	for s in _footsteps.keys():
		_last_footstep_index[s] = -1

	# Ambient & Music
	_ambient_tracks["lost"] = _safe_load("res://assets/audio/ambient/lost_2.ogg")
	_ambient_tracks["freezer"] = _safe_load("res://assets/audio/ambient/freezer_0.ogg")
	_ambient_tracks["horror"] = _safe_load("res://assets/audio/ambient/ambient_horror_0.ogg")
	_ambient_tracks["evil"] = _safe_load("res://assets/audio/ambient/evil_0.ogg")

	_music_tracks["suspense"] = _ambient_tracks["lost"]
	_music_tracks["exploration"] = _ambient_tracks["freezer"]
	_music_tracks["combat"] = _ambient_tracks["horror"]
	_music_tracks["boss"] = _ambient_tracks["evil"]

	# Jumpscares
	_jumpscares.append(_safe_load("res://assets/audio/jumpscare/horror_effect1.ogg"))
	_jumpscares.append(_safe_load("res://assets/audio/jumpscare/horror_effect2.ogg"))
	_jumpscares.append(_safe_load("res://assets/audio/jumpscare/scream.ogg"))

	# Enemies
	_enemy_sfx["growl"] = _safe_load("res://assets/audio/enemy/monster_growl.ogg")
	_enemy_sfx["fast"] = _safe_load("res://assets/audio/enemy/fastzombie1.ogg")
	_enemy_sfx["zombie1"] = _safe_load("res://assets/audio/enemy/zombienoise1.ogg")
	_enemy_sfx["zombie2"] = _safe_load("res://assets/audio/enemy/zombienoise2.ogg")
	_enemy_sfx["zombie3"] = _safe_load("res://assets/audio/enemy/zombienoise3.ogg")

	# Guns & Weapons
	_weapon_sfx["pistol"] = _safe_load("res://assets/audio/guns/pistol_fire.ogg")
	_weapon_sfx["magnum"] = _safe_load("res://assets/audio/guns/magnum_fire.ogg")
	_weapon_sfx["shotgun"] = _safe_load("res://assets/audio/guns/shotty.ogg")
	_weapon_sfx["rifle"] = _safe_load("res://assets/audio/guns/mosin.ogg")
	_weapon_sfx["knife_draw"] = _safe_load("res://assets/audio/melee/drawKnife1.ogg")
	_weapon_sfx["knife_slice"] = _safe_load("res://assets/audio/melee/knifeSlice.ogg")
	_weapon_sfx["chop"] = _safe_load("res://assets/audio/melee/chop.ogg")
	_weapon_sfx["punch"] = _safe_load("res://assets/audio/melee/impactPunch_heavy_000.ogg")
	_weapon_sfx["body_hit"] = _safe_load("res://assets/audio/melee/impactSoft_heavy_000.ogg")

	# Interactions
	_interaction_sfx["door_open"] = _safe_load("res://assets/audio/interaction/doorOpen_1.ogg")
	_interaction_sfx["door_close"] = _safe_load("res://assets/audio/interaction/doorClose_1.ogg")
	_interaction_sfx["creak"] = _safe_load("res://assets/audio/interaction/creak1.ogg")
	_interaction_sfx["switch"] = _safe_load("res://assets/audio/ui/switch_001.ogg")
	_interaction_sfx["pickup"] = _safe_load("res://assets/audio/interaction/metalClick.ogg")
	_interaction_sfx["unlock"] = _safe_load("res://assets/audio/interaction/metalLatch.ogg")
	_interaction_sfx["flashlight"] = _safe_load("res://assets/audio/ui/switch_002.ogg")

	# UI
	_ui_sfx["click"] = _safe_load("res://assets/audio/ui/click1.ogg")
	_ui_sfx["confirm"] = _safe_load("res://assets/audio/ui/confirmation_001.ogg")
	_ui_sfx["error"] = _safe_load("res://assets/audio/ui/error_001.ogg")
	_ui_sfx["back"] = _safe_load("res://assets/audio/ui/back_001.ogg")

	# Player
	_player_sfx["heartbeat_slow"] = _safe_load("res://assets/audio/player/heartbeat_slow.ogg")
	_player_sfx["heartbeat_fast"] = _safe_load("res://assets/audio/player/heartbeat_fast.ogg")
	_player_sfx["jump"] = _safe_load("res://assets/audio/melee/impactSoft_medium_000.ogg")
	_player_sfx["land"] = _safe_load("res://assets/audio/melee/impactSoft_heavy_001.ogg")

	# Auto-start Level 1 Horror Ambience Loop
	start_ambient("lost")


func _safe_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func _load_dir(dir_path: String) -> Array[AudioStream]:
	var list: Array[AudioStream] = []
	var d := DirAccess.open(dir_path)
	if d:
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir() and (fname.ends_with(".ogg") or fname.ends_with(".wav")):
				var full_path := dir_path.path_join(fname)
				var stream := _safe_load(full_path)
				if stream:
					list.append(stream)
			fname = d.get_next()
	return list


func _load_matching(dir_path: String, prefix: String) -> Array[AudioStream]:
	var list: Array[AudioStream] = []
	var d := DirAccess.open(dir_path)
	if d:
		d.list_dir_begin()
		var fname := d.get_next()
		while fname != "":
			if not d.current_is_dir() and fname.begins_with(prefix) and (fname.ends_with(".ogg") or fname.ends_with(".wav")):
				var full_path := dir_path.path_join(fname)
				var stream := _safe_load(full_path)
				if stream:
					list.append(stream)
			fname = d.get_next()
	return list


# ─────────────────────────────────────────────────────────────
# Footsteps & Surface Detection
# ─────────────────────────────────────────────────────────────

func play_footstep(surface: String = "concrete", is_sprint: bool = false, is_crouch: bool = false) -> void:
	var key := surface.to_lower()
	if not _footsteps.has(key) or _footsteps[key].is_empty():
		key = "concrete"
	var list: Array[AudioStream] = _footsteps[key]
	if list.is_empty():
		return

	# Randomized selection without immediate repetition
	var last_idx: int = _last_footstep_index.get(key, -1)
	var next_idx := randi() % list.size()
	if list.size() > 1 and next_idx == last_idx:
		next_idx = (next_idx + 1) % list.size()
	_last_footstep_index[key] = next_idx

	var p := _get_pooled_player(BUS_SFX)
	p.stream = list[next_idx]
	p.pitch_scale = randf_range(0.92, 1.08)

	# Volume & Pitch modulation by movement type
	if is_crouch:
		p.volume_db = -12.0
		p.pitch_scale *= 0.88
	elif is_sprint:
		p.volume_db = 1.5
		p.pitch_scale *= 1.10
	else:
		p.volume_db = -4.0

	p.play()


# ─────────────────────────────────────────────────────────────
# Weapons & Combat
# ─────────────────────────────────────────────────────────────

func play_gun_fire(type: String = "pistol") -> void:
	var stream: AudioStream = _weapon_sfx.get(type, _weapon_sfx.get("pistol"))
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.pitch_scale = randf_range(0.95, 1.05)
		p.volume_db = 2.0
		p.play()


func play_melee_swing() -> void:
	var stream: AudioStream = _weapon_sfx.get("knife_slice")
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.pitch_scale = randf_range(0.9, 1.1)
		p.volume_db = -2.0
		p.play()


func play_melee_hit() -> void:
	var stream: AudioStream = _weapon_sfx.get("punch")
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.pitch_scale = randf_range(0.9, 1.05)
		p.volume_db = 0.0
		p.play()


# ─────────────────────────────────────────────────────────────
# Horror Ambience & Music Loops
# ─────────────────────────────────────────────────────────────

func start_ambient(track_name: String = "lost", fade_time: float = 2.0) -> void:
	var stream: AudioStream = _ambient_tracks.get(track_name, _ambient_tracks.get("lost"))
	if not stream or _ambient_player.stream == stream and _ambient_player.playing:
		return

	if _ambient_fade_tween:
		_ambient_fade_tween.kill()

	_ambient_fade_tween = create_tween()
	if _ambient_player.playing:
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -36.0, fade_time * 0.5)
		_ambient_fade_tween.tween_callback(func():
			_ambient_player.stream = stream
			_ambient_player.play()
		)
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -6.0, fade_time * 0.5)
	else:
		_ambient_player.volume_db = -36.0
		_ambient_player.stream = stream
		_ambient_player.play()
		_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -6.0, fade_time)


func stop_ambient(fade_time: float = 1.5) -> void:
	if not _ambient_player.playing:
		return
	if _ambient_fade_tween:
		_ambient_fade_tween.kill()
	_ambient_fade_tween = create_tween()
	_ambient_fade_tween.tween_property(_ambient_player, "volume_db", -40.0, fade_time)
	_ambient_fade_tween.tween_callback(func(): _ambient_player.stop())


func play_music(track_name: String = "suspense", fade_time: float = 2.0) -> void:
	var stream: AudioStream = _music_tracks.get(track_name)
	if not stream or _music_player.stream == stream and _music_player.playing:
		return

	var tween := create_tween()
	if _music_player.playing:
		tween.tween_property(_music_player, "volume_db", -36.0, fade_time * 0.5)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.play()
		)
		tween.tween_property(_music_player, "volume_db", -4.0, fade_time * 0.5)
	else:
		_music_player.volume_db = -36.0
		_music_player.stream = stream
		_music_player.play()
		tween.tween_property(_music_player, "volume_db", -4.0, fade_time)


# ─────────────────────────────────────────────────────────────
# Jumpscares & Enemy Audio
# ─────────────────────────────────────────────────────────────

func play_jumpscare() -> void:
	if _jumpscares.is_empty():
		return
	var stream: AudioStream = _jumpscares[randi() % _jumpscares.size()]
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.volume_db = 4.0
		p.pitch_scale = randf_range(0.96, 1.04)
		p.play()


func play_enemy_sfx(_type: String, action: String = "growl") -> void:
	var key := action
	var stream: AudioStream = _enemy_sfx.get(key, _enemy_sfx.get("growl"))
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.pitch_scale = randf_range(0.85, 1.05)
		p.volume_db = 1.0
		p.play()


# ─────────────────────────────────────────────────────────────
# Player Health & Heartbeat Loop
# ─────────────────────────────────────────────────────────────

func _on_health_changed(hp: int, _max_hp: int) -> void:
	set_low_health_mode(hp <= 30 and hp > 0)


func set_low_health_mode(active: bool) -> void:
	if _is_low_health == active:
		return
	_is_low_health = active
	low_health_mode_changed.emit(active)

	if active:
		var stream: AudioStream = _player_sfx.get("heartbeat_fast")
		if stream:
			_heartbeat_player.stream = stream
			_heartbeat_player.volume_db = -6.0
			_heartbeat_player.play()
	else:
		if _heartbeat_player.playing:
			var tween := create_tween()
			tween.tween_property(_heartbeat_player, "volume_db", -36.0, 0.8)
			tween.tween_callback(func(): _heartbeat_player.stop())


# ─────────────────────────────────────────────────────────────
# Interactions & UI
# ─────────────────────────────────────────────────────────────

func play_interaction_sfx(sound_name: String) -> void:
	var stream: AudioStream = _interaction_sfx.get(sound_name)
	if stream:
		var p := _get_pooled_player(BUS_SFX)
		p.stream = stream
		p.pitch_scale = randf_range(0.95, 1.05)
		p.play()


func play_ui_sfx(action: String = "click") -> void:
	var stream: AudioStream = _ui_sfx.get(action, _ui_sfx.get("click"))
	if stream:
		var p := _get_pooled_player(BUS_UI)
		p.stream = stream
		p.play()


# ─────────────────────────────────────────────────────────────
# 3D Spatial Audio
# ─────────────────────────────────────────────────────────────

func play_3d(sound_name: String, global_pos: Vector3, bus: String = BUS_SFX, max_dist: float = 24.0, vol_db: float = 0.0) -> AudioStreamPlayer3D:
	var stream: AudioStream = null
	if _weapon_sfx.has(sound_name): stream = _weapon_sfx[sound_name]
	elif _interaction_sfx.has(sound_name): stream = _interaction_sfx[sound_name]
	elif _enemy_sfx.has(sound_name): stream = _enemy_sfx[sound_name]
	elif _ui_sfx.has(sound_name): stream = _ui_sfx[sound_name]

	if not stream:
		return null

	var p3d := AudioStreamPlayer3D.new()
	p3d.stream = stream
	p3d.bus = bus
	p3d.max_distance = max_dist
	p3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p3d.volume_db = vol_db
	get_tree().root.add_child(p3d)
	p3d.global_position = global_pos
	p3d.play()
	p3d.finished.connect(func(): p3d.queue_free())
	return p3d


# ─────────────────────────────────────────────────────────────
# Backwards Compatibility API
# ─────────────────────────────────────────────────────────────

func play_sfx(sfx_name: String) -> void:
	match sfx_name:
		"flashlight":
			play_interaction_sfx("flashlight")
		"attack":
			play_melee_swing()
		"hit":
			play_melee_hit()
		"damage":
			var p := _get_pooled_player(BUS_SFX)
			p.stream = _player_sfx.get("heartbeat_slow")
			p.volume_db = 1.0
			p.play()
		"heal":
			play_interaction_sfx("pickup")
		"resurrect":
			play_jumpscare()
		"pickup":
			play_interaction_sfx("pickup")
		"unlock":
			play_interaction_sfx("unlock")
		"error":
			play_ui_sfx("error")
		"jump":
			var p := _get_pooled_player(BUS_SFX)
			p.stream = _player_sfx.get("jump")
			p.play()
		"land":
			var p := _get_pooled_player(BUS_SFX)
			p.stream = _player_sfx.get("land")
			p.play()
		_:
			# Fallback generic click
			play_ui_sfx("click")
