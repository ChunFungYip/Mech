# Combat Visual Effects

This document describes the visual effects currently implemented in HonGong Mech // Neon Harbour and the visual work that is still planned. The current project is a procedural Godot 4.7 prototype: effects are created at runtime with GDScript, meshes, emissive materials, lights, and tweens. No external effect assets are required.

## Visual Direction

The game uses a neon Hong Kong night-combat style:

- Dark blue-grey streets and mech armor provide the base contrast.
- Cyan, teal, orange, red, and yellow emissive materials identify technology, weapons, warning states, and explosions.
- World lights are kept small and local so neon signs, cockpit displays, projectiles, and explosions read clearly.
- First-person cockpit geometry stays at the screen edges so the center remains open for aiming.
- Third-person view shows the complete procedural mech silhouette and its damaged-part state.

## Effects Currently Implemented

### Machine-Gun Tracers

The machine gun uses a camera-centered ray for hit detection. When it fires, a short glowing line is created between the ray origin and the impact point.

- Color: warm yellow-orange for the player.
- Lifetime: approximately `0.075` seconds.
- Geometry: thin `BoxMesh` rotated along the shot direction.
- Damage: applied immediately by the raycast before the tracer is displayed.
- Enemy return fire uses the same tracer system with a red color.

Implementation:

- Player shot creation: `scripts/MechPlayer.gd`
- Tracer mesh and cleanup: `scripts/Main.gd` in `spawn_tracer()`
- Enemy shot creation: `scripts/EnemyMech.gd`

### Rocket Projectile

The direct-fire rocket is a visible projectile rather than an instant ray.

- Geometry: glowing `SphereMesh`.
- Material: orange emissive unshaded material.
- Light: temporary red-orange `OmniLight3D` attached to the projectile.
- Movement: straight-line travel with collision ray checking between frames.
- Detonation: on geometry impact, enemy impact, or lifetime expiration.
- Damage: direct target damage plus nearby enemy area damage.
- Smoke trail: short generated translucent puffs emitted behind the projectile during flight.

Implementation:

- Projectile movement and collision: `scripts/RocketProjectile.gd`
- Spawn and upgraded damage values: `scripts/Main.gd` and `scripts/MechPlayer.gd`
- Explosion presentation: `scripts/Main.gd` in `spawn_explosion()`

### Homing Missile

The missile port fires eight missiles in a salvo. Each missile is individually simulated.

- Geometry: elongated glowing `SphereMesh`.
- Material: orange-red emissive unshaded material.
- Light: small red-orange point light.
- Homing: missile direction turns toward the locked enemy over time.
- Unguided mode: when there is no lock, the missile keeps its launch direction.
- Salvo spread: missiles launch from small offsets to create a visible formation.
- Detonation: on collision, near-target contact, or lifetime expiration.
- Smoke trail: smaller generated translucent puffs emitted at a faster interval than the rocket trail.

Implementation:

- Missile movement and homing: `scripts/HomingMissile.gd`
- Eight-missile launch formation: `scripts/Main.gd`
- Lock state and firing mode: `scripts/MechPlayer.gd`

### Explosion Flash

Rockets, missiles, enemy destruction, and hit sparks use the procedural explosion helper.

- A glowing sphere is placed at the impact position.
- A temporary point light creates a local flash.
- A tween expands the sphere for a short burst.
- The visual is removed after the tween completes.
- The radius is reused as a gameplay damage radius by the projectile systems.

Implementation: `scripts/Main.gd` in `spawn_explosion()`.

### Hit Spark

A hit spark combines a small explosion flash with six generated glowing debris streaks that shoot outward from the impact position and fade quickly. It is used when an enemy mech or boss receives damage.

This is intentionally lightweight. It provides directional impact feedback without introducing a particle system or imported effect texture.

Implementation: `scripts/Main.gd` in `spawn_hit_spark()`.

### Enemy Part Destruction

Enemy mechs are assembled into six logical visual groups:

- Left arm
- Right arm
- Upper torso
- Lower torso
- Left leg
- Right leg

When a part takes damage, its generated armor meshes progressively tint toward hot red and gain emissive damage heat. Below roughly 72 percent HP, a generated exposed-core panel and two glowing conduit strips appear on the part. When the part reaches zero HP, its armor group and damage detail geometry are hidden. This gives a clear visual state change even though the current prototype does not yet detach parts with physics.

The upper and lower torso are critical sections. The enemy is destroyed only after both torso sections reach zero HP. Destroying either leg applies the 40 percent movement-speed penalty before the final destruction state.

Implementation: `scripts/EnemyMech.gd`, using the `_part_meshes`, `_part_damage_markers`, and `_update_part_damage_visual()` runtime mesh path.

### Enemy Archetype Visuals

Enemy visuals now communicate different combat roles:

- The heavy mech uses the full bipedal silhouette.
- The scout mech reuses the bipedal silhouette at a smaller scale to read as a fast light unit.
- The flying drone uses a compact floating body, lateral arms, underside thrusters, emissive panels, and a hover animation.
- The spider mech uses the ground body at a reduced scale and adds four leg pairs for eight visible legs.

These archetypes are generated from the same runtime mesh helpers as the original enemy. Their different shapes are visual feedback for their movement profile: small and fast, aerial, or low spider-like ground movement.

### Giant Boss Visuals

The Central Market Siege Boss uses a separate giant procedural silhouette rather than the regular enemy body:

