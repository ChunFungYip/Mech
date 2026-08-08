extends Node3D

const HongKongDistrictScript = preload("res://scripts/HongKongDistrict.gd")
const HomeBaseScript = preload("res://scripts/HomeBase.gd")
const MechPlayerScript = preload("res://scripts/MechPlayer.gd")
const EnemyMechScript = preload("res://scripts/EnemyMech.gd")
const RocketProjectileScript = preload("res://scripts/RocketProjectile.gd")
const HomingMissileScript = preload("res://scripts/HomingMissile.gd")
const CombatHazardScript = preload("res://scripts/CombatHazard.gd")
const GameHUDScript = preload("res://scripts/GameHUD.gd")
const SettingsMenuScript = preload("res://scripts/SettingsMenu.gd")
const RepairBotScript = preload("res://scripts/RepairBot.gd")
const RepairBotMenuScript = preload("res://scripts/RepairBotMenu.gd")
const BossMechScript = preload("res://scripts/BossMech.gd")
const MissionOverlayScript = preload("res://scripts/MissionOverlay.gd")
const TutorialOverlayScript = preload("res://scripts/TutorialOverlay.gd")

const ENEMY_TYPE_HEAVY: int = 0
const ENEMY_TYPE_SCOUT: int = 1
const ENEMY_TYPE_DRONE: int = 2
const ENEMY_TYPE_SPIDER: int = 3
const PLAYER_SPAWN_POSITION := Vector3(0.0, 0.0, 36.0)
const MIN_ENEMY_SPAWN_DISTANCE_FROM_PLAYER: float = 45.0
const RANDOM_ENCOUNTER_MAX_SPAWN_OFFSET: float = 4.0
const HANGAR_SAFE_CENTER := Vector3(0.0, 0.0, 39.0)
const HANGAR_NO_ENEMY_RADIUS: float = 30.0
const BOSS_CENTER_POSITION := Vector3(0.0, 0.0, 0.0)
const BOSS_AREA_RADIUS: float = 18.0

var player: Node3D
var district: Node3D
var home_base: Node3D
var hud: CanvasLayer
var settings_menu: CanvasLayer
var repair_bot: Node3D
var repair_bot_menu: CanvasLayer
var mission_overlay: CanvasLayer
var tutorial_overlay: CanvasLayer
var boss: Node3D
var _boss_area_active: bool = false
var _boss_engaged: bool = false
var _boss_defeated: bool = false
var _mission_deployed: bool = false
var _mission_complete: bool = false
var _checkpoint_position: Vector3 = PLAYER_SPAWN_POSITION
var _checkpoint_name: String = "HOME BASE"
var wave: int = 1
var kills: int = 0
var _spawn_rng := RandomNumberGenerator.new()
var _city_spawn_points: Array[Vector3] = []
var _city_spawn_triggered: Array[bool] = []
var _enemy_spawn_serial: int = 0
var _random_encounters_triggered: int = 0
var _next_wave_timer: float = 0.0
var _wave_clear_announced: bool = false
var _kill_streak: int = 0
var _kill_streak_timer: float = 0.0

const KILL_STREAK_WINDOW_SECONDS: float = 6.0
const KILL_STREAK_BONUS_PER_KILL: int = 25

const RANDOM_CITY_SPAWN_POINT_COUNT: int = 8
const RANDOM_CITY_SPAWN_TRIGGER_DISTANCE: float = 20.0
const RANDOM_CITY_SPAWN_MIN_ENEMIES: int = 1
const RANDOM_CITY_SPAWN_MAX_ENEMIES: int = 5
const RANDOM_CITY_SPAWN_MIN_SEPARATION: float = 16.0
const RANDOM_CITY_SPAWN_X_MIN: float = -10.0
const RANDOM_CITY_SPAWN_X_MAX: float = 10.0
const RANDOM_CITY_SPAWN_Z_MIN: float = -56.0
const RANDOM_CITY_SPAWN_Z_MAX: float = 16.0

func _ready() -> void:
	_build_environment()
	SettingsManager.difficulty_changed.connect(_on_difficulty_changed)
	district = HongKongDistrictScript.new()
	district.name = "MongKokDistrict"
	add_child(district)
	district.call("build", 2407)
	_spawn_home_base()
	_build_random_city_spawn_points()
	_spawn_player()
	_spawn_boss()
	_spawn_hud()
	_spawn_settings_menu()
	_spawn_repair_bot_menu()
	_spawn_mission_overlay()
	_spawn_tutorial_overlay()
	_spawn_repair_bot()
	_spawn_wave()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.012, 0.020, 0.045)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.24, 0.32, 0.48)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-56.0, -28.0, 0.0)
	moon.light_color = Color(0.42, 0.54, 0.78)
	moon.light_energy = 0.9
	moon.shadow_enabled = true
	add_child(moon)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-20.0, 148.0, 0.0)
	rim_light.light_color = Color(0.95, 0.25, 0.13)
	rim_light.light_energy = 0.20
	rim_light.shadow_enabled = false
	add_child(rim_light)

