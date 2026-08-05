# HonGong Mech // Neon Harbour

HonGong Mech is a single-player mech first-person shooter prototype made with Godot 4.7. The player pilots a 5 m tall combat mech through a procedural Hong Kong-inspired night district and fights hostile NPC mechs using a machine gun, direct-fire rockets, and an eight-missile salvo system.

The prototype is designed as a compact playable foundation. It focuses on movement, camera switching, dual-hand weapons, homing missiles, enemy component damage, enemy waves, a home-base repair and upgrade loop, and a strong sense of place without requiring external art assets.

## Game Overview

The current scenario takes place in a neon Mong Kok-inspired street approach. The district contains:

- Dense tenement-style buildings with varied heights and illuminated windows.
- Narrow asphalt roads, Hong Kong-style double yellow road markings, tiled sidewalks, and parked vehicles.
- Neon signs, hawker stalls, streetlights, overhead utility wires, and a raised footbridge.
- Authored Central Market, tram-intersection, and harbour-cargo combat spaces layered into the procedural route.
- A combat route populated by hostile mechs that steer around obstacles, strafe, circle, and fire when they are in range.

The player starts inside the HK-05 Titan Home Base, a procedural launch hangar at the edge of the street. The base includes a marked mech spawn pad, pilot-link and armory consoles, neon launch-bay lighting, a covered roof, and an automatic upward-sliding hangar door facing the combat route. The door opens as the mech approaches the entrance and closes after the mech returns inside. Enemy spawns and pursuit are kept outside a `30 m` no-enemy buffer around the hangar, while the player start also has its separate `45 m` spawn-distance protection.

The player starts in the HK-05 Titan mech. The first wave contains four enemies. Once a wave is cleared, another wave arrives after a short delay. Later waves add more enemies to the encounter.

Enemy kills award credits, which can be spent at the repair bot before the next sortie. The current prototype has no separate campaign map or mission selection; the home base and street are part of one runtime combat scene.

In addition to the opening fixed wave, each run places eight randomized ambush points along the main road. When the player approaches an untriggered point within `20 m`, it spawns between `1` and `5` enemy mechs. Each point is consumed after its first trigger, so the same location does not continuously respawn enemies.

The center of the city contains the Central Market Siege Boss. Entering its `18 m` boss area activates the giant mech and reveals its boss HP bar. The boss is tracked separately from regular waves, escalates through three phases, launches missile salvos, and marks telegraphed ground hazards. It awards `1000` credits when destroyed.

## Main Features

- Procedural 3D Hong Kong-inspired environment generated at runtime.
- 5 m tall player mech built from procedural meshes.
- First-person cockpit camera and third-person chase camera.
- Visible first-person cockpit framing with lower mech armor, mechanical weapon mounts, and separate machine-gun and rocket-pod models kept clear of the center aim area.
- Ground movement with acceleration, gravity, floor snapping, and heat-limited sprint movement.
- Automatic hitscan machine gun with tracers and magazine reloads.
- Direct-fire rocket launcher with projectile travel and area damage.
- Selectable missile port that launches an eight-missile homing salvo when a target is locked.
- EMP pulse ability on `Q` that damages and staggers nearby hostiles on a cooldown.
- Unguided missile salvos that fly straight through the aim point when no target is locked.
- Hostile NPC mechs with pursuit, line-of-sight shooting, health, and destruction effects.
- Four enemy archetypes: heavy mech, fast scout mech, flying drone, and eight-legged spider mech.
- Giant Central Market Siege Boss with a dedicated area trigger and HP bar.
- Boss phase attack patterns with homing ordnance and warning-ring arena hazards.
- MechWarrior-inspired enemy component damage with separate left arm, right arm, upper torso, lower torso, left leg, and right leg HP bars.
- Generated 3D enemy damage states: heated armor tint, exposed-core plates, glowing conduits, and hidden destroyed parts.
- Randomized city ambush points that activate when the player approaches.
- Wave spawning, kill tracking, combat announcements, and a code-generated HUD.
- Mission objective loop: deploy from home base, defeat the Central Market boss, return to base, and complete the sortie.
- Weapon hit confirmation, critical-part messages, low-health warning, muzzle flashes, and camera recoil.
- Generated projectile smoke trails, impact debris streaks, and escalating boss phases.
- GPU particle bursts, EMP pulse rings, hazard markers, and reduced-effects accessibility handling.
- Enemy stagger reactions on heavy hits and destroyed components.
- Procedural servo, sprint-engine, and sprint-exhaust movement feedback.
- Resolution-aware HUD and menu layouts that scale to fit the current viewport.
- Incoming-damage direction arrow that points toward the side of the player mech being hit.
- Reference-inspired settings menu with display, audio, controls, and gameplay pages.
- Interactive repair bot inside the home base with persistent upgrades, weapon-group changes, frame tuning, and full repair.
- Automatic upward hangar door with moving collision and neon edge lighting.
- Runtime-generated procedural audio for weapons, impacts, explosions, the hangar door, and repair interaction.
- Procedural city ambience plus mission, boss-phase, hazard, and completion stingers.
- Local persistence for settings, the mech upgrade profile, and live mission state.
- Three campaign save slots with mission completion tracking, live player/enemy/boss restoration, Story/Standard/Veteran balancing, and first-sortie onboarding.
- Detailed combat visual-effects reference in `docs/COMBAT_VISUAL_EFFECTS.md`.
- Bilingual audit and fix record in `docs/audit20260804.md`.
- Compatible with the Godot 4.7 project format.
- No mandatory imported models, textures, sound files, or plugins; the current SFX layer is generated at runtime.

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
| `Shift` | Sprint while held, using the sprint heat system. |
| Mouse movement | Rotate the mech's aim and camera. |
| `1` | Return to dual-hand weapons using the current weapon group. |
| `2` | Return to dual-hand weapons using the current weapon group. |
| `3` | Enter missile-port mode and temporarily disable both hand weapons. |
| `E` | Talk to the repair bot when standing inside the home base. |
| `Q` | Fire the EMP pulse ability. |
| `V` | Switch between first-person and third-person view. |
| `Esc` | Open or close the settings menu and pause the game. |

