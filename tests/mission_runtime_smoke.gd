extends Node

var _failed: bool = false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var settings := get_node("/root/SettingsManager")
	settings.set("tutorial_seen", true)
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

	get_tree().quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
