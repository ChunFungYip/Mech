extends Node
class_name ProceduralAudioManager

const MIX_RATE: float = 44100.0
const BUFFER_LENGTH: float = 0.5
const MAX_VOICES: int = 24

var _audio_player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []
var _noise_table := PackedFloat32Array()
var _ambience_timer: float = 0.0
var _music_timer: float = 0.0

func _ready() -> void:
    if DisplayServer.get_name() == "headless":
        return
    _noise_table.resize(512)
    for noise_index in _noise_table.size():
        _noise_table[noise_index] = randf_range(-1.0, 1.0)
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = MIX_RATE
    stream.buffer_length = BUFFER_LENGTH
    _audio_player = AudioStreamPlayer.new()
    _audio_player.name = "ProceduralAudioOutput"
    _audio_player.stream = stream
    _audio_player.bus = "Master"
    add_child(_audio_player)
    _audio_player.play()
    _playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _exit_tree() -> void:
    _voices.clear()
    if _audio_player != null:
        _audio_player.stop()
        _audio_player.stream = null
        _audio_player.queue_free()
        _audio_player = null
    _playback = null

func play_sound(sound_id: StringName, world_position: Vector3 = Vector3.ZERO, intensity: float = 1.0) -> void:
    if _playback == null:
        return
    var spec := _get_sound_spec(sound_id)
    if spec.is_empty():
        return
    var voice := spec.duplicate()
    voice["elapsed"] = 0.0
    voice["phase"] = 0.0
    voice["intensity"] = clampf(intensity, 0.0, 2.0)
    var spatial := _get_spatial_mix(world_position)
    voice["volume"] = float(voice["volume"]) * spatial["volume"]
    voice["pan"] = spatial["pan"]
    if _voices.size() >= MAX_VOICES:
        _voices.pop_front()
    _voices.append(voice)

func _process(_delta: float) -> void:
    if _playback == null:
        return
    _ambience_timer -= _delta
    if _ambience_timer <= 0.0:
        play_sound(&"city_ambience", Vector3.ZERO, 0.34)
        _ambience_timer = 3.8
    _music_timer -= _delta
    if _music_timer <= 0.0:
        play_sound(&"music_pad", Vector3.ZERO, 0.20)
        _music_timer = 5.8
    var frame_count := _playback.get_frames_available()
    for frame_index in range(frame_count):
        var left := 0.0
        var right := 0.0
        var voice_index := _voices.size() - 1
        while voice_index >= 0:
            var voice: Dictionary = _voices[voice_index]
            var elapsed: float = float(voice["elapsed"])
            var duration: float = float(voice["duration"])
            if elapsed >= duration:
                _voices.remove_at(voice_index)
                voice_index -= 1
                continue

            var progress := clampf(elapsed / duration, 0.0, 1.0)
            var frequency := lerpf(float(voice["frequency_start"]), float(voice["frequency_end"]), progress)
            var phase: float = float(voice["phase"])
            phase = fmod(phase + frequency / MIX_RATE, 1.0)
            voice["phase"] = phase
            voice["elapsed"] = elapsed + 1.0 / MIX_RATE

            var envelope := _get_envelope(progress, float(voice["attack"]), float(voice["release"]))
            var tone := sin(phase * TAU)
            var harmonic := sin(phase * TAU * 2.01) * float(voice["harmonic"])
            var noise_index := int(floor(phase * float(_noise_table.size()) + elapsed * 1000.0)) % _noise_table.size()
            var noise := _noise_table[noise_index] * float(voice["noise"])
            var sample := (tone + harmonic + noise) * envelope * float(voice["volume"]) * float(voice["intensity"])
            var pan: float = clampf(float(voice["pan"]), -1.0, 1.0)
            left += sample * (1.0 - pan * 0.42)
            right += sample * (1.0 + pan * 0.42)
            _voices[voice_index] = voice
            voice_index -= 1

        _playback.push_frame(Vector2(clampf(left, -1.0, 1.0), clampf(right, -1.0, 1.0)))

