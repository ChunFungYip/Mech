extends CharacterBody3D
class_name MechPlayer

enum WeaponMode {
    DUAL_HANDS,
    MISSILE_POD,
}

signal stats_changed
signal view_mode_changed(first_person: bool)
signal announcement(text: String)
signal damage_taken(amount: float, hit_position: Vector3)
signal weapon_hit(part_name: String, critical: bool, destroyed: bool)
signal player_defeated

@export var move_speed: float = 7.5
@export var boost_multiplier: float = 1.65
@export var acceleration: float = 24.0
@export var gravity: float = 18.0
@export var respawn_invulnerability_seconds: float = 3.0
@export var sprint_safe_duration: float = 10.0
@export var sprint_max_duration: float = 20.0
@export var sprint_recovery_seconds: float = 6.0
@export var sprint_overheat_recovery_multiplier: float = 3.0
@export var health_max: float = 500.0
@export var machinegun_magazine_size: int = 60
@export var machinegun_reserve_max: int = 240
@export var machinegun_damage: float = 16.0
@export var machinegun_fire_interval: float = 0.085
@export var machinegun_reload_time: float = 1.8
@export var rocket_magazine_size: int = 6
@export var rocket_reserve_max: int = 12
@export var rocket_damage: float = 110.0
@export var rocket_explosion_radius: float = 5.0
@export var missile_salvo_count: int = 4
@export var missile_salvo_size: int = 8
@export var missile_damage: float = 46.0
@export var missile_explosion_radius: float = 2.8

var health: float = health_max
var machinegun_ammo: int = machinegun_magazine_size
var machinegun_reserve: int = machinegun_reserve_max
var rocket_ammo: int = rocket_magazine_size
var rocket_reserve: int = rocket_reserve_max
var current_weapon: WeaponMode = WeaponMode.DUAL_HANDS
var first_person: bool = true
var yaw: float = 0.0
var pitch: float = -0.08
var mouse_sensitivity_x: float = 0.0025
var mouse_sensitivity_y: float = 0.0022
var mouse_invert_y: bool = false
var sprint_elapsed: float = 0.0
var sprint_recovery_timer: float = 0.0
var sprint_active: bool = false
var sprint_overheated: bool = false
var _sprint_extended_announced: bool = false

var game: Node3D
var _body_visual: Node3D
var _cockpit_visual: Node3D
var _first_person_weapon_visual: Node3D
var _missile_port_visual: Node3D
var _left_muzzle_flash: MeshInstance3D
var _right_muzzle_flash: MeshInstance3D
var _left_muzzle_light: OmniLight3D
var _right_muzzle_light: OmniLight3D
var _left_muzzle_timer: float = 0.0
var _right_muzzle_timer: float = 0.0
var _movement_audio_timer: float = 0.0
var _sprint_exhaust_timer: float = 0.0
var _view_pivot: Node3D
var _spring_arm: SpringArm3D
var _first_person_camera: Camera3D
var _third_person_camera: Camera3D
var _machinegun_cooldown: float = 0.0
var _rocket_cooldown: float = 0.0
var _emp_cooldown: float = 0.0
var _reload_timer: float = 0.0
var _missile_lock_target: Node3D
var _camera_recoil: float = 0.0
var _respawn_invulnerability_timer: float = 0.0
var _disabled: bool = false
var _base_health_max: float
var _base_move_speed: float
var _base_boost_multiplier: float
var _base_machinegun_damage: float
var _base_machinegun_fire_interval: float
var _base_rocket_damage: float
var _base_rocket_explosion_radius: float
var _base_missile_damage: float
const MISSILE_LOCK_RANGE: float = 180.0
const MISSILE_LOCK_CONE_DEGREES: float = 8.0

func setup(game_instance: Node3D) -> void:
    game = game_instance

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    add_to_group("player_mechs")
    floor_snap_length = 0.5
    floor_stop_on_slope = true
    _build_collision()
    _build_visual()
    _build_cameras()
    _build_first_person_cockpit()
    _cache_base_stats()
    _connect_settings()
    _connect_upgrade_manager()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _cache_base_stats() -> void:
    _base_health_max = health_max
    _base_move_speed = move_speed
    _base_boost_multiplier = boost_multiplier
    _base_machinegun_damage = machinegun_damage
    _base_machinegun_fire_interval = machinegun_fire_interval
    _base_rocket_damage = rocket_damage
    _base_rocket_explosion_radius = rocket_explosion_radius
    _base_missile_damage = missile_damage

func _connect_upgrade_manager() -> void:
    UpgradeManager.profile_changed.connect(_apply_upgrade_profile)
    UpgradeManager.weapon_group_changed.connect(_on_weapon_group_changed)
    UpgradeManager.mech_tuning_changed.connect(_on_mech_tuning_changed)
    _apply_upgrade_profile()

func _connect_settings() -> void:
    SettingsManager.field_of_view_changed.connect(_on_field_of_view_changed)
    SettingsManager.mouse_sensitivity_changed.connect(_on_mouse_sensitivity_changed)
    SettingsManager.mouse_invert_y_changed.connect(_on_mouse_invert_y_changed)
    _on_field_of_view_changed(SettingsManager.field_of_view)
    _on_mouse_sensitivity_changed(SettingsManager.mouse_sensitivity_x, SettingsManager.mouse_sensitivity_y)
    _on_mouse_invert_y_changed(SettingsManager.mouse_invert_y)

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 1.35
    capsule.height = 5.0
    collision.shape = capsule
    collision.position = Vector3(0.0, 2.5, 0.0)
    add_child(collision)

