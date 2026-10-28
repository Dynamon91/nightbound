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
const DEFAULT_FADE_SECONDS := 2.5

var _players: Array[AudioStreamPlayer] = []
var _active_index := 0
var _current_track_id := ""
var _generators: Array[Node] = []

func _ready() -> void:
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % index
		player.bus = "Master"
		player.volume_db = -80.0
		add_child(player)
		_players.append(player)
		var generator: Node = ProceduralMusicScript.new()
		generator.name = "ProceduralMusic%d" % index
		add_child(generator)
		_generators.append(generator)

## Returns false only for an unknown track. Missing final audio assets use original procedural music.
func play_track(track_id: String, fade_seconds := DEFAULT_FADE_SECONDS) -> bool:
	if track_id == _current_track_id and _players[_active_index].playing:
		return true
	if not TRACKS.has(track_id):
		push_warning("Nightbound music: no track is registered for '%s'." % track_id)
		return false
	var path: String = TRACKS[track_id]
	var has_asset := ResourceLoader.exists(path)
	var stream: AudioStream = load(path) as AudioStream if has_asset else null
	# Set loop metadata for formats exposing a loop flag. Loop points still need
	# to be authored/tested in the source asset to guarantee a seamless transition.
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var next_index := 1 - _active_index
	var outgoing := _players[_active_index]
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
	tween.chain().tween_callback(_generators[_active_index].stop_generation)
	_active_index = next_index
	_current_track_id = track_id
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
