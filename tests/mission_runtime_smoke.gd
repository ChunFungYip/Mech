extends Node

var _failed: bool = false
const TEST_SLOT: int = 3
var _backups: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings := get_node("/root/SettingsManager")
	settings.set("tutorial_seen", true)
	_backup_file("user://mech_upgrade_profile.cfg")
	_backup_file("user://mech_campaign_slot_3.cfg")
	_backup_file("user://mech_campaign_slot_3_state.cfg")
	var main := preload("res://scripts/Main.gd").new()
	main.name = "RuntimeSmokeMain"
	add_child(main)
	await process_frame
	await process_frame
	_check(main.player != null, "player was not spawned")
	_check(main.mission_overlay != null, "mission overlay was not spawned")

	var player := main.player
	player.call("take_damage", float(player.get("health")) + 1.0, Vector3.ZERO)
	await process_frame
	_check(main.mission_overlay.call("is_open") == true, "failure overlay did not open")
	main.call("restart_from_checkpoint")
	await process_frame
	_check(main.mission_overlay.call("is_open") == false, "checkpoint restart did not close overlay")
	_check(int(player.get("machinegun_ammo")) == int(player.get("machinegun_magazine_size")), "checkpoint restart did not restore machine-gun ammo")

	main.call("spawn_emp_pulse", player.global_position, 13.0, 0.0)
	main.call("spawn_boss_hazard", player.global_position, 3.0, 0.0, 0.05, 0.1)
	main.call("spawn_boss_missile_salvo", player.global_position + Vector3(0.0, 4.0, -2.0), Vector3(0.0, 0.0, -1.0), main.boss, player, 0.0, 1.0)
	await process_frame
	_check(get_nodes_in_group("combat_hazards").size() > 0, "boss hazard was not spawned")
	_check(get_nodes_in_group("projectiles").size() > 0, "boss missiles were not spawned")
	main.call("restart_mission")
	await process_frame
	_check(main.boss != null and is_instance_valid(main.boss), "mission restart did not restore the boss")
	_check(main.get("_mission_deployed") == false, "mission restart did not reset deployment state")

	var saved_position := Vector3(-4.0, 0.0, -18.0)
	player.global_position = saved_position
	player.set("health", 271.0)
	player.set("machinegun_ammo", 17)
	player.set("rocket_ammo", 2)
	main.set("_mission_deployed", true)
	main.set("_boss_engaged", true)
	main.set("_checkpoint_name", "CENTRAL MARKET")
	main.set("_checkpoint_position", saved_position)
	main.set("wave", 4)
	var save_result: bool = main.call("save_game", TEST_SLOT)
	_check(save_result, "save_game returned false")
	player.global_position = Vector3(25.0, 0.0, 25.0)
	player.set("health", 42.0)
	player.set("machinegun_ammo", 1)
	main.set("_mission_deployed", false)
	main.set("_boss_engaged", false)
	main.set("wave", 1)
	var load_result: bool = main.call("load_game", TEST_SLOT)
	_check(load_result, "load_game returned false")
	await process_frame
	_check(player.global_position.distance_to(saved_position) < 0.01, "load_game did not restore player position")
	_check(is_equal_approx(float(player.get("health")), 271.0), "load_game did not restore player health")
	_check(int(player.get("machinegun_ammo")) == 17, "load_game did not restore machine-gun ammo")
	_check(main.get("_mission_deployed") == true, "load_game did not restore mission state")
	_check(main.get("_boss_engaged") == true, "load_game did not restore boss state")
	_check(int(main.get("wave")) == 4, "load_game did not restore wave")
	_check(main.get_enemy_count() > 0, "load_game did not restore saved enemies")

	_restore_backups()
	get_tree().quit(0)

func _backup_file(path: String) -> void:
	_backups[path] = {
		"exists": FileAccess.file_exists(path),
		"data": FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray(),
	}

func _restore_backups() -> void:
	for path in _backups.keys():
		var backup: Dictionary = _backups[path]
		if backup["exists"]:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(backup["data"])
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