func _spawn_player() -> void:
	player = MechPlayerScript.new()
	player.name = "HK05Titan"
	add_child(player)
	player.global_position = PLAYER_SPAWN_POSITION
	player.call("setup", self)
	player.connect("player_defeated", Callable(self, "_on_player_defeated"))

func _spawn_home_base() -> void:
	home_base = HomeBaseScript.new()
	home_base.name = "TitanHomeBase"
	add_child(home_base)
	home_base.call("build")

func _spawn_boss() -> void:
	boss = BossMechScript.new()
	boss.name = "CentralMarketSiegeBoss"
	add_child(boss)
	boss.global_position = BOSS_CENTER_POSITION
	boss.call("setup", self, player)
	boss.call("apply_difficulty", SettingsManager.get_enemy_health_scale(), SettingsManager.get_enemy_damage_scale())
	boss.connect("defeated", Callable(self, "_on_boss_defeated"))
	boss.connect("phase_changed", Callable(self, "_on_boss_phase_changed"))

func _spawn_wave() -> void:
	var spawn_positions: Array[Vector3] = [
		Vector3(-10.0, 0.0, -12.0),
		Vector3(11.0, 0.0, -24.0),
		Vector3(-12.0, 0.0, -39.0),
		Vector3(13.0, 0.0, -53.0)
	]
	if wave >= 2:
		spawn_positions.append(Vector3(0.0, 0.0, -59.0))
	if wave >= 3:
		spawn_positions.append(Vector3(-6.0, 0.0, -47.0))
	var spawn_types: Array[int] = [
		ENEMY_TYPE_HEAVY,
		ENEMY_TYPE_SCOUT,
		ENEMY_TYPE_DRONE,
		ENEMY_TYPE_SPIDER,
	]
	if wave >= 2:
		spawn_types.append(ENEMY_TYPE_SCOUT)
	if wave >= 3:
		spawn_types.append(ENEMY_TYPE_DRONE)
	for index in spawn_positions.size():
		var enemy_type := spawn_types[index % spawn_types.size()]
		_spawn_enemy(spawn_positions[index], "WAVE_%02d" % wave, enemy_type)
	_wave_clear_announced = false

func _process(delta: float) -> void:
	if _kill_streak_timer > 0.0:
		_kill_streak_timer -= delta
		if _kill_streak_timer <= 0.0:
			_kill_streak = 0
	_update_mission_state()
	_keep_enemies_out_of_hangar()
	_update_boss_area()
	_update_home_base_door()
	_check_random_city_spawn_points()
	if not _boss_defeated and not _mission_complete and get_enemy_count() == 0:
		if not _wave_clear_announced:
			_wave_clear_announced = true
			_next_wave_timer = 2.5
			if hud != null and hud.has_method("_on_announcement"):
				hud.call("_on_announcement", "MARKET APPROACH CLEAR // NEXT WAVE INBOUND")
		else:
			_next_wave_timer -= delta
			if _next_wave_timer <= 0.0:
				wave += 1
				_spawn_wave()
				if hud != null and hud.has_method("_on_announcement"):
					hud.call("_on_announcement", "HOSTILE WAVE %02d // ENGAGE" % wave)

func _update_home_base_door() -> void:
	if home_base == null or not is_instance_valid(player):
		return
	if home_base.has_method("update_hangar_door"):
		home_base.call("update_hangar_door", player.global_position)

func _update_boss_area() -> void:
	if boss == null or not is_instance_valid(boss) or player == null or not is_instance_valid(player):
		_boss_area_active = false
		return
	var player_distance := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(BOSS_CENTER_POSITION.x, BOSS_CENTER_POSITION.z))
	var inside_area := player_distance <= BOSS_AREA_RADIUS
	if inside_area and not _boss_engaged:
		_boss_engaged = true
		_boss_area_active = true
		_checkpoint_position = player.global_position
		_checkpoint_name = "CENTRAL MARKET"
		if boss.has_method("activate"):
			boss.call("activate")
		save_game()
		if hud != null and hud.has_method("_on_announcement"):
			hud.call("_on_announcement", "CENTRAL MARKET // SIEGE BOSS ENGAGED")
	elif not inside_area:
		_boss_area_active = false

