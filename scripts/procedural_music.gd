extends Node
## Original procedural soundtrack generator for early Nightbound builds.
## Produces deterministic, loopable music from synthesized tones; no samples or
## third-party recordings. Each theme uses its own tempo, mode and motif.

const SAMPLE_RATE := 22050.0
const TWO_PI := TAU
const TRACK_DATA := {
	"moonlit_valley_level_1": {"bpm": 108.0, "beats_per_bar": 4, "bars": 128, "root": 73.42, "mode": [0, 2, 3, 7, 9, 10], "motif": [9, 0, 3, 2, 9, 10, 0]},
	"veilwood_level_2": {"bpm": 76.0, "beats_per_bar": 6, "bars": 128, "root": 55.0, "mode": [0, 2, 3, 5, 7, 8, 11], "motif": [7, 0, 3, 2, 7, 5, 0]},
	"moonlit_valley_boss_1": {"bpm": 132.0, "beats_per_bar": 7, "bars": 112, "root": 73.42, "mode": [0, 3, 5, 7, 8, 10], "motif": [0, 3, 7, 6, 7, 10, 3]},
	"veilwood_boss_2": {"bpm": 116.0, "beats_per_bar": 5, "bars": 112, "root": 55.0, "mode": [0, 2, 3, 5, 7, 8, 11], "motif": [0, 3, 2, 7, 5, 7, 3]}
}

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _track_id := "moonlit_valley_level_1"
var _sample_cursor := 0
var _active := false
var _last_kick_bar := -1

func setup(player: AudioStreamPlayer, track_id: String) -> void:
	_player = player
	_track_id = track_id
	_sample_cursor = 0
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.6
	_player.stream = stream
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_active = _playback != null
	set_process(_active)

func stop_generation() -> void:
	_active = false
	set_process(false)

func _process(_delta: float) -> void:
	if not _active or not is_instance_valid(_player) or _playback == null:
		return
	var available := _playback.get_frames_available()
	for frame in range(available):
		var sample := _render_sample(float(_sample_cursor) / SAMPLE_RATE)
		_playback.push_frame(Vector2(sample, sample * 0.985))
		_sample_cursor += 1

func _render_sample(real_time: float) -> float:
	var data: Dictionary = TRACK_DATA.get(_track_id, TRACK_DATA["moonlit_valley_level_1"])
	var bpm: float = data["bpm"]
	var beats_per_bar: int = data["beats_per_bar"]
	var bar_seconds := 60.0 / bpm * float(beats_per_bar)
	var song_seconds := bar_seconds * float(data["bars"])
	var t := fposmod(real_time, song_seconds)
	var beat := t * bpm / 60.0
	var bar := int(floor(beat / float(beats_per_bar)))
	var beat_in_bar := fposmod(beat, float(beats_per_bar))
	var step := int(floor(beat * 2.0))
	var section := int(floor(float(bar) / 16.0))
	var root: float = data["root"]
	var mode: Array = data["mode"]
	var motif: Array = data["motif"]
	var energy := 0.62 if section % 4 == 1 else (0.78 if section % 4 == 2 else 0.48)
	var output := 0.0

	# Warm, softly saturated bass ostinato with phrase changes every 8 bars.
	var bass_degree := [0, 0, 3, 4, 0, 5, 3, 4][int(bar % 8)]
	var bass_freq := root * 0.5 * pow(2.0, float(mode[bass_degree % mode.size()]) / 12.0)
	var bass_phase := TWO_PI * bass_freq * t
	output += (sin(bass_phase) * 0.105 + sin(bass_phase * 2.0) * 0.025) * (0.72 + energy * 0.35)

	# A melody with intentional rests; each 16-bar section changes register and density.
	var motif_index := int(floor(beat * 0.5)) % motif.size()
	var melody_step := int(motif[motif_index])
	var melody_gate := fposmod(beat * 2.0, 2.0)
	var phrase_gate := fposmod(beat, 8.0)
	var melody_active := melody_gate < (0.62 if section % 4 == 0 else 0.82) and phrase_gate < 6.8
	if melody_active:
		var octave := 2.0 if section % 4 == 2 else 1.0
		var melody_freq := root * octave * pow(2.0, float(melody_step) / 12.0)
		var local_beat := fposmod(beat * 2.0, 1.0)
		var envelope := exp(-local_beat * 4.2)
		var bell := sin(TWO_PI * melody_freq * t) * 0.045
		bell += sin(TWO_PI * melody_freq * 2.01 * t) * 0.013
		bell += sin(TWO_PI * melody_freq * 3.97 * t) * 0.004
		output += bell * envelope * energy

	# Slow harmonic bed shifts on eight-bar boundaries; low amplitude to leave space.
	var chord_degree := [0, 3, 5, 4][int(floor(float(bar) / 8.0)) % 4]
	var pad_freq := root * pow(2.0, float(mode[chord_degree % mode.size()]) / 12.0)
	output += sin(TWO_PI * pad_freq * 0.5 * t) * 0.035
	output += sin(TWO_PI * pad_freq * 0.75 * t + 0.7) * 0.018
	output += sin(TWO_PI * pad_freq * 1.5 * t + 1.1) * 0.012

	# Original synthesized percussion: kick, offbeat wooden click and a short noise-like hat.
	var beat_fraction := fposmod(beat, 1.0)
	var kick_hit := beat_fraction < 0.14 and (int(floor(beat)) % beats_per_bar == 0 or (section > 0 and int(floor(beat)) % beats_per_bar == 2))
	if kick_hit:
		var kick_env := exp(-beat_fraction * 38.0)
		var kick_freq := 72.0 - 34.0 * minf(beat_fraction * 5.0, 1.0)
		output += sin(TWO_PI * kick_freq * t) * kick_env * 0.17
	var click_phase := fposmod(beat * 2.0, 1.0)
	if click_phase < 0.10 and int(floor(beat * 2.0)) % 4 == 1:
		output += sin(TWO_PI * (680.0 + float((bar + step) % 5) * 73.0) * t) * exp(-click_phase * 45.0) * 0.035
	var hat_phase := fposmod(beat * 4.0, 1.0)
	if hat_phase < 0.075:
		var hash_value := sin(float(int(t * SAMPLE_RATE) % 997) * 12.9898) * 43758.5453
		var noise_value := (fposmod(hash_value, 2.0) - 1.0)
		output += noise_value * exp(-hat_phase * 55.0) * 0.012 * (1.0 if section % 4 != 3 else 0.45)

	# Gentle end-of-phrase variation and conservative limiting.
	output += sin(TWO_PI * root * 4.0 * t) * 0.004 * (0.5 + energy)
	return clampf(output, -0.82, 0.82)
