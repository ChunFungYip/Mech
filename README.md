# HonGong Mech // Neon Harbour

HonGong Mech is a single-player mech first-person shooter prototype made with Godot 4.7. The player pilots a 5 m tall combat mech through a procedural Hong Kong-inspired night district and fights hostile NPC mechs using a machine gun and rockets.

The prototype is designed as a compact playable foundation. It focuses on movement, camera switching, basic ranged combat, enemy waves, and a strong sense of place without requiring external art assets.

## Game Overview

The current scenario takes place in a neon Mong Kok-inspired street approach. The district contains:

- Dense tenement-style buildings with varied heights and illuminated windows.
- Narrow asphalt roads, Hong Kong-style double yellow road markings, tiled sidewalks, and parked vehicles.
- Neon signs, hawker stalls, streetlights, overhead utility wires, and a raised footbridge.
- A combat route populated by hostile mechs that move toward the player and fire when they are in range.

The player starts in the HK-05 Titan mech. The first wave contains four enemies. Once a wave is cleared, another wave arrives after a short delay. Later waves add more enemies to the encounter.

## Main Features

- Procedural 3D Hong Kong-inspired environment generated at runtime.
- 5 m tall player mech built from procedural meshes.
- First-person cockpit camera and third-person chase camera.
- Visible first-person cockpit framing with lower mech armor, mechanical weapon mounts, and separate machine-gun and rocket-pod models kept clear of the center aim area.
- Ground movement with acceleration, gravity, floor snapping, and boost movement.
- Automatic hitscan machine gun with tracers and magazine reloads.
- Direct-fire rocket launcher with projectile travel and area damage.
- Selectable missile port that launches an eight-missile homing salvo when a target is locked.
- Unguided missile salvos that fly straight through the aim point when no target is locked.
- Hostile NPC mechs with pursuit, line-of-sight shooting, health, and destruction effects.
- Wave spawning, kill tracking, combat announcements, and a code-generated HUD.
- Reference-inspired settings menu with display, audio, controls, and gameplay pages.
- Compatible with the Godot 4.7 project format.
- No mandatory imported models, textures, sounds, or plugins.

## Running the Game

1. Open the `HonGong-Mech` folder in Godot 4.7.
2. Open the project and press Play.
3. The configured main scene is `res://scenes/Main.tscn`.

The world is assembled by scripts when the main scene starts. There is no separate level editor scene containing the full city layout.

## Controls

### Basic Movement

| Input | Action |
| --- | --- |
| `W` | Move forward relative to the mech's facing direction. |
| `S` | Move backward. |
| `A` | Strafe left. |
| `D` | Strafe right. |
| `Shift` | Boost movement speed while held. |
| Mouse movement | Rotate the mech's aim and camera. |
| `1` | Return to dual-hand weapons. |
| `2` | Return to dual-hand weapons. |
| `3` | Enter missile-port mode and temporarily disable both hand weapons. |
| `V` | Switch between first-person and third-person view. |
| `Esc` | Open or close the settings menu and pause the game. |

### Combat

| Input | Action |
| --- | --- |
| Left mouse button | Fire the left-hand direct-fire rocket launcher. |
| Right mouse button | Fire the right-hand machine gun. Hold to fire automatically. |
| `R` | Reload the machine gun. |

When the missile port is selected with `3`, both hand weapons are disabled. Press the right mouse button to launch eight missiles directly toward the current aim point. Press the left mouse button to launch eight homing missiles only when an enemy has been locked. The left-button salvo uses the last valid locked enemy; if there is no lock, it does not fire.

### Movement Details

The current movement system is intentionally simple and grounded:

- `W`, `A`, `S`, and `D` produce movement on the ground plane.
- Movement follows the mech's horizontal facing direction. Looking up or down does not make the mech fly or walk vertically.
- The mech accelerates toward the requested direction instead of changing velocity instantly.
- Releasing the movement keys causes the mech to slow down through the same movement controller.
- `Shift` multiplies the normal movement speed by the boost multiplier while held.
- Gravity keeps the mech grounded, and floor snapping helps it stay attached to streets and sidewalks.
- There is currently no jump, crouch, slide, dash, melee attack, or wall-running system.
- In first-person mode the complete external mech body remains hidden from the camera, but a dedicated cockpit interior, lower armor, mechanical arms, machine gun, and rocket pod remain visible around the edges of the screen. This keeps the mech presence without placing the full body in front of the aim point. In third-person mode the complete mech body is visible.

## Combat Systems

### Player Mech