func _update_mission_state() -> void:
	if not is_instance_valid(player):
		return
	if not _mission_deployed and _horizontal_distance_from_hangar(player.global_position) > 30.0:
		_mission_deployed = true
		_checkpoint_position = player.global_position
		_checkpoint_name = "MARKET APPROACH"
		AudioManager.play_sound(&"mission_start", player.global_position, 1.0)
		save_game()
		if hud != null and hud.has_method("_on_announcement"):
			hud.call("_on_announcement", "SORTIE LIVE // REACH CENTRAL MARKET")
	if _boss_defeated and not _mission_complete and _horizontal_distance_from_hangar(player.global_position) < 22.0:
		_mission_complete = true
		AudioManager.play_sound(&"mission_complete", player.global_position, 1.0)
		if UpgradeManager.has_method("record_mission_complete"):
			UpgradeManager.call("record_mission_complete", 1)
		save_game()
		if hud != null and hud.has_method("_on_announcement"):
			hud.call("_on_announcement", "MISSION COMPLETE // RETURNED TO HOME BASE")
		if mission_overlay != null and mission_overlay.has_method("show_complete"):
			mission_overlay.call("show_complete")

func _build_random_city_spawn_points() -> void:
	_spawn_rng.randomize()
	_city_spawn_points.clear()
	_city_spawn_triggered.clear()
	var attempts := 0
	while _city_spawn_points.size() < RANDOM_CITY_SPAWN_POINT_COUNT and attempts < 200:
		attempts += 1
		var candidate := Vector3(
			_spawn_rng.randf_range(RANDOM_CITY_SPAWN_X_MIN, RANDOM_CITY_SPAWN_X_MAX),
			0.0,
			_spawn_rng.randf_range(RANDOM_CITY_SPAWN_Z_MIN, RANDOM_CITY_SPAWN_Z_MAX))
		if _horizontal_distance_from_player_spawn(candidate) < MIN_ENEMY_SPAWN_DISTANCE_FROM_PLAYER + RANDOM_ENCOUNTER_MAX_SPAWN_OFFSET:
			continue
		if _horizontal_distance_from_hangar(candidate) < HANGAR_NO_ENEMY_RADIUS + RANDOM_ENCOUNTER_MAX_SPAWN_OFFSET:
			continue
		var separated := true
		for existing_point in _city_spawn_points:
			if candidate.distance_to(existing_point) < RANDOM_CITY_SPAWN_MIN_SEPARATION:
				separated = false
				break
		if separated:
			_city_spawn_points.append(candidate)
			_city_spawn_triggered.append(false)

func _check_random_city_spawn_points() -> void:
	if not is_instance_valid(player):
		return
	for point_index in _city_spawn_points.size():
		if _city_spawn_triggered[point_index]:
			continue
		if player.global_position.distance_to(_city_spawn_points[point_index]) > RANDOM_CITY_SPAWN_TRIGGER_DISTANCE:
			continue
		_city_spawn_triggered[point_index] = true
		_spawn_random_city_encounter(point_index, _city_spawn_points[point_index])

func _spawn_random_city_encounter(point_index: int, center: Vector3) -> void:
	_random_encounters_triggered += 1
	var enemy_count := _spawn_rng.randi_range(RANDOM_CITY_SPAWN_MIN_ENEMIES, RANDOM_CITY_SPAWN_MAX_ENEMIES)
	for enemy_index in enemy_count:
		var angle := _spawn_rng.randf_range(0.0, TAU)
		var radius := _spawn_rng.randf_range(1.5, 4.0)
		var spawn_position := center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		spawn_position.x = clampf(spawn_position.x, RANDOM_CITY_SPAWN_X_MIN - 1.5, RANDOM_CITY_SPAWN_X_MAX + 1.5)
		spawn_position.z = clampf(spawn_position.z, RANDOM_CITY_SPAWN_Z_MIN - 1.5, RANDOM_CITY_SPAWN_Z_MAX + 1.5)
		var enemy_type := _spawn_rng.randi_range(ENEMY_TYPE_HEAVY, ENEMY_TYPE_SPIDER)
		_spawn_enemy(spawn_position, "AMBUSH_%02d" % _random_encounters_triggered, enemy_type)
	if hud != null and hud.has_method("_on_announcement"):
		hud.call("_on_announcement", "CITY AMBUSH // POINT %02d // %02d HOSTILES" % [_random_encounters_triggered, enemy_count])