func _material(color: Color, emission_energy: float = 0.0, roughness: float = 0.58) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_energy
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return material

func _visual_box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)
    return mesh_instance

func _build_visual() -> void:
    _body_visual = Node3D.new()
    _body_visual.name = "MechVisual"
    add_child(_body_visual)

    var armor_dark := Color(0.07, 0.12, 0.15)
    var armor_mid := Color(0.12, 0.30, 0.34)
    var armor_light := Color(0.22, 0.56, 0.56)
    var hazard := Color(0.96, 0.36, 0.08)
    var cockpit := Color(0.03, 0.15, 0.18)

    _visual_box(_body_visual, Vector3(0.0, 2.95, 0.0), Vector3(2.5, 2.7, 1.65), armor_mid)
    _visual_box(_body_visual, Vector3(0.0, 3.35, -0.86), Vector3(1.8, 0.85, 0.08), armor_light, 1.2)
    _visual_box(_body_visual, Vector3(0.0, 4.35, 0.0), Vector3(1.65, 1.25, 1.35), armor_dark)
    _visual_box(_body_visual, Vector3(0.0, 4.4, -0.72), Vector3(1.05, 0.34, 0.08), cockpit, 2.4)
    _visual_box(_body_visual, Vector3(0.0, 4.85, 0.0), Vector3(0.42, 0.25, 0.42), hazard, 2.0)
    _visual_box(_body_visual, Vector3(-1.55, 3.55, 0.0), Vector3(0.58, 1.7, 0.9), armor_dark)
    _visual_box(_body_visual, Vector3(1.55, 3.55, 0.0), Vector3(0.58, 1.7, 0.9), armor_dark)
    _visual_box(_body_visual, Vector3(-1.62, 2.75, -0.55), Vector3(0.72, 0.55, 1.55), armor_light)
    _visual_box(_body_visual, Vector3(1.62, 2.75, -0.55), Vector3(0.72, 0.55, 1.55), armor_light)
    _visual_box(_body_visual, Vector3(-1.72, 2.55, -1.55), Vector3(0.48, 0.48, 2.3), armor_dark)
    _visual_box(_body_visual, Vector3(1.72, 2.55, -1.55), Vector3(0.48, 0.48, 2.3), armor_dark)
    _visual_box(_body_visual, Vector3(-0.72, 1.25, 0.0), Vector3(0.82, 2.5, 1.05), armor_mid)
    _visual_box(_body_visual, Vector3(0.72, 1.25, 0.0), Vector3(0.82, 2.5, 1.05), armor_mid)
    _visual_box(_body_visual, Vector3(-0.72, 0.16, -0.32), Vector3(1.0, 0.32, 1.65), armor_dark)
    _visual_box(_body_visual, Vector3(0.72, 0.16, -0.32), Vector3(1.0, 0.32, 1.65), armor_dark)

    _visual_box(_body_visual, Vector3(1.72, 3.00, -2.55), Vector3(0.42, 0.42, 2.8), Color(0.03, 0.06, 0.07))
    _visual_box(_body_visual, Vector3(1.72, 3.00, -4.05), Vector3(0.18, 0.18, 0.35), hazard, 3.5)
    _visual_box(_body_visual, Vector3(-1.58, 3.45, -1.0), Vector3(0.82, 1.0, 1.2), Color(0.16, 0.20, 0.21))
    _visual_box(_body_visual, Vector3(-1.58, 3.45, -1.68), Vector3(0.58, 0.58, 0.55), hazard, 2.4)

    for side in [-1.0, 1.0]:
        _visual_box(_body_visual, Vector3(side * 1.02, 4.1, 0.0), Vector3(0.12, 0.75, 0.16), hazard, 2.0)

func _build_cameras() -> void:
    _view_pivot = Node3D.new()
    _view_pivot.name = "ViewPivot"
    _view_pivot.position = Vector3(0.0, 3.35, 0.0)
    add_child(_view_pivot)

    _first_person_camera = Camera3D.new()
    _first_person_camera.name = "CockpitCamera"
    _first_person_camera.position = Vector3(0.0, 1.0, -0.42)
    _first_person_camera.fov = 76.0
    _first_person_camera.near = 0.08
    _first_person_camera.far = 300.0
    _view_pivot.add_child(_first_person_camera)

    _spring_arm = SpringArm3D.new()
    _spring_arm.name = "ThirdPersonSpringArm"
    _spring_arm.position = Vector3(0.0, 1.2, 0.0)
    _spring_arm.spring_length = 11.0
    _spring_arm.margin = 0.45
    _spring_arm.collision_mask = 1
    _view_pivot.add_child(_spring_arm)

    _third_person_camera = Camera3D.new()
    _third_person_camera.name = "ChaseCamera"
    _third_person_camera.fov = 70.0
    _third_person_camera.near = 0.08
    _third_person_camera.far = 300.0
    _spring_arm.add_child(_third_person_camera)
    _first_person_camera.current = true
    _third_person_camera.current = false
    _body_visual.visible = false