- Maximum armor: `500`
- Machine-gun magazine: `60` rounds
- Machine-gun reserve: `240` rounds
- Rocket magazine: `6` rockets
- Rocket reserve: `12` rockets
- Machine-gun fire interval: approximately `0.085` seconds
- Machine-gun reload time: approximately `1.8` seconds
- Rocket cooldown: approximately `0.85` seconds
- Rocket explosion radius: `5 m`

When the player's armor reaches zero, the pilot link is reset and the mech returns to the starting position with full armor.

### Machine Gun

The machine gun uses a camera-centered ray to find its target. A hit applies immediate damage and creates a short-lived procedural tracer between the muzzle direction and the impact point. Pressing `R` starts a timed reload when the magazine is not full.

### Rockets

Rockets travel through the world as visible projectiles. They detonate when they hit geometry, an enemy, or reach their lifetime limit. The explosion damages the direct target and nearby hostile mechs.

### Enemy Mechs

Enemy mechs use a simple combat loop:

1. Move toward the player until they are close enough to stop and attack.
2. Rotate toward the player.
3. Fire a line-of-sight attack when the attack timer is ready.
4. Take damage from machine-gun hits and rocket explosions.
5. Spawn an explosion and leave the scene when destroyed.

## Camera Modes

### First Person

The cockpit camera is the default view. A dedicated first-person rig shows the cockpit frame, lower armor, mechanical weapon mounts, machine gun, and rocket pod at the lower and side edges of the screen. The center stays open for aiming. The HUD shows current speed, boost state, armor, ammunition, and weapon readiness.

### Third Person

The chase camera follows the mech through a spring arm. The full procedural mech body is visible, making this mode useful for checking movement, positioning, and the Hong Kong environment from outside the cockpit.

## Project Structure

| File | Responsibility |
| --- | --- |
| `project.godot` | Godot 4.7 project settings, display settings, and input actions. |
| `scenes/Main.tscn` | Minimal entry scene that loads the runtime game controller. |
| `scripts/Main.gd` | Builds the world, lighting, player, enemy waves, projectiles, tracers, and explosion effects. |
| `scripts/HongKongDistrict.gd` | Generates the Hong Kong-inspired street, buildings, props, signs, lights, and wires. |
| `scripts/MechPlayer.gd` | Controls player movement, cameras, view switching, weapons, reloads, armor, and aiming. |
| `scripts/EnemyMech.gd` | Controls enemy movement, pursuit, line-of-sight attacks, health, and destruction. |
| `scripts/RocketProjectile.gd` | Handles rocket travel, collision, detonation, and area damage. |
| `scripts/HomingMissile.gd` | Handles individual missile homing, straight aim-point travel, collision, and detonation. |
| `scripts/GameHUD.gd` | Creates and updates the runtime HUD and combat announcements. |
| `scripts/SettingsManager.gd` | Loads, applies, and saves player settings to `user://mech_settings.cfg`. |
| `scripts/SettingsMenu.gd` | Creates the pause/settings interface and connects controls to the settings manager. |

## Design Reference

This project uses patterns from the sibling `HonGong-ShootingRange` project:

- The procedural city approach is adapted from its `City.gd` environment generator.
- The player uses a `CharacterBody3D` controller with a dedicated camera rig, following the reference project's FPS structure.
- World geometry, lights, signs, and combat effects are assembled through GDScript rather than a large authored scene.
- The Hong Kong setting uses district naming, neon lighting, dense facades, narrow roads, overhead wires, and market details inspired by the reference project.
- The settings menu follows the reference project's `SettingsScreen.gd` and `SettingsManager.gd` split, reduced to the options currently supported by this prototype.

## Current Prototype Limitations

- The game is single-player only.
- There is no multiplayer or networking layer.
- Enemy behavior is intentionally lightweight and does not yet use navigation meshes, cover tactics, squad coordination, or advanced pathfinding.
- There are no imported character animations, sound effects, music, or authored 3D models yet.
- There is no save system, mission selection, inventory, or upgrade system. Settings are saved locally, but there is no account-level progression.
- The movement system does not currently include jumping, crouching, melee, or aerial movement.

## Possible Next Steps

- Add mech footstep, servo, weapon, rocket, and explosion audio.
- Add separate first-person arm, weapon, and cockpit models instead of hiding the external body.
- Add jump jets, dash movement, heat management, and mech stagger states.
- Replace simple enemy pursuit with navigation, cover seeking, flanking, and squad behavior.
- Add multiple Hong Kong districts, mission objectives, checkpoints, and extraction zones.
- Add damage zones, armor upgrades, weapon variants, and a progression system.