func _spawn_enemy(spawn_position: Vector3, encounter_name: String, enemy_type: int = ENEMY_TYPE_HEAVY) -> Node3D:
	_enemy_spawn_serial += 1
	var enemy: Node3D = EnemyMechScript.new()
	enemy.enemy_type = enemy_type
	enemy.name = "%s_%s_%03d" % [_enemy_type_name(enemy_type), encounter_name, _enemy_spawn_serial]
	add_child(enemy)
	if _horizontal_distance_from_player_spawn(spawn_position) < MIN_ENEMY_SPAWN_DISTANCE_FROM_PLAYER:
		var away_direction := Vector3(spawn_position.x - PLAYER_SPAWN_POSITION.x, 0.0, spawn_position.z - PLAYER_SPAWN_POSITION.z)
		if away_direction.length_squared() < 0.001:
			away_direction = Vector3(0.0, 0.0, -1.0)
		spawn_position = PLAYER_SPAWN_POSITION + away_direction.normalized() * MIN_ENEMY_SPAWN_DISTANCE_FROM_PLAYER
	if _horizontal_distance_from_hangar(spawn_position) < HANGAR_NO_ENEMY_RADIUS:
		var away_from_hangar := Vector3(spawn_position.x - HANGAR_SAFE_CENTER.x, 0.0, spawn_position.z - HANGAR_SAFE_CENTER.z)
		if away_from_hangar.length_squared() < 0.001:
			away_from_hangar = Vector3(0.0, 0.0, -1.0)
		spawn_position = HANGAR_SAFE_CENTER + away_from_hangar.normalized() * HANGAR_NO_ENEMY_RADIUS
	if enemy_type == ENEMY_TYPE_DRONE:
		spawn_position.y = maxf(spawn_position.y, 6.5)
	enemy.global_position = spawn_position
	enemy.call("setup", self, player)
	enemy.call("apply_difficulty", SettingsManager.get_enemy_health_scale(), SettingsManager.get_enemy_damage_scale())
	enemy.connect("died", Callable(self, "_on_enemy_died"))
	return enemy

func _on_difficulty_changed(_level: int) -> void:
	for hostile in get_tree().get_nodes_in_group("enemy_mechs"):
		if hostile.has_method("apply_difficulty"):
			hostile.call("apply_difficulty", SettingsManager.get_enemy_health_scale(), SettingsManager.get_enemy_damage_scale())

func _horizontal_distance_from_player_spawn(position: Vector3) -> float:
	return Vector2(position.x, position.z).distance_to(Vector2(PLAYER_SPAWN_POSITION.x, PLAYER_SPAWN_POSITION.z))

func _horizontal_distance_from_hangar(position: Vector3) -> float:
	return Vector2(position.x, position.z).distance_to(Vector2(HANGAR_SAFE_CENTER.x, HANGAR_SAFE_CENTER.z))

func get_enemy_target_position() -> Vector3:
	if not is_instance_valid(player):
		return Vector3.ZERO
	var target_position := player.global_position
	if _horizontal_distance_from_hangar(target_position) < HANGAR_NO_ENEMY_RADIUS:
		var away_from_hangar := Vector3(target_position.x - HANGAR_SAFE_CENTER.x, 0.0, target_position.z - HANGAR_SAFE_CENTER.z)
		if away_from_hangar.length_squared() < 0.001:
			away_from_hangar = Vector3(0.0, 0.0, -1.0)
		target_position = HANGAR_SAFE_CENTER + away_from_hangar.normalized() * HANGAR_NO_ENEMY_RADIUS
	return target_position

func _keep_enemies_out_of_hangar() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_mechs"):
		if enemy.has_method("keep_out_of_hangar"):
			enemy.call("keep_out_of_hangar", HANGAR_SAFE_CENTER, HANGAR_NO_ENEMY_RADIUS)

func _enemy_type_name(enemy_type: int) -> String:
	match enemy_type:
		ENEMY_TYPE_SCOUT:
			return "SCOUT"
		ENEMY_TYPE_DRONE:
			return "DRONE"
		ENEMY_TYPE_SPIDER:
			return "SPIDER"
	return "HEAVY"

func _on_boss_defeated(_defeated_boss: Node) -> void:
	_boss_defeated = true
	_boss_area_active = false
	AudioManager.play_sound(&"mission_complete", BOSS_CENTER_POSITION, 1.3)
	UpgradeManager.add_credits(1000)
	save_game()
	if hud != null and hud.has_method("_on_announcement"):
		hud.call("_on_announcement", "CENTRAL MARKET // SIEGE BOSS DESTROYED // +1000 CREDITS")

func _on_boss_phase_changed(phase: int) -> void:
	AudioManager.play_sound(&"boss_phase", BOSS_CENTER_POSITION, 1.2)
	if hud != null and hud.has_method("_on_announcement"):
		hud.call("_on_announcement", "SIEGE BOSS // PHASE %02d // THREAT ESCALATING" % phase)

func _spawn_hud() -> void:
	hud = GameHUDScript.new()
	add_child(hud)
	hud.call("setup", player, self)

func _spawn_settings_menu() -> void:
	settings_menu = SettingsMenuScript.new()
	settings_menu.name = "SettingsMenu"
	add_child(settings_menu)
	settings_menu.call("setup", self)

func _spawn_repair_bot_menu() -> void:
	repair_bot_menu = RepairBotMenuScript.new()
	repair_bot_menu.name = "RepairBotMenu"
	add_child(repair_bot_menu)

