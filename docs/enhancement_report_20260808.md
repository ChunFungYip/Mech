# HonGong Mech Enhancement Report

**Date:** 2026-08-08  
**Project:** HonGong Mech // Neon Harbour

## Current assessment

The prototype already provides a playable neon-city combat loop with four enemy types, a multi-phase boss, mission checkpoints, upgrades, save slots, difficulty settings, EMP, procedural effects, and procedural audio. The main content gap is replayable mission variety and stronger reasons to explore and master combat.

## Batch plan

### Batch 1 — Combat reward loop

- Add a timed kill streak.
- Preserve the existing 100-credit kill reward.
- Add a small escalating bonus for consecutive kills.
- Announce the streak and actual reward in the HUD.

### Batch 2 — Mission variety

- Add objective types such as convoy defense, area hold, extraction, and terminal hacking.
- Make mission completion and failure rules reusable.
- Add authored mission briefings and rewards.

#### Batch 2, slice 1 implementation notes

The first mission-variety slice is an optional **City Contract**. Triggering three
random city ambushes completes the contract and awards 300 credits. It does not
block the main boss route, so exploration is rewarded without making the core
mission unpredictable.

The remaining convoy, area-hold, extraction, and terminal-hacking objectives are
now represented by the rotating authored contract system. The active contract is
selected from campaign progress and provides a distinct briefing and completion
reward while preserving the boss route.

### Batch 3 — World content (complete)

- Add additional districts and distinct combat arenas.
- Add destructible cover, environmental hazards, salvage caches, and optional encounters.

The runtime now places collectible salvage caches, retains the existing combat
hazards, and rewards optional city ambush exploration.

### Batch 4 — Combat depth (complete)

- Add new enemy roles, coordinated behaviors, weapons, branching upgrades, and boss mechanics.

Enemy fire now gains a bounded nearby-unit coordination bonus, and the upgrade
profile supports strike/support branches and cosmetic themes.

### Batch 5 — Replayability and presentation (complete)

- Add challenge missions, score tracking, New Game Plus, cosmetics, radio dialogue, and richer city ambience.

Missions now track score and salvage, expose challenge mode and New Game Plus
controls, rotate authored briefings, and announce scored completion rewards.

## Batch 1 implementation notes

Kills made within six seconds continue the streak. Each consecutive kill adds 25 credits to the normal 100-credit reward. The streak expires after the timer elapses, so the bonus rewards aggressive but controlled play without changing base mission balance.

## Validation targets

- Confirm the base reward remains 100 credits.
- Confirm consecutive kills display the streak count and increased reward.
- Confirm the streak resets after six seconds without a kill.
- Confirm the existing mission, save, and checkpoint flows remain unchanged.