- Oversized torso and shoulder armor.
- Heavy arm-mounted weapon blocks.
- Large lower legs and a rear power assembly.
- Red reactor sphere and emissive warning strips.
- Local red reactor light.
- World-space `CENTRAL MARKET // SIEGE CLASS` label.
- Large defeat explosion when its health reaches zero.
- Phase label changes from `PHASE 01` to `PHASE 02` below 50 percent health and to `PHASE 03` below 25 percent health.
- Movement speed, attack damage, and attack interval increase at each phase.

The boss is dormant until the player enters its central-city area. The gameplay HUD adds a dedicated red boss-health panel while the player is inside that area.

### Mech Cockpit and Weapon Visuals

The first-person camera includes a dedicated cockpit presentation instead of showing the full external mech body inside the camera.

Visible elements include:

- Side cockpit armor rails.
- Top and bottom cockpit framing.
- Lower mechanical armor and instrument lights.
- Right-side machine-gun mount.
- Left-side rocket mount.
- Missile-port tubes when missile mode is selected.
- Emissive warning strips and display panels.
- Reusable first-person muzzle-flash meshes and local weapon lights.
- Brief camera recoil after machine-gun and rocket shots.
- Brief enemy body twist and movement interruption on heavy hits or destroyed components.

These pieces are visual-only and are positioned around the screen edges to protect the center aim area.

Implementation: `scripts/MechPlayer.gd` in `_build_first_person_cockpit()`.

### Neon Environment Effects

The environment uses emissive mesh materials and local point lights for atmosphere and readability.

The city and home base include:

- Neon building signs.
- Lit windows.
- Streetlights.
- Hawker-stall signs.
- Road markings.
- Home-base launch-bay strips.
- Pilot-link and armory console displays.
- Cockpit indicator lights.
- Overhead wire silhouettes.
- The home-base hangar door's animated neon edge strips.

Implementation:

- City: `scripts/HongKongDistrict.gd`
- Home base: `scripts/HomeBase.gd`
- Repair bot: `scripts/RepairBot.gd`
- Player cockpit: `scripts/MechPlayer.gd`

The hangar door is an `AnimatableBody3D` with a box collision shape. It slides upward through a one-second tween when the player approaches the front threshold, then slides down after the player retreats into the hangar.

### HUD Combat Feedback

The HUD is also part of the combat presentation. It currently shows:

- Speed and sprint heat state.
- Health and armor.
- Machine-gun and rocket ammunition.
- Selected weapon group.
- Missile lock state.
- Target-following missile lock brackets and a `LOCKED` indicator, clamped to the viewport edge when the target is off-center.
- A red incoming-damage arrow that rotates toward the hit direction and fades after impact.
- A short hit-confirmation `X` marker for successful player weapon impacts.
- `CRITICAL HIT` and `PART DESTROYED` announcements for enemy component results.
- A pulsing `CRITICAL ARMOR` warning at low player health.
- A responsive `50 m` radar with forward-oriented enemy blips and an active-boss marker.
- Six locked-enemy component HP bars.
- Enemy wave, contact count, and confirmed kills.
- Combat announcements such as enemy destruction, overheat, and missile launches.

Implementation: `scripts/GameHUD.gd`.

## Effect Flow

The current projectile and damage flow is:

```text
Player input
    -> Raycast or projectile spawn
    -> Hit or lifetime event
    -> EnemyMech.take_damage()
    -> Part HP update
    -> Hit spark or explosion
    -> Part visual hidden or enemy destroyed
```

For a machine-gun shot, damage is immediate and the tracer is visual feedback. For rockets and missiles, the projectile travels first and damage is applied at detonation.

## Current Technical Approach

The effect layer currently uses:

- `MeshInstance3D`
- `BoxMesh`
- `SphereMesh`
- `StandardMaterial3D`
- Emission and unshaded materials
- `OmniLight3D`
- `Tween`
- Physics ray queries for projectile collision
- Runtime object cleanup with `queue_free()`

This approach keeps the prototype self-contained and easy to tune. The visual effects are deliberately simple and do not yet include textures, particle systems, or skeletal animation. Sound is handled separately by the runtime procedural audio layer documented in `docs/PROCEDURAL_AUDIO.md`.

## Effects Not Yet Implemented

The following effects are not currently part of the project:

- Particle-based sparks.
- Smoke trails for rockets and missiles.
- Fire, burning, or critical-damage effects.
- Armor debris and detached parts with physics.
- Bullet impact decals or scorch marks.
- Enemy hit reactions or stagger animations.
- Camera shake on heavy impacts.
- Stronger screen damage effects and cockpit warning overlays.
- Engine glow, sprint heat distortion, footstep dust, and landing impact effects.
- Servo movement animations.
- Richer authored weapon, impact, and explosion audio. Basic synthesized versions already exist in `scripts/AudioManager.gd`.
- Mech alarms and warning voice lines.

## Recommended Next Effect Pass

The next visual-effects pass should add feedback in this order:

1. Add smoke trails and small exhaust flames to rockets and missiles.
2. Add particle sparks and a brief flash for each enemy part hit.
3. Add a stronger critical warning effect when either torso is damaged below a threshold.
4. Add detached armor chunks when an arm or leg is destroyed.
5. Add a small camera shake on heavy impacts.
6. Add heat glow and exhaust effects during sprint and overheat.
7. Expand the procedural sound layer with ambience and looping mech audio after the visual timing is stable.

## Performance Notes

The current effects are short-lived and local, but large enemy waves can still create many temporary nodes. Future particle work should:

- Reuse particle systems where possible.
- Keep explosion lights short-lived.
- Limit simultaneous smoke and debris effects.
- Avoid enabling shadows on small effect lights.
- Remove expired projectiles and visual effects promptly.
- Keep the center-screen cockpit geometry simple so first-person rendering stays clear.