func _build_first_person_cockpit() -> void:
    _cockpit_visual = Node3D.new()
    _cockpit_visual.name = "CockpitInterior"
    _first_person_camera.add_child(_cockpit_visual)

    var armor_dark := Color(0.035, 0.075, 0.09)
    var armor_mid := Color(0.08, 0.22, 0.25)
    var armor_light := Color(0.18, 0.48, 0.48)
    var hazard := Color(0.96, 0.30, 0.06)
    var display_blue := Color(0.10, 0.76, 0.88)

    # Keep the cockpit framing at the edges so the center remains clear for aiming.
    _visual_box(_cockpit_visual, Vector3(-1.38, 0.18, -2.15), Vector3(0.18, 1.75, 0.22), armor_mid)
    _visual_box(_cockpit_visual, Vector3(1.38, 0.18, -2.15), Vector3(0.18, 1.75, 0.22), armor_mid)
    _visual_box(_cockpit_visual, Vector3(0.0, 0.86, -2.15), Vector3(2.75, 0.16, 0.22), armor_dark)
    _visual_box(_cockpit_visual, Vector3(0.0, -0.73, -1.75), Vector3(2.65, 0.20, 0.30), armor_dark)
    _visual_box(_cockpit_visual, Vector3(-1.08, -0.57, -1.45), Vector3(0.36, 0.46, 0.58), armor_light)
    _visual_box(_cockpit_visual, Vector3(1.08, -0.57, -1.45), Vector3(0.36, 0.46, 0.58), armor_light)
    _visual_box(_cockpit_visual, Vector3(0.0, -0.68, -1.42), Vector3(1.28, 0.16, 0.52), armor_mid)
    _visual_box(_cockpit_visual, Vector3(-0.72, 0.56, -2.05), Vector3(0.48, 0.08, 0.08), hazard, 2.4)
    _visual_box(_cockpit_visual, Vector3(0.72, 0.56, -2.05), Vector3(0.48, 0.08, 0.08), hazard, 2.4)
    _visual_box(_cockpit_visual, Vector3(-0.42, -0.62, -1.68), Vector3(0.20, 0.035, 0.24), display_blue, 3.0)
    _visual_box(_cockpit_visual, Vector3(0.42, -0.62, -1.68), Vector3(0.20, 0.035, 0.24), display_blue, 3.0)

    _first_person_weapon_visual = Node3D.new()
    _first_person_weapon_visual.name = "FirstPersonWeapons"
    _first_person_camera.add_child(_first_person_weapon_visual)

    # Machine gun stays low on the right; the rocket pod sits low on the left.
    _visual_box(_first_person_weapon_visual, Vector3(0.82, -0.49, -1.20), Vector3(0.32, 0.34, 0.76), armor_mid)
    _visual_box(_first_person_weapon_visual, Vector3(0.82, -0.46, -1.76), Vector3(0.18, 0.18, 0.72), armor_dark)
    _visual_box(_first_person_weapon_visual, Vector3(0.82, -0.46, -2.18), Vector3(0.08, 0.08, 0.28), hazard, 4.0)
    _visual_box(_first_person_weapon_visual, Vector3(0.62, -0.30, -1.02), Vector3(0.12, 0.22, 0.40), armor_light)
    _visual_box(_first_person_weapon_visual, Vector3(1.02, -0.30, -1.02), Vector3(0.12, 0.22, 0.40), armor_light)
    _visual_box(_first_person_weapon_visual, Vector3(-0.80, -0.50, -1.18), Vector3(0.50, 0.36, 0.70), armor_mid)
    _visual_box(_first_person_weapon_visual, Vector3(-0.96, -0.50, -1.72), Vector3(0.18, 0.18, 0.78), armor_dark)
    _visual_box(_first_person_weapon_visual, Vector3(-0.64, -0.50, -1.72), Vector3(0.18, 0.18, 0.78), armor_dark)
    _visual_box(_first_person_weapon_visual, Vector3(-0.96, -0.50, -2.18), Vector3(0.10, 0.10, 0.26), hazard, 4.0)
    _visual_box(_first_person_weapon_visual, Vector3(-0.64, -0.50, -2.18), Vector3(0.10, 0.10, 0.26), hazard, 4.0)

    _cockpit_visual.visible = first_person
    _first_person_weapon_visual.visible = first_person

    _missile_port_visual = Node3D.new()
    _missile_port_visual.name = "MissilePort"
    _first_person_camera.add_child(_missile_port_visual)
    _visual_box(_missile_port_visual, Vector3(-1.05, -0.34, -1.28), Vector3(1.18, 0.18, 0.78), armor_dark)
    _visual_box(_missile_port_visual, Vector3(-1.05, -0.58, -1.32), Vector3(1.18, 0.16, 0.72), armor_mid)
    for row in range(2):
        for column in range(4):
            var tube_x := -1.47 + float(column) * 0.28
            var tube_y := -0.34 + float(row) * 0.26
            _visual_box(_missile_port_visual, Vector3(tube_x, tube_y, -1.78), Vector3(0.18, 0.18, 0.52), Color(0.025, 0.05, 0.06))
            _visual_box(_missile_port_visual, Vector3(tube_x, tube_y, -2.07), Vector3(0.08, 0.08, 0.08), hazard, 4.0)
    _missile_port_visual.visible = false
    _build_muzzle_effects()
    _refresh_first_person_weapon_visuals()

