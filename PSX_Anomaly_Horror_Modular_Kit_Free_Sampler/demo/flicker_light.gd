extends Light3D
## Light that flickers like a failing bulb or tube (mode 0), a flame (mode 1: candles, jack-o'-lanterns), pulses
## slowly (mode 2) or stays steady (mode 3). dip() makes any of them stutter for a moment (the anomaly loop does it
## when a new loop starts). PSX Anomaly Horror Texture Pack demo (bitkiln - https://bitkiln.itch.io).
## Works on OmniLight3D and SpotLight3D.

@export_enum("Failing bulb", "Flame", "Pulse", "Steady") var mode := 0
@export var flicker_seed := 1
## Pulse mode: pulses per second and the lowest energy (fraction of the light's energy).
@export var pulse_speed := 0.35
@export var pulse_low := 0.35

var _base := 1.0
var _wait := 0.0
var _level := 1.0
var _time := 0.0
var _state := 1
var _dip := 0.0


func _ready() -> void:
	_base = light_energy
	_state = maxi(1, flicker_seed & 0x7fffffff)
	_time = float(flicker_seed) * 0.37


## The light stutters (off, on, off, on) for the given seconds, then goes on as before.
func dip(seconds := 0.6) -> void:
	_dip = seconds


func _process(delta: float) -> void:
	_time += delta
	if _dip > 0.0:
		_dip -= delta
		var k := int(_dip * 14.0) % 3
		light_energy = _base * (0.05 if k == 0 else (0.3 if k == 1 else 0.85))
		if _dip <= 0.0:
			light_energy = _base
		return
	if mode == 3:
		return
	if mode == 2:
		var s := 0.5 + 0.5 * sin(_time * TAU * pulse_speed)
		light_energy = _base * lerpf(pulse_low, 1.0, s * s)
		return
	if mode == 1:
		_wait -= delta
		if _wait <= 0.0:
			_wait = _range(0.05, 0.12)
			_level = _range(0.78, 1.08)
		light_energy = lerpf(light_energy, _base * _level, 1.0 - exp(-14.0 * delta))
		return
	_wait -= delta
	if _wait > 0.0:
		return
	if _randf() < 0.14:
		light_energy = _base * _range(0.04, 0.35)
		_wait = _range(0.03, 0.11)
	else:
		light_energy = _base * _range(0.93, 1.04)
		_wait = _range(0.15, 1.8)


# a small seeded random source per light, so every light flickers in its own rhythm
func _randf() -> float:
	_state = (_state * 1103515245 + 12345) & 0x7fffffff
	return float(_state) / 2147483648.0


func _range(from: float, to: float) -> float:
	return from + (to - from) * _randf()