### Combat

| Input | Action |
| --- | --- |
| Left mouse button | Fire the left-hand direct-fire rocket launcher. |
| Right mouse button | Fire the right-hand machine gun. Hold to fire automatically. |
| `R` | Reload the machine gun. |

When the missile port is selected with `3`, both hand weapons are disabled. The missile lock searches within `180 m` and an `8-degree` aim cone. Press the right mouse button to launch eight missiles directly toward the current aim point. Press the left mouse button to launch eight homing missiles only when an enemy has been locked. The left-button salvo uses the last valid locked enemy; if there is no lock, it does not fire. The lock is cleared when the target is destroyed or removed.

When a target is locked, an orange four-corner `LOCKED` reticle follows the target on screen. If the target moves outside the center of the view, the reticle clamps to the nearest screen edge so the player can still see the lock direction.

In normal dual-hand mode, the default `STRIKE GROUP` maps the left mouse button to the direct-fire rocket launcher and the right mouse button to the machine gun. The repair bot can switch to `SUPPORT GROUP`, which swaps those left/right assignments.

### Repair Bot Upgrade System

Walk up to the service robot inside the home base and press `E`. The game pauses and opens a repair dialogue with four service paths:

- `UPGRADE MECH`: spend credits on reinforced armor, servo actuators, machine-gun calibration, rocket payload, or missile guidance. Each upgrade has three levels and a rising cost.
- `CHANGE WEAPON GROUP`: choose `STRIKE GROUP` or `SUPPORT GROUP` to change which weapon fires from each mouse button.
- `ADJUST MECH FRAME`: choose `BALANCED FRAME`, `HEAVY FRAME`, or `MOBILE FRAME`. Heavy adds health but reduces speed; Mobile adds speed but reduces health.
- `REPAIR TO FULL HEALTH`: restore the mech to its current maximum health before a sortie.

The player starts with `1200` credits. Each enemy kill awards `100` credits. The upgrade profile is saved to `user://mech_upgrade_profile.cfg`. Credits, upgrade levels, weapon group, and frame tuning remain available the next time the project runs.

Upgrade costs use a three-level progression. The base costs are `150` for armor, `130` for mobility, `140` for machine-gun calibration, `160` for rocket payload, and `180` for missile guidance; the next levels cost two and three times the base cost.

### Movement Details

The current movement system is intentionally simple and grounded:

- `W`, `A`, `S`, and `D` produce movement on the ground plane.
- Movement follows the mech's horizontal facing direction. Looking up or down does not make the mech fly or walk vertically.
- The mech accelerates toward the requested direction instead of changing velocity instantly.
- Releasing the movement keys causes the mech to slow down through the same movement controller.
- `Shift` multiplies the normal movement speed by the sprint multiplier while the sprint system is available.
- Sprinting has a `10 s` safe window. Holding Shift beyond 10 seconds enters an extended `10-20 s` window with rising heat.
- Reaching `20 s` forces an overheat. Sprint is disabled during the `18 s` overheat recovery period, which is three times the normal `6 s` full recharge duration.
- Releasing Shift before overheat lets the sprint timer recharge; partial use takes proportionally less than 6 seconds to recover.
- Gravity keeps the mech grounded, and floor snapping helps it stay attached to streets and sidewalks.
- There is currently no jump, crouch, slide, dash, melee attack, or wall-running system.
- In first-person mode the complete external mech body remains hidden from the camera, but a dedicated cockpit interior, lower armor, mechanical arms, machine gun, and rocket pod remain visible around the edges of the screen. This keeps the mech presence without placing the full body in front of the aim point. In third-person mode the complete mech body is visible.

## Combat Systems

### Player Mech

- Base maximum armor: `500`
- Machine-gun magazine: `60` rounds
- Machine-gun reserve: `240` rounds
- Rocket magazine: `6` rockets
- Rocket reserve: `12` rockets
- Missile ammunition: `4` salvos, with `8` missiles per salvo
- Machine-gun fire interval: approximately `0.085` seconds
- Machine-gun reload time: approximately `1.8` seconds
- Rocket cooldown: approximately `0.85` seconds
- Rocket explosion radius: `5 m`

The base health, movement, and weapon values can change through the repair bot. When the player's health reaches zero, the pilot link is interrupted and a failure overlay offers a restart from the latest deployment or boss checkpoint, or a full mission restart. Checkpoint restarts restore health, ammunition, and missile stocks and clear transient combat units.

Upgrade effects are:

- Reinforced Armor: `+100` maximum health per level.
- Servo Actuators: `+0.4 m/s` movement speed per level.
- Ballistic Calibration: `+4` machine-gun damage per level and a small fire-interval reduction.
- Rocket Payload: `+15` rocket damage and `+0.25 m` explosion radius per level.
- Missile Guidance: `+8` missile damage per level.

Frame tuning adds another live modifier: `HEAVY FRAME` gives `+100` health and `-1.0 m/s` speed; `MOBILE FRAME` gives `+1.2 m/s` speed, `-50` health, and a small boost multiplier increase; `BALANCED FRAME` keeps the base values.

### Sprint Heat System

The Shift sprint uses five states shown in the HUD:

- `READY // SAFE 10 S`: no sprint heat is stored.
- `SPRINT`: the mech is inside the first 10 seconds of sprint use.
- `EXTENDED`: the mech is still sprinting between 10 and 20 seconds, but heat is rising.
- `RECHARGE`: Shift was released before overheat and the sprint timer is cooling down.
- `OVERHEATED`: the mech held sprint for 20 seconds; sprint is unavailable until the longer recovery finishes.

### Machine Gun

The machine gun uses a camera-centered ray to find its target. A hit applies immediate damage and creates a short-lived procedural tracer between the muzzle direction and the impact point. Pressing `R` starts a timed reload when the magazine is not full.

Successful weapon hits show a short hit marker. Torso hits and destroyed components produce critical or part-destroyed combat announcements. The player receives a pulsing `CRITICAL ARMOR` warning at 25% health or below. Hand weapons produce first-person muzzle flashes and brief camera recoil.

### Rockets

- Responsive 50 m radar mini-map with forward-facing enemy and boss blips.

- `HEAVY MECH`: the standard 5 m ground unit. It moves at `3.2 m/s`, has the full six-part health profile, and is the most durable general-purpose enemy.
- `SCOUT MECH`: a smaller ground unit with a `0.68` visual scale, `7.0 m/s` movement speed, and approximately `55%` of the heavy mech's component HP. It closes distance quickly and attacks more often.
- `FLYING DRONE`: a compact hovering unit with approximately `50%` of the heavy mech's component HP. It moves at `5.6 m/s`, maintains roughly `6.5 m` altitude above the combat plane, and attacks from the air without being affected by leg damage.
- `SPIDER MECH`: a ground unit with an `0.85` visual scale and eight visible legs. It moves at `4.5 m/s`, has approximately `86%` of the heavy mech's component HP, and uses the existing leg-damage slowdown.