func _build_muzzle_effects() -> void:
    _left_muzzle_flash = _create_muzzle_flash(Vector3(-0.80, -0.50, -2.35), Color(1.0, 0.28, 0.06))
    _right_muzzle_flash = _create_muzzle_flash(Vector3(0.82, -0.46, -2.35), Color(1.0, 0.76, 0.20))
    _left_muzzle_light = _create_muzzle_light(_left_muzzle_flash.position, Color(1.0, 0.20, 0.04))
    _right_muzzle_light = _create_muzzle_light(_right_muzzle_flash.position, Color(1.0, 0.66, 0.12))
    _left_muzzle_flash.visible = false
    _right_muzzle_flash.visible = false
    _left_muzzle_light.visible = false
    _right_muzzle_light.visible = false

func _create_muzzle_flash(position: Vector3, color: Color) -> MeshInstance3D:
    var flash := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.24
    mesh.height = 0.48
    flash.mesh = mesh
    flash.position = position
    flash.scale = Vector3(0.65, 0.65, 1.8)
    flash.material_override = _material(color, 5.0)
    _first_person_camera.add_child(flash)
    return flash

func _create_muzzle_light(position: Vector3, color: Color) -> OmniLight3D:
    var light := OmniLight3D.new()
    light.position = position
    light.light_color = color
    light.light_energy = 3.5
    light.omni_range = 4.5
    light.shadow_enabled = false
    _first_person_camera.add_child(light)
    return light

func _show_muzzle_flash(hand: StringName, color: Color, intensity: float) -> void:
    if SettingsManager.reduced_effects:
        intensity *= 0.55
    var flash := _left_muzzle_flash if hand == &"left" else _right_muzzle_flash
    var light := _left_muzzle_light if hand == &"left" else _right_muzzle_light
    flash.material_override = _material(color, 4.0 + intensity * 2.0)
    flash.scale = Vector3(0.55, 0.55, 1.2 + intensity * 0.65)
    flash.visible = true
    light.light_energy = 2.0 + intensity * 2.0
    light.visible = true
    if hand == &"left":
        _left_muzzle_timer = 0.055
    else:
        _right_muzzle_timer = 0.045

func _update_muzzle_effects(delta: float) -> void:
    _left_muzzle_timer = maxf(_left_muzzle_timer - delta, 0.0)
    _right_muzzle_timer = maxf(_right_muzzle_timer - delta, 0.0)
    _left_muzzle_flash.visible = _left_muzzle_timer > 0.0
    _right_muzzle_flash.visible = _right_muzzle_timer > 0.0
    _left_muzzle_light.visible = _left_muzzle_timer > 0.0
    _right_muzzle_light.visible = _right_muzzle_timer > 0.0

func _process(delta: float) -> void:
    _update_muzzle_effects(delta)
    _camera_recoil = move_toward(_camera_recoil, 0.0, delta * 0.65)
    _respawn_invulnerability_timer = maxf(_respawn_invulnerability_timer - delta, 0.0)
    _machinegun_cooldown = maxf(_machinegun_cooldown - delta, 0.0)
    _rocket_cooldown = maxf(_rocket_cooldown - delta, 0.0)
    _emp_cooldown = maxf(_emp_cooldown - delta, 0.0)
    if _reload_timer > 0.0:
        _reload_timer = maxf(_reload_timer - delta, 0.0)
        if is_zero_approx(_reload_timer):
            _finish_reload()

    if Input.is_action_just_pressed("weapon_machinegun") or Input.is_action_just_pressed("weapon_rocket"):
        _select_weapon(WeaponMode.DUAL_HANDS)
    elif Input.is_action_just_pressed("weapon_missile"):
        _select_weapon(WeaponMode.MISSILE_POD)

    _update_missile_lock()
    if Input.is_action_just_pressed("toggle_view"):
        toggle_view()
    if Input.is_action_just_pressed("reload"):
        _start_reload()
    if Input.is_action_just_pressed("emp_pulse"):
        _fire_emp_pulse()
    if current_weapon == WeaponMode.MISSILE_POD:
        if Input.is_action_just_pressed("fire_left_weapon"):
            _fire_guided_missile_salvo()
        if Input.is_action_just_pressed("fire_right_weapon"):
            _fire_direct_missile_salvo()
    else:
        if Input.is_action_just_pressed("fire_left_weapon"):
            _fire_left_hand_weapon()
        if Input.is_action_pressed("fire_right_weapon"):
            _fire_right_hand_weapon()

func _physics_process(delta: float) -> void:
    var forward_input := Input.get_axis("move_back", "move_forward")
    var strafe_input := Input.get_axis("move_left", "move_right")
    var local_direction := Vector3(strafe_input, 0.0, -forward_input)
    var move_direction := local_direction.rotated(Vector3.UP, yaw)
    if move_direction.length_squared() > 1.0:
        move_direction = move_direction.normalized()

    var sprint_requested := Input.is_action_pressed("boost") and move_direction.length_squared() > 0.0001
    var sprinting := _update_sprint(delta, sprint_requested)
    var speed := move_speed
    if sprinting:
        speed *= boost_multiplier
    var target_velocity := move_direction * speed
    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0
    move_and_slide()
    _update_movement_feedback(delta, move_direction, sprinting)

    _view_pivot.rotation = Vector3(pitch - _camera_recoil, yaw, 0.0)
    _body_visual.rotation.y = lerp_angle(_body_visual.rotation.y, yaw, minf(delta * 8.0, 1.0))
    stats_changed.emit()