func _spawn_mission_overlay() -> void:
	mission_overlay = MissionOverlayScript.new()
	mission_overlay.name = "MissionOverlay"
	add_child(mission_overlay)
	mission_overlay.call("setup", self)

func _spawn_tutorial_overlay() -> void:
	tutorial_overlay = TutorialOverlayScript.new()
	tutorial_overlay.name = "TutorialOverlay"
	add_child(tutorial_overlay)
	tutorial_overlay.call("setup", self)

func _spawn_repair_bot() -> void:
	repair_bot = RepairBotScript.new()
	repair_bot.name = "RepairBot"
	add_child(repair_bot)
	repair_bot.global_position = Vector3(5.6, 0.0, 45.0)
	repair_bot.call("setup", self, player)

func open_repair_bot() -> void:
	if repair_bot_menu != null and repair_bot_menu.has_method("open_menu"):
		repair_bot_menu.call("open_menu", player)

func save_game(slot_id: int = -1) -> bool:
	if slot_id < 1:
		slot_id = int(UpgradeManager.active_slot)
	if player == null or not is_instance_valid(player):
		return false
	if not UpgradeManager.save_slot(slot_id):
		return false
	return UpgradeManager.save_game_state(slot_id, _build_game_state())

func load_game(slot_id: int = -1) -> bool:
	if slot_id < 1:
		slot_id = int(UpgradeManager.active_slot)
	if not UpgradeManager.has_game_state(slot_id):
		return false
	if not UpgradeManager.load_slot(slot_id):
		return false
	var state := UpgradeManager.load_game_state(slot_id)
	if state.is_empty():
		return false
	_restore_game_state(state)
	if settings_menu != null and settings_menu.has_method("close_menu"):
		settings_menu.call("close_menu")
	return true

func _build_game_state() -> Dictionary:
	var triggered_points: Array[int] = []
	for triggered in _city_spawn_triggered:
		triggered_points.append(1 if triggered else 0)
	var enemy_states: Array[Dictionary] = []
	for hostile in get_tree().get_nodes_in_group("enemy_mechs"):
		if hostile == boss or not hostile.has_method("get_save_state"):
			continue
		enemy_states.append(hostile.call("get_save_state"))
	var state: Dictionary = {
		"version": 1,
		"player_position": player.global_position,
		"player_health": float(player.get("health")),
		"machinegun_ammo": int(player.get("machinegun_ammo")),
		"machinegun_reserve": int(player.get("machinegun_reserve")),
		"rocket_ammo": int(player.get("rocket_ammo")),
		"rocket_reserve": int(player.get("rocket_reserve")),
		"missile_salvo_count": int(player.get("missile_salvo_count")),
		"emp_cooldown": float(player.get("_emp_cooldown")),
		"current_weapon": int(player.get("current_weapon")),
		"first_person": player.get("first_person") == true,
		"player_yaw": float(player.get("yaw")),
		"player_pitch": float(player.get("pitch")),
		"mission_deployed": _mission_deployed,
		"mission_complete": _mission_complete,
		"boss_engaged": _boss_engaged,
		"boss_defeated": _boss_defeated,
		"boss_area_active": _boss_area_active,
		"checkpoint_position": _checkpoint_position,
		"checkpoint_name": _checkpoint_name,
		"wave": wave,
		"kills": kills,
		"city_spawn_triggered": triggered_points,
		"random_encounters_triggered": _random_encounters_triggered,
		"next_wave_timer": _next_wave_timer,
		"wave_clear_announced": _wave_clear_announced,
		"enemies": enemy_states,
	}
	if boss != null and is_instance_valid(boss):
		state["boss_position"] = boss.global_position
		state["boss_active"] = boss.get("active") == true
		state["boss_phase"] = int(boss.get("phase"))
		state["boss_health_ratio"] = float(boss.call("get_health_percent")) if boss.has_method("get_health_percent") else 1.0
		state["boss_attack_damage"] = float(boss.get("attack_damage"))
		state["boss_attack_timer"] = float(boss.get("_attack_timer"))
		state["boss_special_attack_timer"] = float(boss.get("_special_attack_timer"))
		state["boss_special_attack_index"] = int(boss.get("_special_attack_index"))
	return state