func _get_envelope(progress: float, attack: float, release: float) -> float:
    var attack_level := 1.0 if attack <= 0.0 else clampf(progress / attack, 0.0, 1.0)
    var release_level := 1.0 if release <= 0.0 else clampf((1.0 - progress) / release, 0.0, 1.0)
    return minf(attack_level, release_level)

func _get_spatial_mix(world_position: Vector3) -> Dictionary:
    if world_position == Vector3.ZERO:
        return {"volume": 1.0, "pan": 0.0}
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return {"volume": 1.0, "pan": 0.0}
    var local_position := camera.to_local(world_position)
    var distance := world_position.distance_to(camera.global_position)
    var volume := clampf(1.0 / (1.0 + distance * 0.045), 0.16, 1.0)
    var pan := clampf(local_position.x / maxf(distance, 1.0) * 1.8, -1.0, 1.0)
    return {"volume": volume, "pan": pan}

func _get_sound_spec(sound_id: StringName) -> Dictionary:
    match sound_id:
        &"machinegun":
            return _spec(0.075, 105.0, 42.0, 0.22, 0.82, 0.10, 0.04, 0.08, 0.0)
        &"rocket":
            return _spec(0.38, 64.0, 25.0, 0.32, 0.46, 0.24, 0.04, 0.12, 0.0)
        &"missile":
            return _spec(0.30, 220.0, 620.0, 0.20, 0.18, 0.18, 0.03, 0.10, 0.0)
        &"enemy_fire":
            return _spec(0.10, 76.0, 34.0, 0.18, 0.86, 0.08, 0.02, 0.08, 0.0)
        &"hit":
            return _spec(0.13, 620.0, 130.0, 0.16, 0.52, 0.18, 0.01, 0.18, 0.0)
        &"explosion":
            return _spec(0.72, 52.0, 20.0, 0.46, 0.92, 0.36, 0.01, 0.24, 0.0)
        &"door":
            return _spec(1.05, 38.0, 22.0, 0.24, 0.24, 0.15, 0.03, 0.22, 0.0)
        &"repair":
            return _spec(0.32, 260.0, 760.0, 0.16, 0.08, 0.15, 0.02, 0.16, 0.0)
        &"servo":
            return _spec(0.16, 92.0, 58.0, 0.09, 0.42, 0.22, 0.02, 0.14, 0.0)
        &"sprint":
            return _spec(0.22, 178.0, 92.0, 0.14, 0.34, 0.38, 0.03, 0.16, 0.0)
        &"boss_attack":
            return _spec(0.52, 46.0, 180.0, 0.22, 0.46, 0.62, 0.05, 0.22, 0.0)
        &"hazard":
            return _spec(0.34, 320.0, 94.0, 0.18, 0.30, 0.54, 0.02, 0.18, 0.0)
        &"emp":
            return _spec(0.48, 680.0, 110.0, 0.20, 0.22, 0.78, 0.02, 0.26, 0.0)
        &"city_ambience":
            return _spec(2.40, 58.0, 42.0, 0.045, 0.38, 0.30, 0.18, 0.30, 0.0)
        &"mission_start":
            return _spec(0.70, 180.0, 420.0, 0.16, 0.18, 0.62, 0.04, 0.20, 0.0)
        &"boss_phase":
            return _spec(0.62, 96.0, 28.0, 0.22, 0.42, 0.70, 0.04, 0.24, 0.0)
        &"mission_complete":
            return _spec(0.90, 220.0, 760.0, 0.18, 0.12, 0.82, 0.04, 0.30, 0.0)
        &"music_pad":
            return _spec(3.20, 132.0, 176.0, 0.030, 0.10, 0.92, 0.30, 0.36, 0.0)
    return {}

func _spec(duration: float, frequency_start: float, frequency_end: float, volume: float, noise: float, harmonic: float, attack: float, release: float, _unused: float) -> Dictionary:
    return {
        "duration": duration,
        "frequency_start": frequency_start,
        "frequency_end": frequency_end,
        "volume": volume,
        "noise": noise,
        "harmonic": harmonic,
        "attack": attack,
        "release": release,
    }