func _update_movement_feedback(delta: float, move_direction: Vector3, sprinting: bool) -> void:
    var moving := move_direction.length_squared() > 0.0001 and get_speed_mps() > 0.3
    _movement_audio_timer = maxf(_movement_audio_timer - delta, 0.0)
    if moving and _movement_audio_timer <= 0.0:
        AudioManager.play_sound(&"sprint" if sprinting else &"servo", global_position, 1.0 if sprinting else 0.65)
        _movement_audio_timer = 0.22 if sprinting else 0.48

    _sprint_exhaust_timer = maxf(_sprint_exhaust_timer - delta, 0.0)
    if sprinting and _sprint_exhaust_timer <= 0.0 and game != null and game.has_method("spawn_sprint_exhaust"):
        game.call("spawn_sprint_exhaust", global_position, move_direction)
        _sprint_exhaust_timer = 0.08

func _update_sprint(delta: float, requested: bool) -> bool:
    sprint_active = false
    if sprint_overheated:
        sprint_recovery_timer = maxf(sprint_recovery_timer - delta, 0.0)
        if is_zero_approx(sprint_recovery_timer):
            sprint_overheated = false
            sprint_elapsed = 0.0
            _sprint_extended_announced = false
            announcement.emit("SPRINT // COOLED AND READY")
        return false

    if requested:
        sprint_elapsed = minf(sprint_elapsed + delta, sprint_max_duration)
        if sprint_elapsed >= sprint_safe_duration and not _sprint_extended_announced:
            _sprint_extended_announced = true
            announcement.emit("SPRINT // EXTENDED WINDOW // HEAT RISING")
        if sprint_elapsed >= sprint_max_duration:
            sprint_elapsed = sprint_max_duration
            sprint_overheated = true
            sprint_recovery_timer = sprint_recovery_seconds * sprint_overheat_recovery_multiplier
            announcement.emit("SPRINT // OVERHEATED // RECOVERY %02d S" % int(ceil(sprint_recovery_timer)))
            return false
        sprint_active = true
        return true

    if sprint_elapsed > 0.0:
        var recovery_rate := sprint_max_duration / maxf(sprint_recovery_seconds, 0.1)
        sprint_elapsed = move_toward(sprint_elapsed, 0.0, recovery_rate * delta)
        if is_zero_approx(sprint_elapsed):
            _sprint_extended_announced = false
    return false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity_x
        var vertical_sign := 1.0 if mouse_invert_y else -1.0
        pitch = clampf(pitch + event.relative.y * mouse_sensitivity_y * vertical_sign, -1.05, 0.72)
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_field_of_view_changed(value: float) -> void:
    if _first_person_camera != null:
        _first_person_camera.fov = value
    if _third_person_camera != null:
        _third_person_camera.fov = value

func _on_mouse_sensitivity_changed(value_x: float, value_y: float) -> void:
    mouse_sensitivity_x = value_x
    mouse_sensitivity_y = value_y

func _on_mouse_invert_y_changed(enabled: bool) -> void:
    mouse_invert_y = enabled

func toggle_view() -> void:
    first_person = not first_person
    _first_person_camera.current = first_person
    _third_person_camera.current = not first_person
    _body_visual.visible = not first_person
    _cockpit_visual.visible = first_person
    _refresh_first_person_weapon_visuals()
    view_mode_changed.emit(first_person)
    announcement.emit("CAMERA LINK // " + ("FIRST PERSON" if first_person else "THIRD PERSON"))

func _get_aim_ray() -> Dictionary:
    var camera: Camera3D = _first_person_camera if first_person else _third_person_camera
    var viewport_center := get_viewport().get_visible_rect().size * 0.5
    return {
        "origin": camera.project_ray_origin(viewport_center),
        "direction": camera.project_ray_normal(viewport_center)
    }