func _restore_game_state(state: Dictionary) -> void:
	_clear_combat_units()
	_mission_deployed = state.get("mission_deployed", false) == true
	_mission_complete = state.get("mission_complete", false) == true
	_boss_engaged = state.get("boss_engaged", false) == true
	_boss_defeated = state.get("boss_defeated", false) == true
	_boss_area_active = state.get("boss_area_active", false) == true
	_checkpoint_name = str(state.get("checkpoint_name", "HOME BASE"))
	var saved_checkpoint = state.get("checkpoint_position", PLAYER_SPAWN_POSITION)
	if saved_checkpoint is Vector3:
		_checkpoint_position = saved_checkpoint
	wave = maxi(int(state.get("wave", 1)), 1)
	kills = maxi(int(state.get("kills", 0)), 0)
	_random_encounters_triggered = maxi(int(state.get("random_encounters_triggered", 0)), 0)
	_next_wave_timer = maxf(float(state.get("next_wave_timer", 0.0)), 0.0)
	_wave_clear_announced = state.get("wave_clear_announced", false) == true
	_city_spawn_triggered.clear()
	var saved_triggered = state.get("city_spawn_triggered", [])
	for point_index in _city_spawn_points.size():
		_city_spawn_triggered.append(point_index < saved_triggered.size() and int(saved_triggered[point_index]) != 0)

	if is_instance_valid(player) and player.has_method("restore_save_state"):
		player.call("restore_save_state", state)

	if _boss_defeated:
		if boss != null and is_instance_valid(boss):
			boss.queue_free()
		boss = null
	else:
		if boss == null or not is_instance_valid(boss) or boss.get("_dead") == true:
			if boss != null and is_instance_valid(boss):
				boss.queue_free()
			boss = null
			_spawn_boss()
		if boss.has_method("restore_save_state"):
			boss.call("restore_save_state", state)

	var saved_enemies = state.get("enemies", [])
	for enemy_state in saved_enemies:
		if not enemy_state is Dictionary:
			continue
		var enemy_position = enemy_state.get("position", Vector3.ZERO)
		if not enemy_position is Vector3:
			continue
		var enemy_type := clampi(int(enemy_state.get("enemy_type", ENEMY_TYPE_HEAVY)), ENEMY_TYPE_HEAVY, ENEMY_TYPE_SPIDER)
		var enemy := _spawn_enemy(enemy_position, "SAVE_%02d" % wave, enemy_type)
		if enemy != null and enemy.has_method("restore_save_state"):
			enemy.call("restore_save_state", enemy_state)

func _on_player_defeated() -> void:
	if mission_overlay != null and mission_overlay.has_method("show_failure"):
		mission_overlay.call("show_failure", _checkpoint_name)

func restart_from_checkpoint() -> void:
	_clear_combat_units()
	_reset_boss_for_checkpoint()
	if is_instance_valid(player) and player.has_method("restore_after_failure"):
		player.call("restore_after_failure", _checkpoint_position)
	_wave_clear_announced = false
	_next_wave_timer = 0.0
	_kill_streak = 0
	_kill_streak_timer = 0.0
	_spawn_wave()
	if mission_overlay != null:
		mission_overlay.call("close_overlay")

func restart_mission() -> void:
	_mission_deployed = false
	_mission_complete = false
	_boss_defeated = false
	_boss_engaged = false
	_boss_area_active = false
	_checkpoint_position = PLAYER_SPAWN_POSITION
	_checkpoint_name = "HOME BASE"
	wave = 1
	kills = 0
	_city_spawn_triggered.fill(false)
	_random_encounters_triggered = 0
	_clear_combat_units()
	_reset_boss_for_checkpoint()
	if is_instance_valid(player) and player.has_method("restore_after_failure"):
		player.call("restore_after_failure", PLAYER_SPAWN_POSITION)
	_wave_clear_announced = false
	_next_wave_timer = 0.0
	_kill_streak = 0
	_kill_streak_timer = 0.0
	_spawn_wave()
	if mission_overlay != null:
		mission_overlay.call("close_overlay")

func _clear_combat_units() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy_mechs"):
		if enemy != boss:
			enemy.queue_free()
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()
	for hazard in get_tree().get_nodes_in_group("combat_hazards"):
		hazard.queue_free()

func _reset_boss_for_checkpoint() -> void:
	if boss == null or not is_instance_valid(boss) or boss.get("is_defeated") == true or boss.get("_dead") == true:
		if boss != null and is_instance_valid(boss):
			boss.queue_free()
		_spawn_boss()
	elif boss.has_method("reset_encounter"):
		boss.call("reset_encounter")
	_boss_defeated = false
	if _checkpoint_name == "CENTRAL MARKET" and boss.has_method("activate"):
		_boss_engaged = true
		boss.call("activate")

func get_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemy_mechs"):
		if enemy.get("is_boss") != true:
			count += 1
	return count

func get_boss() -> Node:
	return boss

func is_boss_area_active() -> bool:
	return _boss_area_active

func is_boss_engaged() -> bool:
	return _boss_engaged and not _boss_defeated

func get_mission_objective() -> String:
	if _mission_complete:
		return "MISSION COMPLETE // HOME BASE SECURED"
	if not _mission_deployed:
		return "OBJECTIVE // EXIT HOME BASE"
	if not _boss_defeated:
		if _boss_engaged:
			return "OBJECTIVE // DEFEAT CENTRAL MARKET BOSS"
		return "OBJECTIVE // REACH CENTRAL MARKET"
	return "OBJECTIVE // RETURN TO HOME BASE"

