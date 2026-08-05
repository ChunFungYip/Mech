# Procedural Audio

HonGong Mech now generates its core sound effects at runtime with Godot 4.7. No WAV, OGG, MP3, or FLAC assets are required for the current sound layer.

## Audio Architecture

`AudioManager.gd` creates one `AudioStreamGenerator` and one `AudioStreamPlayer` at runtime. Sound requests become short synthesized voices stored in a bounded voice pool. The manager fills the generator buffer with generated stereo samples every frame.

Implementation: `scripts/AudioManager.gd`.

The audio generator uses:

- Tonal sine waves for mechanical and weapon pitches.
- A second harmonic for body and texture.
- White-noise-like samples for muzzle blasts, impacts, and explosions.
- Attack and release envelopes to avoid clicks.
- Frequency sweeps to distinguish launches, hits, and repair feedback.
- Distance attenuation based on the active 3D camera.
- Simple stereo panning based on the sound position relative to the camera.
- A maximum of `24` active generated voices to limit runtime overhead.
- A low-volume city ambience bed and repeating harmonic music pad mixed through the same bounded voice pool.

## Generated Sound Catalog

| Sound ID | Trigger | Character |
| --- | --- | --- |
| `machinegun` | Player right-hand machine gun | Short bright mechanical burst with noise. |
| `rocket` | Player direct-fire rocket | Low descending launch tone with blast texture. |
| `missile` | Eight-missile salvo | Rising guidance chirp. |
| `enemy_fire` | Enemy or boss ranged attack | Short low red-team weapon burst. |
| `hit` | Enemy part or boss damage | Sharp impact tick with a descending tone. |
| `explosion` | Rocket, missile, enemy, or boss detonation | Low-frequency blast with heavy noise. |
| `door` | Hangar door starts opening or closing | Low motor-like lift/lock tone. |
| `repair` | Player talks to the repair bot | Short rising service-confirmation chime. |
| `servo` | Normal mech movement | Low mechanical actuator pulse. |
| `sprint` | Sprint movement | Faster, brighter engine-like movement pulse. |
| `city_ambience` | Repeating background bed | Low-volume road, transformer, and harbour texture. |
| `music_pad` | Repeating background motif | Restrained harmonic pulse for the night district. |
| `boss_attack` | Boss special attack | Rising mechanical charge before missiles or hazards. |
| `hazard` | Hazard arming and activation | Bright warning tone with a descending activation sweep. |
| `emp` | Player EMP pulse | Wide electronic discharge with a short high-to-low sweep. |
| `mission_start` | Player leaves home base | Sortie deployment stinger. |
| `boss_phase` | Boss phase escalation | Low threat-rise transition. |
| `mission_complete` | Boss defeat and return objective | Completion-oriented rising stinger. |

## Event Flow

```text
Gameplay event
    -> AudioManager.play_sound(sound_id, world_position, intensity)
    -> Sound specification selected
    -> Voice added to bounded pool
    -> AudioStreamGenerator samples synthesized
    -> Stereo frame pushed to the audio output
```

The system does not create an audio node for every shot. All short sounds are mixed by the single generator player.

## Volume Control

The existing settings system controls the Godot `Master` audio bus. The master-volume value is stored in:

```text
user://mech_settings.cfg
```

The Audio page in the settings menu changes this bus value immediately.

## Current Limitations

The current audio layer is intentionally synthetic and compact:

- The music and ambience are procedural motifs rather than authored tracks.
- No spoken repair-bot dialogue.
- No authored footstep or landing recordings; movement currently uses short generated servo/sprint pulses.
- No reverb zones for the hangar and street.
- No occlusion through buildings or the hangar door.
- No authored instrument or weapon recordings.
- No multi-channel mixer beyond the master bus.

## Next Audio Pass

Recommended additions after the current generated layer is verified in-game:

1. Add a separate hangar ambience loop.
2. Add looping servo and sprint-engine voices with heat-state modulation.
3. Add footstep and heavy landing sounds.
4. Add audio buses for SFX, ambience, music, and dialogue.
5. Add reverb and occlusion when the project has authored audio assets.