The first wave demonstrates all four types. Later fixed waves add more scouts and drones, while randomized city ambushes choose an archetype independently for each spawned enemy.

### Central Market Siege Boss

The giant boss mech starts dormant at the center of the city and is not counted as part of the regular wave contact total. When the player enters the `18 m` Central Market boss area, the boss activates, moves toward the player, and fires a heavy ranged attack. While the player remains inside the area, the HUD displays:

- `SIEGE CLASS // CENTRAL MARKET`
- Current boss HP and maximum HP
- A dedicated red boss-health bar

The boss has `2400 HP` on Standard, uses the same projectile and raycast damage contract as other enemies, and can be damaged by the machine gun, direct rockets, missile salvos, and EMP pulses. It escalates through three phases: phase 2 begins below 50% HP with faster movement and attacks, and phase 3 begins below 25% HP with the most aggressive movement and attack rate. Later phases alternate between five-missile homing salvos and telegraphed ground hazards that damage the player while they remain inside the warning radius. Destroying it triggers a particle-backed explosion and awards `1000 credits`.

### Random City Encounters

Random encounter points are generated by `Main.gd` inside the road corridor, at least `49 m` from the initial spawn to account for their maximum four-metre enemy-group offset, and outside the hangar's `30 m` no-enemy buffer. Their positions are randomized on every run, with a minimum separation between points. A proximity check runs during gameplay; crossing within `20 m` triggers one encounter of `1` to `5` hostile mechs. The fixed wave system remains active alongside these one-shot city ambushes, and its opening enemies are placed deeper down the street beyond both safety rules.

## Camera Modes

### First Person

The cockpit camera is the default view. A dedicated first-person rig shows the cockpit frame, lower armor, mechanical weapon mounts, machine gun, and rocket pod at the lower and side edges of the screen. The center stays open for aiming. The HUD shows current speed, sprint heat state, armor, ammunition, and weapon readiness.

When the player is hit, a red directional arrow briefly appears around the center of the HUD. It points toward the incoming hit direction relative to the active camera: up for front, down for behind, and left or right for side hits. The indicator fades after the impact.

### Third Person

The chase camera follows the mech through a spring arm. The full procedural mech body is visible, making this mode useful for checking movement, positioning, and the Hong Kong environment from outside the cockpit.

## Settings and Persistence

Press `Esc` during gameplay to open the settings menu. It pauses the combat scene and provides five pages:

- `DISPLAY`: field of view and window mode.
- `AUDIO`: master volume.
- `CONTROLS`: the current movement, weapon, camera, reload, missile, and repair-bot bindings.
- `GAMEPLAY`: mouse X/Y sensitivity, inverted vertical aim, reduced combat effects, and difficulty.
- `PROFILE`: three campaign save slots, mission-progress summaries, and `SAVE GAME` / `LOAD GAME` actions.

Settings are saved to `user://mech_settings.cfg`. Upgrade data remains backward-compatible in `user://mech_upgrade_profile.cfg`; campaign profile slots are stored as `user://mech_campaign_slot_1.cfg` through `user://mech_campaign_slot_3.cfg`, with matching runtime state files ending in `_state.cfg`. `SAVE GAME` captures the player position, health, ammunition, weapon/view state, mission flags, wave and ambush progress, active enemies, checkpoints, and boss phase/health. Deployment, boss engagement, boss defeat, and mission completion also create automatic saves in the active slot. `LOAD GAME` restores the selected slot into the current scene without restarting the application.

## Audio

The project generates its core sound effects at runtime with `AudioStreamGenerator`. Player weapons, enemy fire, hits, explosions, the hangar door, repair-bot interaction, boss attacks, hazards, and mission events all have synthesized audio cues. A low-volume procedural city ambience bed runs between one-shot effects. The master-volume setting in the Audio page controls the Godot `Master` bus. See [docs/PROCEDURAL_AUDIO.md](docs/PROCEDURAL_AUDIO.md) for the sound catalog and implementation details.

### Resolution-Aware UI

The gameplay HUD is authored on a centered `1280x720` design canvas and scales down uniformly when the viewport is smaller. The settings and repair-bot panels also recalculate their scale whenever the window size changes, keeping their controls inside the available viewport at the project's minimum window size and common desktop resolutions.

