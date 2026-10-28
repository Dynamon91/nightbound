extends Node
## Original procedural soundtrack generator for early Nightbound builds.
## Produces original, loop-oriented music from synthesized tones with syncopated bass and counter-plucks; no samples or
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
var _section_offset := 0

func setup(player: AudioStreamPlayer, track_id: String) -> void:
	_player = player
	_track_id = track_id
	_sample_cursor = 0
	_section_offset = 0
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

func set_section(section_index: int) -> void:
	_section_offset = maxi(section_index, 0)

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
	var section := (int(floor(float(bar) / 16.0)) + _section_offset) % 8
	var root: float = data["root"]
	var mode: Array = data["mode"]
	var motif: Array = data["motif"]
	var energy := 0.62 if section % 4 == 1 else (0.78 if section % 4 == 2 else 0.48)
	var output := 0.0

	var bass_degree := [0, 0, 3, 4, 0, 5, 3, 4][int(bar % 8)]
	var bass_freq := root * 0.5 * pow(2.0, float(mode[bass_degree % mode.size()]) / 12.0)
	var bass_phase := TWO_PI * bass_freq * real_time
	var bass_subdivision := fposmod(beat * 2.0, 1.0)
	var bass_attack := 0.58 if bass_subdivision > 0.42 else 1.0
	var bass_bar_beat := int(floor(beat)) % beats_per_bar
	if bass_bar_beat == 1 and bass_subdivision < 0.18:
		bass_attack *= 0.68
	output += (sin(bass_phase) * 0.105 + sin(bass_phase * 2.0) * 0.025) * bass_attack * (0.72 + energy * 0.35)

	var motif_index := int(floor(beat * 0.5 + (1.0 if section % 4 == 2 else 0.0))) % motif.size()
	var melody_step := int(motif[motif_index])
	var melody_gate := fposmod(beat * 2.0, 2.0)
	var phrase_gate := fposmod(beat, 8.0)
	var melody_active := melody_gate < (0.62 if section % 4 == 0 else 0.82) and phrase_gate < 6.8
	if melody_active:
		var octave := 2.0 if section % 4 == 2 else 1.0
		var melody_freq := root * octave * pow(2.0, float(melody_step) / 12.0)
		var local_beat := fposmod(beat * 2.0, 1.0)
		var envelope := exp(-local_beat * 4.2)
		var bell := sin(TWO_PI * melody_freq * real_time) * 0.045
		if _track_id == "veilwood_level_2":
			bell += sin(TWO_PI * melody_freq * 1.5 * real_time + 0.35) * 0.010
			bell += sin(TWO_PI * melody_freq * 2.98 * real_time) * 0.006
		elif _track_id.find("boss") >= 0:
			bell += sin(TWO_PI * melody_freq * 2.7 * real_time) * 0.018
			bell += sin(TWO_PI * melody_freq * 4.03 * real_time + 0.2) * 0.008
		else:
			bell += sin(TWO_PI * melody_freq * 2.01 * real_time) * 0.013
			bell += sin(TWO_PI * melody_freq * 3.97 * real_time) * 0.004
		output += bell * envelope * energy

	var counter_step := int(floor(beat * 2.0))
	var counter_phase := fposmod(beat * 2.0, 1.0)
	var counter_gate := counter_phase < (0.16 if section % 4 == 0 else 0.23)
	if counter_gate and counter_step % 4 == (1 if beats_per_bar != 7 else 3):
		var counter_degree := int(motif[(counter_step + bar) % motif.size()])
		var counter_freq := root * 2.0 * pow(2.0, float(counter_degree) / 12.0)
		var counter_env := exp(-counter_phase * 28.0)
		output += (sin(TWO_PI * counter_freq * real_time) * 0.018 + sin(TWO_PI * counter_freq * 2.0 * real_time) * 0.006) * counter_env * energy

	var chord_degree := [0, 3, 5, 4][int(floor(float(bar) / 8.0)) % 4]
	var pad_freq := root * pow(2.0, float(mode[chord_degree % mode.size()]) / 12.0)
	output += sin(TWO_PI * pad_freq * 0.5 * real_time) * 0.035
	output += sin(TWO_PI * pad_freq * 0.75 * real_time + 0.7) * 0.018
	output += sin(TWO_PI * pad_freq * 1.5 * real_time + 1.1) * 0.012
	if _track_id == "veilwood_level_2":
		output += sin(TWO_PI * pad_freq * 2.0 * real_time + 0.4) * 0.009
	elif _track_id.find("boss") >= 0:
		output += sin(TWO_PI * pad_freq * 1.414 * real_time) * 0.012

	var beat_fraction := fposmod(beat, 1.0)
	var beat_in_bar_index := int(floor(beat)) % beats_per_bar
	var bar_in_phrase := bar % 8
	var downbeat := beat_in_bar_index == 0
	var backbeat := beat_in_bar_index == (3 if beats_per_bar == 4 else (3 if beats_per_bar == 6 else beats_per_bar - 1))
	var kick_pattern := downbeat or (section > 0 and backbeat and bar_in_phrase % 2 == 0)
	if beats_per_bar == 7:
		kick_pattern = downbeat or (beat_in_bar_index == 4 and bar_in_phrase % 2 == 1)
	elif beats_per_bar == 5:
		kick_pattern = downbeat or (beat_in_bar_index == 3 and bar_in_phrase % 2 == 0)
	if beat_fraction < 0.14 and kick_pattern:
		var kick_env := exp(-beat_fraction * 38.0)
		var kick_freq := 72.0 - 34.0 * minf(beat_fraction * 5.0, 1.0)
		output += sin(TWO_PI * kick_freq * real_time) * kick_env * (0.15 if bar_in_phrase == 7 else 0.17)

	var click_phase := fposmod(beat * 2.0, 1.0)
	var click_step := int(floor(beat * 2.0)) % (beats_per_bar * 2)
	var click_pattern := click_step % 4 == 1
	if beats_per_bar == 6:
		click_pattern = click_step % 6 == 2 or click_step % 6 == 5
	elif beats_per_bar == 7:
		click_pattern = click_step % 7 == 3 or click_step % 7 == 6
	elif beats_per_bar == 5:
		click_pattern = click_step % 5 == 1 or click_step % 5 == 4
	if bar_in_phrase == 7 and click_step >= (beats_per_bar * 2 - 2):
		click_pattern = false
	elif bar_in_phrase == 0 and click_step < 2 and section % 4 != 0:
		click_pattern = click_pattern or click_step == 1
	if click_phase < 0.10 and click_pattern:
		output += sin(TWO_PI * (680.0 + float((bar + step) % 5) * 73.0) * real_time) * exp(-click_phase * 45.0) * 0.035

	var hat_phase := fposmod(beat * 4.0, 1.0)
	if hat_phase < 0.075:
		var hash_value := sin(float(int(t * SAMPLE_RATE) % 997) * 12.9898) * 43758.5453
		var noise_value := (fposmod(hash_value, 2.0) - 1.0)
		output += noise_value * exp(-hat_phase * 55.0) * 0.012 * (1.0 if section % 4 != 3 else 0.45)

	output += sin(TWO_PI * root * 4.0 * real_time) * 0.004 * (0.5 + energy)
	return clampf(output, -0.82, 0.82)
