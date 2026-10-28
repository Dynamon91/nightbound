extends Node
class_name NightboundAudioDirector
## Music routing/crossfade framework. Uses original rendered assets when present;
## otherwise starts the in-project procedural score generator for a playable music bed.
const ProceduralMusicScript = preload("res://scripts/procedural_music.gd")
const TRACKS := {
	"moonlit_valley_level_1": "res://audio/music/moonlit_valley_level_1.ogg",
	"moonlit_valley_boss_1": "res://audio/music/moonlit_valley_boss_1.ogg",
	"veilwood_level_2": "res://audio/music/veilwood_level_2.ogg",
	"veilwood_boss_2": "res://audio/music/veilwood_boss_2.ogg",
}
const TRACK_PROFILES := {
	"moonlit_valley_level_1": {"bpm": 108, "meter": "4/4", "character": "playful nocturnal syncopation", "palette": "wood clicks, rounded bass, bright mallet-like synth", "loop_bars": 128},
	"moonlit_valley_boss_1": {"bpm": 132, "meter": "7/8", "character": "restless asymmetric combat drive", "palette": "tight kick, dry percussion, sharp synth stabs", "loop_bars": 112},
	"veilwood_level_2": {"bpm": 76, "meter": "6/8", "character": "mysterious floating forest pulse", "palette": "breathy pads, hand percussion, glassy tones", "loop_bars": 128},
	"veilwood_boss_2": {"bpm": 116, "meter": "5/4", "character": "dark escalating ritual groove", "palette": "metallic accents, low toms, tense ostinato", "loop_bars": 112},
}
const DEFAULT_FADE_SECONDS := 2.5
const SECTION_LENGTH_BARS := 16
var _players: Array[AudioStreamPlayer] = []
var _active_index := 0
var _current_track_id := ""
var _generators: Array[Node] = []
var _current_section := 0
var _section_elapsed := 0.0
var _last_reported_section := -1

func _ready() -> void:
	# Keep music isolated from future SFX/voice buses so later gameplay audio can
	# duck or mute music without changing the soundtrack's own crossfade levels.
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus < 0:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, "Music")
	AudioServer.set_bus_volume_db(music_bus, -1.5)
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % index
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)
		var generator: Node = ProceduralMusicScript.new()
		generator.name = "ProceduralMusic%d" % index
		add_child(generator)
		_generators.append(generator)

func _process(delta: float) -> void:
	if _current_track_id == "" or not _players[_active_index].playing:
		return
	_section_elapsed += delta
	var profile: Dictionary = TRACK_PROFILES.get(_current_track_id, {})
	var bpm: float = float(profile.get("bpm", 100.0))
	var meter := str(profile.get("meter", "4/4"))
	var slash := meter.find("/")
	var beats_per_bar := maxi(1, int(meter.substr(0, slash))) if slash > 0 else 4
	var section_seconds := 60.0 / bpm * float(beats_per_bar * SECTION_LENGTH_BARS)
	if section_seconds <= 0.0:
		return
	var section := int(floor(_section_elapsed / section_seconds)) % 8
	if section != _last_reported_section:
		_last_reported_section = section
		set_section(section)

func get_track_profile(track_id: String) -> Dictionary:
	return TRACK_PROFILES.get(track_id, {})

func get_current_track() -> String:
	return _current_track_id

func play_track(track_id: String, fade_seconds := DEFAULT_FADE_SECONDS) -> bool:
	if track_id == _current_track_id and _players[_active_index].playing:
		return true
	if not TRACKS.has(track_id):
		push_warning("Nightbound music: no track is registered for '%s'." % track_id)
		return false
	var path: String = TRACKS[track_id]
	var has_asset := ResourceLoader.exists(path)
	var stream: AudioStream = load(path) as AudioStream if has_asset else null
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var outgoing_index := _active_index
	var next_index := 1 - outgoing_index
	var outgoing := _players[outgoing_index]
	var incoming := _players[next_index]
	incoming.stop()
	_generators[next_index].stop_generation()
	incoming.volume_db = -60.0
	if stream != null:
		incoming.stream = stream
		incoming.play()
	else:
		_generators[next_index].setup(incoming, track_id)
	var duration := maxf(0.0, fade_seconds)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, duration)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -60.0, duration)
	tween.chain().tween_callback(outgoing.stop)
	tween.chain().tween_callback(_generators[outgoing_index].stop_generation)
	_active_index = next_index
	_current_track_id = track_id
	_current_section = 0
	_section_elapsed = 0.0
	_last_reported_section = -1
	set_section(0)
	return true

func stop_music(fade_seconds := DEFAULT_FADE_SECONDS) -> void:
	var outgoing := _players[_active_index]
	if not outgoing.playing:
		_current_track_id = ""
		return
	var tween := create_tween()
	tween.tween_property(outgoing, "volume_db", -60.0, maxf(0.0, fade_seconds))
	tween.tween_callback(outgoing.stop)
	_current_track_id = ""
	_section_elapsed = 0.0

func set_section(section_index: int) -> void:
	_current_section = maxi(section_index, 0)
	for generator in _generators:
		if generator.has_method("set_section"):
			generator.set_section(_current_section)