## Visual Effects Documentation

See [docs/COMBAT_VISUAL_EFFECTS.md](docs/COMBAT_VISUAL_EFFECTS.md) for the current visual-effects inventory, implementation paths, effect flow, missing mech-combat feedback, performance notes, and recommended next visual pass.

The HUD radar covers a `50 m` radius around the player. Its center is the player mech, and the top represents the mech's current forward direction. Blip colors identify roles: orange for heavy mechs, yellow for scouts, cyan diamonds for drones, magenta for spiders, and red pulsing rings for the active boss.

## Project Structure

| File | Responsibility |
| --- | --- |
| `project.godot` | Godot 4.7 project settings, display settings, and input actions. |
| `scenes/Main.tscn` | Minimal entry scene that loads the runtime game controller. |
| `scripts/Main.gd` | Builds the world, lighting, player, enemy waves, projectiles, tracers, and explosion effects. |
| `scripts/HongKongDistrict.gd` | Generates the Hong Kong-inspired street, buildings, props, signs, lights, and wires. |
| `scripts/HomeBase.gd` | Generates the protected HK-05 launch hangar and player spawn area. |
| `scripts/RepairBot.gd` | Generates the interactive service NPC and proximity prompt inside the home base. |
| `scripts/RepairBotMenu.gd` | Creates the repair dialogue, upgrade shop, weapon-group selector, frame tuner, and repair action. |
| `scripts/UpgradeManager.gd` | Persists credits, upgrades, campaign profiles, and per-slot runtime save state. |
| `scripts/MechPlayer.gd` | Controls player movement, cameras, view switching, weapons, reloads, armor, and aiming. |
| `scripts/EnemyMech.gd` | Controls enemy movement, pursuit, line-of-sight attacks, health, and destruction. |
| `scripts/BossMech.gd` | Controls the Central Market giant boss, activation, movement, attacks, health, and defeat state. |
| `scripts/CombatHazard.gd` | Runs warning-ring arena hazards with timed damage and cleanup. |
| `scripts/RocketProjectile.gd` | Handles rocket travel, collision, detonation, and area damage. |
| `scripts/HomingMissile.gd` | Handles individual missile homing, straight aim-point travel, collision, and detonation. |
| `scripts/GameHUD.gd` | Creates and updates the runtime HUD and combat announcements. |
| `scripts/SettingsManager.gd` | Loads, applies, and saves player settings to `user://mech_settings.cfg`. |
| `scripts/SettingsMenu.gd` | Creates the pause/settings interface and connects controls to the settings manager. |
| `scripts/TutorialOverlay.gd` | Presents first-sortie controls, objective context, and onboarding dismissal. |
| `scripts/AudioManager.gd` | Generates and mixes runtime procedural sound effects through `AudioStreamGenerator`. |
| `scripts/RadarDisplay.gd` | Draws the responsive 50 m radar range, sweep, player marker, and enemy blips. |
| `docs/PROCEDURAL_AUDIO.md` | Documents generated sounds, triggers, audio architecture, and limitations. |
| `docs/COMBAT_VISUAL_EFFECTS.md` | Documents current combat effects, visual implementation, limitations, and next steps. |
| `docs/audit20260804.md` | English and Traditional Chinese audit findings, fixes, validation, and remaining test gaps. |

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
- There are no imported character animations, music, dialogue, or authored 3D models yet. Core sound effects are generated procedurally, but there are no ambience or looping mech audio systems yet.
- The campaign currently contains one playable mission; mission selection, inventory, and account-level progression are not yet implemented. Save slots and settings are stored locally.
- The movement system does not currently include jumping, crouching, melee, or aerial movement.

## Possible Next Steps

- Add city and hangar ambience, mech footsteps, servo loops, sprint-engine audio, and richer weapon stingers.
- Add separate first-person arm, weapon, and cockpit models instead of hiding the external body.
- Add jump jets, dash movement, heat management, and mech stagger states.
- Replace simple enemy pursuit with navigation, cover seeking, flanking, and squad behavior.
- Add multiple Hong Kong districts, mission objectives, checkpoints, and extraction zones.
- Add distinct arm weapon failure, torso critical states, leg animations, and more detailed hit zones.
- Add authored mech models, cockpit instruments, animation, audio, and visual damage effects.
