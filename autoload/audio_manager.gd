extends Node
## Lightweight procedural horror audio manager (zero external asset/network dependencies).

var _sfx_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = -26.0
	_ambient_player.stream = _make_ambient_loop()
	add_child(_ambient_player)
	_ambient_player.play()
	apply_volume(GameState.master_volume)


func _make_ambient_loop() -> AudioStreamWAV:
	# A tiny precomputed-in-memory loop avoids per-frame synthesis and external audio downloads.
	var rate := 8000
	var frames := rate * 3
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var time := float(i) / float(rate)
		var low := sin(time * TAU * 43.0) * 0.34
		var overtone := sin(time * TAU * 47.0) * 0.12
		var breath := 0.65 + 0.35 * sin(time * TAU / 3.0)
		data[i] = clampi(int(((low + overtone) * breath * 0.5 + 0.5) * 255.0), 0, 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	stream.data = data
	return stream


func apply_volume(linear: float) -> void:
	var clamped := clampf(linear, 0.0, 1.0)
	var db := linear_to_db(maxf(clamped, 0.0001))
	AudioServer.set_bus_volume_db(0, db)


func play_sfx(sfx_name: String) -> void:
	var freq := 220.0
	var duration := 0.15
	match sfx_name:
		"interact":
			freq = 520.0
			duration = 0.09
		"pickup":
			freq = 680.0
			duration = 0.12
		"flashlight":
			freq = 900.0
			duration = 0.04
		"attack":
			freq = 140.0
			duration = 0.12
		"fire":
			freq = 95.0
			duration = 0.09
		"reload":
			freq = 360.0
			duration = 0.16
		"hit":
			freq = 110.0
			duration = 0.14
		"damage":
			freq = 85.0
			duration = 0.22
		"heal":
			freq = 440.0
			duration = 0.2
		"resurrect":
			freq = 180.0
			duration = 0.45
		"unlock":
			freq = 600.0
			duration = 0.18
		"error":
			freq = 130.0
			duration = 0.18
		_:
			freq = 300.0
			duration = 0.1

	var stream := AudioStreamWAV.new()
	var sample_rate := 11025
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (float(i) / float(count))
		var val := sin(t * freq * TAU) * env * 0.45
		var byte_val := clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)
		data[i] = byte_val
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	_sfx_player.stream = stream
	_sfx_player.volume_db = -6.0
	_sfx_player.play()