func _on_enemy_died(_enemy: Node) -> void:
	kills += 1
	_kill_streak = _kill_streak + 1 if _kill_streak_timer > 0.0 else 1
	_kill_streak_timer = KILL_STREAK_WINDOW_SECONDS
	var reward := 100 + (_kill_streak - 1) * KILL_STREAK_BONUS_PER_KILL
	UpgradeManager.add_credits(reward)
	if hud != null and hud.has_method("_on_announcement"):
		var streak_text := " // STREAK x%02d" % _kill_streak if _kill_streak >= 2 else ""
		hud.call("_on_announcement", "HOSTILE DISABLED // CONFIRMED %02d // +%d CREDITS%s" % [kills, reward, streak_text])

func spawn_player_rocket(origin: Vector3, direction: Vector3, shooter: Node, damage: float = 110.0, explosion_radius: float = 5.0) -> void:
	var rocket: Node3D = RocketProjectileScript.new()
	add_child(rocket)
	rocket.call("setup", self, shooter, origin, direction, &"enemy_mechs", damage, explosion_radius)

func spawn_player_missile_salvo(origin: Vector3, direction: Vector3, shooter: Node, target: Node3D, damage: float = 46.0, explosion_radius: float = 2.8, salvo_size: int = 8) -> void:
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	var up := side.cross(direction).normalized()
	var launch_offsets: Array[Vector2] = []
	var missile_count := maxi(salvo_size, 1)
	for missile_index in missile_count:
		var centered_index := float(missile_index) - float(missile_count - 1) * 0.5
		var row_offset := 0.18 if missile_index % 2 == 0 else -0.18
		launch_offsets.append(Vector2(centered_index * 0.22, row_offset))
	for offset in launch_offsets:
		var missile: Node3D = HomingMissileScript.new()
		add_child(missile)
		var launch_position := origin + side * offset.x + up * offset.y
		var launch_direction := (direction + side * offset.x * 0.045 + up * offset.y * 0.045).normalized()
		missile.call("setup", self, shooter, launch_position, launch_direction, target, damage, explosion_radius)

func spawn_emp_pulse(position: Vector3, radius: float = 13.0, damage: float = 90.0) -> void:
	for hostile in get_tree().get_nodes_in_group("enemy_mechs"):
		var enemy := hostile as Node3D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := Vector2(enemy.global_position.x, enemy.global_position.z).distance_to(Vector2(position.x, position.z))
		if distance <= radius and enemy.has_method("take_damage"):
			enemy.call("take_damage", damage, enemy.global_position + Vector3(0.0, 2.0, 0.0))
			if enemy.has_method("apply_emp"):
				enemy.call("apply_emp", 2.4)
	var pulse := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.35
	mesh.bottom_radius = 0.35
	mesh.height = 0.08
	pulse.mesh = mesh
	pulse.position = Vector3(position.x, 0.12, position.z)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.88, 1.0, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.08, 0.72, 1.0)
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse.material_override = material
	pulse.scale = Vector3(0.08, 1.0, 0.08)
	add_child(pulse)
	var light := OmniLight3D.new()
	light.position = pulse.position + Vector3(0.0, 1.5, 0.0)
	light.light_color = Color(0.08, 0.72, 1.0)
	light.light_energy = 4.5
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)
	var end_scale := Vector3(radius / 0.35, 1.0, radius / 0.35)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", end_scale, 0.34)
	tween.parallel().tween_method(Callable(self, "_set_effect_alpha").bind(material), material.albedo_color.a, 0.0, 0.34)
	tween.tween_callback(Callable(pulse, "queue_free"))
	get_tree().create_timer(0.40).timeout.connect(Callable(light, "queue_free"))

func spawn_boss_missile_salvo(origin: Vector3, direction: Vector3, shooter: Node, target: Node3D, damage: float = 32.0, explosion_radius: float = 3.6) -> void:
	var side := direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	var up := side.cross(direction).normalized()
	for missile_index in 5:
		var centered_index := float(missile_index) - 2.0
		var offset := side * centered_index * 0.28 + up * (0.12 if missile_index % 2 == 0 else -0.12)
		var missile: Node3D = HomingMissileScript.new()
		add_child(missile)
		var launch_position := origin + offset
		var launch_direction := (direction + offset * 0.035).normalized()
		missile.call("setup", self, shooter, launch_position, launch_direction, target, damage, explosion_radius, &"player_mechs")

func spawn_boss_hazard(position: Vector3, radius: float = 5.5, damage: float = 38.0, warning_seconds: float = 1.2, active_seconds: float = 3.4) -> void:
	var hazard: Node3D = CombatHazardScript.new()
	add_child(hazard)
	hazard.call("setup", self, player, position, radius, damage, warning_seconds, active_seconds, Color(1.0, 0.12, 0.035))