func _raycast(from: Vector3, to: Vector3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1
    query.exclude = [get_rid()]
    return get_world_3d().direct_space_state.intersect_ray(query)

func _find_damage_target(collider: Node) -> Node:
    var current := collider
    while current != null:
        if current.has_method("take_damage"):
            return current
        if current == self:
            break
        current = current.get_parent()
    return null

func notify_weapon_hit(target: Node, hit_position: Vector3) -> void:
    if target == null or not is_instance_valid(target):
        return
    var part_name := "ARMOR"
    var critical := false
    var destroyed := false
    if target.get("is_boss") == true:
        part_name = "BOSS CORE"
        var boss_health := float(target.get("health"))
        var boss_health_max := maxf(float(target.get("health_max")), 1.0)
        critical = boss_health / boss_health_max <= 0.25
    elif target.has_method("get_hit_part_id"):
        var part_id: StringName = target.call("get_hit_part_id", hit_position)
        var names: Dictionary = target.call("get_part_display_names") if target.has_method("get_part_display_names") else {}
        part_name = str(names.get(part_id, part_id))
        critical = part_id == &"upper_torso" or part_id == &"lower_torso"
        if target.has_method("get_part_health_snapshot"):
            var health_snapshot: Dictionary = target.call("get_part_health_snapshot")
            destroyed = is_zero_approx(float(health_snapshot.get(part_id, 1.0)))
    weapon_hit.emit(part_name, critical, destroyed)

func _fire_machinegun(hand: StringName = &"right") -> void:
    if _machinegun_cooldown > 0.0 or _reload_timer > 0.0:
        return
    if machinegun_ammo <= 0:
        _start_reload()
        return

    _machinegun_cooldown = machinegun_fire_interval
    machinegun_ammo -= 1
    _show_muzzle_flash(hand, Color(1.0, 0.76, 0.20), 0.65)
    _camera_recoil += 0.006
    AudioManager.play_sound(&"machinegun", global_position, 1.0)
    var aim := _get_aim_ray()
    var ray_origin: Vector3 = aim["origin"]
    var ray_direction: Vector3 = aim["direction"]
    var ray_end := ray_origin + ray_direction * 250.0
    var hit := _raycast(ray_origin, ray_end)
    var hit_position := ray_end
    if not hit.is_empty():
        hit_position = hit["position"]
        var target := _find_damage_target(hit.get("collider") as Node)
        if target != null:
            target.call("take_damage", machinegun_damage, hit_position)
            notify_weapon_hit(target, hit_position)
    if game != null and game.has_method("spawn_tracer"):
        game.call("spawn_tracer", ray_origin, hit_position, Color(1.0, 0.76, 0.20))
    stats_changed.emit()

func _fire_rocket(hand: StringName = &"left") -> void:
    if _rocket_cooldown > 0.0 or _reload_timer > 0.0 or rocket_ammo <= 0:
        if rocket_ammo <= 0:
            announcement.emit("ROCKET POD // EMPTY")
        return
    _rocket_cooldown = 0.85
    rocket_ammo -= 1
    _show_muzzle_flash(hand, Color(1.0, 0.24, 0.06), 1.2)
    _camera_recoil += 0.022
    AudioManager.play_sound(&"rocket", global_position, 1.0)
    var aim := _get_aim_ray()
    var ray_origin: Vector3 = aim["origin"]
    var ray_direction: Vector3 = aim["direction"]
    if game != null and game.has_method("spawn_player_rocket"):
        game.call("spawn_player_rocket", ray_origin + ray_direction * 1.2, ray_direction, self, rocket_damage, rocket_explosion_radius)
    stats_changed.emit()

func _fire_guided_missile_salvo() -> void:
    if not is_instance_valid(_missile_lock_target):
        announcement.emit("MISSILE PORT // NO LOCK // LEFT HAND DISABLED")
        return
    _launch_missile_salvo(_missile_lock_target, "LOCKED SALVO")

func _fire_direct_missile_salvo() -> void:
    _launch_missile_salvo(null, "AIM POINT SALVO")

func _launch_missile_salvo(lock_target: Node3D, fire_mode: String) -> void:
    if missile_salvo_count <= 0:
        announcement.emit("MISSILE PORT // EMPTY")
        return
    missile_salvo_count -= 1
    var aim := _get_aim_ray()
    var ray_origin: Vector3 = aim["origin"]
    var ray_direction: Vector3 = aim["direction"]
    if game != null and game.has_method("spawn_player_missile_salvo"):
        game.call("spawn_player_missile_salvo", ray_origin + ray_direction * 1.4, ray_direction, self, lock_target, missile_damage, missile_explosion_radius, missile_salvo_size)
    AudioManager.play_sound(&"missile", global_position, 1.0)
    announcement.emit("MISSILE PORT // %02dX %s" % [missile_salvo_size, fire_mode])
    stats_changed.emit()

func _fire_emp_pulse() -> void:
    if _emp_cooldown > 0.0:
        announcement.emit("EMP PULSE // RECHARGING %02d S" % int(ceil(_emp_cooldown)))
        return
    _emp_cooldown = 12.0
    if game != null and game.has_method("spawn_emp_pulse"):
        game.call("spawn_emp_pulse", global_position + Vector3(0.0, 1.0, 0.0), 13.0, 90.0)
    AudioManager.play_sound(&"emp", global_position, 1.2)
    announcement.emit("EMP PULSE // HOSTILES DISRUPTED")
    stats_changed.emit()

func _select_weapon(mode: int) -> void:
    current_weapon = mode as WeaponMode
    if current_weapon != WeaponMode.MISSILE_POD:
        _missile_lock_target = null
    _refresh_first_person_weapon_visuals()
    announcement.emit("WEAPON SELECTED // " + get_weapon_display_name())

func _refresh_first_person_weapon_visuals() -> void:
    if _first_person_weapon_visual != null:
        _first_person_weapon_visual.visible = first_person and current_weapon != WeaponMode.MISSILE_POD
        _first_person_weapon_visual.scale.x = -1.0 if UpgradeManager.weapon_group == &"support" else 1.0
    if _missile_port_visual != null:
        _missile_port_visual.visible = first_person and current_weapon == WeaponMode.MISSILE_POD

func _apply_upgrade_profile() -> void:
    if _base_health_max <= 0.0:
        return
    var armor_level := UpgradeManager.get_upgrade_level(&"armor")
    var mobility_level := UpgradeManager.get_upgrade_level(&"mobility")
    var machinegun_level := UpgradeManager.get_upgrade_level(&"machinegun")
    var rocket_level := UpgradeManager.get_upgrade_level(&"rocket")
    var missile_level := UpgradeManager.get_upgrade_level(&"missile")

    health_max = _base_health_max + float(armor_level * 100)
    move_speed = _base_move_speed + float(mobility_level) * 0.4
    boost_multiplier = _base_boost_multiplier
    machinegun_damage = _base_machinegun_damage + float(machinegun_level * 4)
    machinegun_fire_interval = maxf(_base_machinegun_fire_interval - float(machinegun_level) * 0.006, 0.045)
    rocket_damage = _base_rocket_damage + float(rocket_level * 15)
    rocket_explosion_radius = _base_rocket_explosion_radius + float(rocket_level) * 0.25
    missile_damage = _base_missile_damage + float(missile_level * 8)

    match UpgradeManager.mech_tuning:
        &"heavy":
            health_max += 100.0
            move_speed -= 1.0
        &"mobile":
            health_max -= 50.0
            move_speed += 1.2
            boost_multiplier += 0.12
    health = minf(health, health_max)
    _refresh_first_person_weapon_visuals()
    stats_changed.emit()

func _on_weapon_group_changed(_group_id: StringName) -> void:
    _refresh_first_person_weapon_visuals()
    announcement.emit("WEAPON GROUP // " + UpgradeManager.get_weapon_group_name())

func _on_mech_tuning_changed(_tuning_id: StringName) -> void:
    _apply_upgrade_profile()
    announcement.emit("MECH FRAME // " + UpgradeManager.get_mech_tuning_name())

func _update_missile_lock() -> void:
    if current_weapon != WeaponMode.MISSILE_POD:
        _missile_lock_target = null
        return

    var aim := _get_aim_ray()
    var ray_origin: Vector3 = aim["origin"]
    var ray_direction: Vector3 = aim["direction"]
    var lock_cosine := cos(deg_to_rad(MISSILE_LOCK_CONE_DEGREES))
    var best_score := INF
    var best_target: Node3D = null

    for candidate_variant in get_tree().get_nodes_in_group("enemy_mechs"):
        var candidate := candidate_variant as Node3D
        if candidate == null or not is_instance_valid(candidate):
            continue
        var target_position := candidate.global_position + Vector3(0.0, 2.2, 0.0)
        var distance := ray_origin.distance_to(target_position)
        if distance > MISSILE_LOCK_RANGE:
            continue
        var target_direction := ray_origin.direction_to(target_position)
        var alignment := ray_direction.dot(target_direction)
        if alignment < lock_cosine:
            continue
        var hit := _raycast(ray_origin, target_position)
        if hit.is_empty():
            continue
        var hit_target := _find_damage_target(hit.get("collider") as Node)
        if hit_target != candidate:
            continue
        var score := (1.0 - alignment) * 100.0 + distance * 0.01
        if score < best_score:
            best_score = score
            best_target = candidate
    if best_target != null:
        _missile_lock_target = best_target
    elif not _is_valid_missile_target(_missile_lock_target):
        _missile_lock_target = null

func _is_valid_missile_target(candidate: Node3D) -> bool:
    return candidate != null and is_instance_valid(candidate) and candidate.is_in_group("enemy_mechs")

func _start_reload() -> void:
    if _reload_timer > 0.0 or machinegun_ammo >= machinegun_magazine_size or machinegun_reserve <= 0:
        return
    _reload_timer = machinegun_reload_time
    announcement.emit("MACHINE GUN // RELOADING")

func _finish_reload() -> void:
    var needed := machinegun_magazine_size - machinegun_ammo
    var loaded := mini(needed, machinegun_reserve)
    machinegun_ammo += loaded
    machinegun_reserve -= loaded
    announcement.emit("MACHINE GUN // READY")
    stats_changed.emit()

func _fire_left_hand_weapon() -> void:
    if UpgradeManager.weapon_group == &"support":
        _fire_machinegun(&"left")
    else:
        _fire_rocket(&"left")

func _fire_right_hand_weapon() -> void:
    if UpgradeManager.weapon_group == &"support":
        _fire_rocket(&"right")
    else:
        _fire_machinegun(&"right")

func get_speed_mps() -> float:
    return Vector2(velocity.x, velocity.z).length()

func is_boosting() -> bool:
    return sprint_active and get_speed_mps() > 0.1

func get_sprint_status() -> String:
    if sprint_overheated:
        return "OVERHEATED // %02d S" % int(ceil(sprint_recovery_timer))
    if sprint_active:
        if sprint_elapsed < sprint_safe_duration:
            return "SPRINT // %02d/%02d S" % [int(ceil(sprint_elapsed)), int(sprint_safe_duration)]
        return "EXTENDED // %02d/%02d S" % [int(ceil(sprint_elapsed)), int(sprint_max_duration)]
    if sprint_elapsed > 0.0:
        var recovery_percent := int(round((1.0 - sprint_elapsed / sprint_max_duration) * 100.0))
        return "RECHARGE // %02d%%" % recovery_percent
    return "READY // SAFE 10 S"

func get_weapon_status() -> String:
    match current_weapon:
        WeaponMode.DUAL_HANDS:
            var machinegun_status := "RELOADING" if _reload_timer > 0.0 else "READY"
            if machinegun_ammo <= 0 and machinegun_reserve <= 0:
                machinegun_status = "EMPTY"
            var rocket_status := "READY" if _rocket_cooldown <= 0.0 else "COOLDOWN"
            if rocket_ammo <= 0:
                rocket_status = "EMPTY"
            if UpgradeManager.weapon_group == &"support":
                return "L MG %s // R ROCKET %s" % [machinegun_status, rocket_status]
            return "L ROCKET %s // R MG %s" % [rocket_status, machinegun_status]
        WeaponMode.MISSILE_POD:
            var missile_status := "READY" if missile_salvo_count > 0 else "EMPTY"
            return "%02dX MISSILE SALVO %02d // %s" % [missile_salvo_size, missile_salvo_count, missile_status]
    return "UNKNOWN"

func get_emp_status() -> String:
    if _emp_cooldown <= 0.0:
        return "READY"
    return "%02d S" % int(ceil(_emp_cooldown))

func get_weapon_display_name() -> String:
    match current_weapon:
        WeaponMode.DUAL_HANDS:
            return UpgradeManager.get_weapon_group_name()
        WeaponMode.MISSILE_POD:
            return "MISSILE PORT"
    return "UNKNOWN"

func is_missile_pod_selected() -> bool:
    return current_weapon == WeaponMode.MISSILE_POD

func get_missile_lock_ui() -> String:
    if current_weapon != WeaponMode.MISSILE_POD:
        return ""
    if is_instance_valid(_missile_lock_target):
        return "MISSILE LOCK // %s // %02dX HOMING" % [_missile_lock_target.name, missile_salvo_size]
    return "MISSILE LOCK // NO TARGET // AIM POINT FIRE"

func get_locked_enemy() -> Node3D:
    if is_instance_valid(_missile_lock_target):
        return _missile_lock_target
    return null

func get_locked_enemy_screen_position() -> Vector2:
    if current_weapon != WeaponMode.MISSILE_POD or not is_instance_valid(_missile_lock_target):
        return Vector2(-1.0, -1.0)
    var camera: Camera3D = _first_person_camera if first_person else _third_person_camera
    var target_position: Vector3 = _missile_lock_target.global_position + Vector3(0.0, 2.2, 0.0)
    if camera.is_position_behind(target_position):
        return Vector2(-1.0, -1.0)
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return Vector2(-1.0, -1.0)
    var screen_position: Vector2 = camera.unproject_position(target_position)
    return Vector2(screen_position.x / viewport_size.x, screen_position.y / viewport_size.y)

func get_damage_direction_screen(hit_position: Vector3) -> Vector2:
    if hit_position == Vector3.ZERO:
        return Vector2.UP
    var camera: Camera3D = _first_person_camera if first_person else _third_person_camera
    var local_hit := camera.to_local(hit_position)
    var direction := Vector2(local_hit.x, local_hit.z)
    if direction.length_squared() < 0.0001:
        return Vector2.UP
    return direction.normalized()

func repair_full() -> void:
    health = health_max
    announcement.emit("REPAIR BOT // ARMOR RESTORED")
    stats_changed.emit()

func take_damage(amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
    if _disabled or _respawn_invulnerability_timer > 0.0:
        return
    health = maxf(health - amount, 0.0)
    damage_taken.emit(amount, hit_position)
    if health <= 0.0:
        _disabled = true
        velocity = Vector3.ZERO
        player_defeated.emit()
        announcement.emit("COCKPIT FAILURE // MISSION INTERRUPTED")
    stats_changed.emit()

func restore_after_failure(position: Vector3) -> void:
    _disabled = false
    health = health_max
    machinegun_ammo = machinegun_magazine_size
    machinegun_reserve = machinegun_reserve_max
    rocket_ammo = rocket_magazine_size
    rocket_reserve = rocket_reserve_max
    missile_salvo_count = 4
    _reload_timer = 0.0
    _missile_lock_target = null
    global_position = position
    velocity = Vector3.ZERO
    sprint_elapsed = 0.0
    sprint_overheated = false
    sprint_recovery_timer = 0.0
    _respawn_invulnerability_timer = respawn_invulnerability_seconds
    _emp_cooldown = 0.0
    announcement.emit("COCKPIT RESET // INVULNERABLE %02d S" % int(ceil(respawn_invulnerability_seconds)))
    stats_changed.emit()

func restore_save_state(state: Dictionary) -> void:
    _disabled = false
    var saved_position = state.get("player_position", global_position)
    if saved_position is Vector3:
        global_position = saved_position
    health = clampf(float(state.get("player_health", health_max)), 0.0, health_max)
    machinegun_ammo = clampi(int(state.get("machinegun_ammo", machinegun_ammo)), 0, machinegun_magazine_size)
    machinegun_reserve = clampi(int(state.get("machinegun_reserve", machinegun_reserve)), 0, machinegun_reserve_max)
    rocket_ammo = clampi(int(state.get("rocket_ammo", rocket_ammo)), 0, rocket_magazine_size)
    rocket_reserve = clampi(int(state.get("rocket_reserve", rocket_reserve)), 0, rocket_reserve_max)
    missile_salvo_count = maxi(int(state.get("missile_salvo_count", missile_salvo_count)), 0)
    _emp_cooldown = maxf(float(state.get("emp_cooldown", 0.0)), 0.0)
    yaw = float(state.get("player_yaw", yaw))
    pitch = clampf(float(state.get("player_pitch", pitch)), -1.05, 0.72)
    var desired_first_person: bool = state.get("first_person", first_person) == true
    if first_person != desired_first_person:
        toggle_view()
    var saved_weapon := clampi(int(state.get("current_weapon", int(WeaponMode.DUAL_HANDS))), 0, 1)
    current_weapon = saved_weapon as WeaponMode
    _reload_timer = 0.0
    _missile_lock_target = null
    _respawn_invulnerability_timer = 0.0
    velocity = Vector3.ZERO
    _refresh_first_person_weapon_visuals()
    stats_changed.emit()
