class_name SoundManager
extends Node

var muted := false
var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = 0.35
	player.stream = generator
	player.volume_db = -8.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func toggle() -> bool:
	muted = not muted
	player.volume_db = -80.0 if muted else -8.0
	return not muted

func play_slash() -> void: _tone(720.0, 320.0, 0.16, "saw")
func play_skill(path_type: int) -> void: _chime(240.0 + float(path_type) * 90.0, 0.28)
func play_hit() -> void: _tone(110.0, 65.0, 0.13, "noise")
func play_chest_open() -> void: _chime(440.0, 0.5)
func play_equip() -> void: _tone(560.0, 780.0, 0.18, "square")
func play_level_up() -> void:
	_chime(520.0, 0.22)
	get_tree().create_timer(0.12).timeout.connect(func() -> void: _chime(780.0, 0.3))

func _tone(start_frequency: float, end_frequency: float, duration: float, waveform: String) -> void:
	if playback == null or muted: return
	var samples := maxi(roundi(generator.mix_rate * duration), 1)
	for index in range(samples):
		var t := float(index) / float(samples)
		var frequency := lerpf(start_frequency, end_frequency, t)
		var phase := TAU * frequency * float(index) / generator.mix_rate
		var value := sin(phase)
		if waveform == "square": value = 1.0 if value >= 0.0 else -1.0
		elif waveform == "saw": value = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		elif waveform == "noise": value = randf_range(-1.0, 1.0)
		var envelope := minf(t * 18.0, 1.0) * (1.0 - t)
		var sample := value * envelope * 0.28
		playback.push_frame(Vector2(sample, sample))

func _chime(frequency: float, duration: float) -> void:
	_tone(frequency, frequency * 1.02, duration, "sine")