func spawn_tracer(start: Vector3, finish: Vector3, color: Color) -> void:
	var difference := finish - start
	if difference.length_squared() < 0.0001:
		return
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.055, 0.055, difference.length())
	tracer.mesh = mesh
	tracer.position = (start + finish) * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer.material_override = material
	add_child(tracer)
	tracer.look_at_from_position(tracer.position, finish, Vector3.UP)
	get_tree().create_timer(0.075).timeout.connect(Callable(tracer, "queue_free"))

func spawn_hit_spark(position: Vector3) -> void:
	spawn_explosion(position, 0.30 if SettingsManager.reduced_effects else 0.42, Color(1.0, 0.78, 0.24))
	var spark_count := 3 if SettingsManager.reduced_effects else 6
	for spark_index in spark_count:
		var spark := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.035, 0.035, 0.24)
		spark.mesh = mesh
		spark.position = position
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.72, 0.16)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.22, 0.03)
		material.emission_energy_multiplier = 4.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark.material_override = material
		add_child(spark)
		var angle := TAU * float(spark_index) / 6.0 + randf_range(-0.25, 0.25)
		var direction := Vector3(cos(angle), randf_range(-0.5, 0.7), sin(angle)).normalized()
		spark.look_at_from_position(position, position + direction, Vector3.UP)
		var tween := create_tween()
		tween.tween_property(spark, "position", position + direction * randf_range(0.35, 0.85), 0.20)
		tween.parallel().tween_property(spark, "scale", Vector3(0.2, 0.2, 0.2), 0.20)
		tween.parallel().tween_method(Callable(self, "_set_effect_alpha").bind(material), material.albedo_color.a, 0.0, 0.20)
		tween.chain().tween_callback(Callable(spark, "queue_free"))

func spawn_smoke_puff(position: Vector3, color: Color) -> void:
	var puff := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	puff.mesh = mesh
	puff.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material_override = material
	add_child(puff)
	var tween := create_tween()
	tween.tween_property(puff, "scale", Vector3.ONE * 2.6, 0.32)
	tween.parallel().tween_method(Callable(self, "_set_effect_alpha").bind(material), material.albedo_color.a, 0.0, 0.32)
	tween.chain().tween_callback(Callable(puff, "queue_free"))

func _set_effect_alpha(alpha: float, material: StandardMaterial3D) -> void:
	var color := material.albedo_color
	color.a = alpha
	material.albedo_color = color

func spawn_sprint_exhaust(position: Vector3, movement_direction: Vector3) -> void:
	var exhaust_direction := -movement_direction.normalized() if movement_direction.length_squared() > 0.001 else Vector3.BACK
	var side := exhaust_direction.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	for side_offset in [-0.72, 0.72]:
		var puff_position: Vector3 = position + side * side_offset + exhaust_direction * 0.8 + Vector3(0.0, 0.25, 0.0)
		spawn_smoke_puff(puff_position, Color(0.10, 0.62, 0.90, 0.42))

func spawn_explosion(position: Vector3, radius: float, color: Color = Color(1.0, 0.34, 0.05)) -> void:
	if SettingsManager.reduced_effects:
		radius *= 0.68
	_spawn_particle_burst(position, radius, color)
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	flash.mesh = mesh
	flash.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = material
	add_child(flash)

	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = 5.0
	light.omni_range = maxf(radius * 2.0, 2.0)
	light.shadow_enabled = false
	add_child(light)

	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * maxf(radius * 0.32, 0.9), 0.16)
	tween.tween_callback(Callable(flash, "queue_free"))
	get_tree().create_timer(0.22).timeout.connect(Callable(light, "queue_free"))

func _spawn_particle_burst(position: Vector3, radius: float, color: Color) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 8 if SettingsManager.reduced_effects else 20
	particles.lifetime = 0.62
	particles.one_shot = true
	particles.explosiveness = 1.0
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.18
	process_material.direction = Vector3.UP
	process_material.spread = 180.0
	process_material.initial_velocity_min = radius * 0.65
	process_material.initial_velocity_max = radius * 1.25
	process_material.gravity = Vector3(0.0, -8.0, 0.0)
	process_material.scale_min = 0.08
	process_material.scale_max = 0.22
	process_material.color = Color(color.r, color.g, color.b, 1.0)
	particles.process_material = process_material
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.10
	particle_mesh.height = 0.20
	var particle_material := StandardMaterial3D.new()
	particle_material.albedo_color = Color(color.r, color.g, color.b, 1.0)
	particle_material.emission_enabled = true
	particle_material.emission = color
	particle_material.emission_energy_multiplier = 4.0
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_mesh.material = particle_material
	particles.draw_pass_1 = particle_mesh
	particles.position = position
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.80).timeout.connect(Callable(particles, "queue_free"))
