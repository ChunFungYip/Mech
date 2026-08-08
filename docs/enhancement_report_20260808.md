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

### Batch 3 — World content

- Add additional districts and distinct combat arenas.
- Add destructible cover, environmental hazards, salvage caches, and optional encounters.

### Batch 4 — Combat depth

- Add new enemy roles, coordinated behaviors, weapons, branching upgrades, and boss mechanics.

### Batch 5 — Replayability and presentation

- Add challenge missions, score tracking, New Game Plus, cosmetics, radio dialogue, and richer city ambience.

## Batch 1 implementation notes

Kills made within six seconds continue the streak. Each consecutive kill adds 25 credits to the normal 100-credit reward. The streak expires after the timer elapses, so the bonus rewards aggressive but controlled play without changing base mission balance.

## Validation targets

- Confirm the base reward remains 100 credits.
- Confirm consecutive kills display the streak count and increased reward.
- Confirm the streak resets after six seconds without a kill.
- Confirm the existing mission, save, and checkpoint flows remain unchanged.
