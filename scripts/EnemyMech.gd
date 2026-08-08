extends CharacterBody3D
class_name EnemyMech

enum EnemyType {
    HEAVY,
    SCOUT,
    DRONE,
    SPIDER,
}

signal died(enemy: Node)
signal part_health_changed(part_id: StringName, current: float, maximum: float)
signal part_destroyed(part_id: StringName)

const PART_IDS: Array[StringName] = [
    &"left_arm",
    &"right_arm",
    &"upper_torso",
    &"lower_torso",
    &"left_leg",
    &"right_leg",
]
const PART_MAX_HEALTH: Dictionary = {
    &"left_arm": 70.0,
    &"right_arm": 70.0,
    &"upper_torso": 130.0,
    &"lower_torso": 130.0,
    &"left_leg": 90.0,
    &"right_leg": 90.0,
}
const PART_DISPLAY_NAMES: Dictionary = {
    &"left_arm": "LEFT ARM",
    &"right_arm": "RIGHT ARM",
    &"upper_torso": "UPPER TORSO",
    &"lower_torso": "LOWER TORSO",
    &"left_leg": "LEFT LEG",
    &"right_leg": "RIGHT LEG",
}

@export var move_speed: float = 3.2
@export var health_max: float = 580.0
@export var attack_range: float = 48.0
@export var attack_damage: float = 18.0
@export var attack_interval: float = 1.35
@export var enemy_type: EnemyType = EnemyType.HEAVY

var health: float = health_max
var target: Node3D
var game: Node3D
var _attack_timer: float = 0.7
var _dead: bool = false
var _visual: Node3D
var _base_move_speed: float
var part_health: Dictionary = {}
var part_max_health: Dictionary = {}
var _part_visuals: Dictionary = {}
var _part_meshes: Dictionary = {}
var _part_damage_markers: Dictionary = {}
var _part_health_multiplier: float = 1.0
var _base_attack_damage: float
var _is_flying: bool = false
var _flight_height: float = 6.5
var _attack_origin_height: float = 3.15
var _visual_scale: float = 1.0
var _hover_phase: float = 0.0
var _stagger_timer: float = 0.0
var _stagger_duration: float = 0.0
var _ai_time: float = 0.0
var _strafe_sign: float = 1.0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.45
    add_to_group("enemy_mechs")
    _configure_enemy_type()
    _initialize_part_health()
    _base_move_speed = move_speed
    _base_attack_damage = attack_damage
    _build_collision()
    _build_visual()
    _refresh_all_part_damage_visuals()

func setup(game_instance: Node3D, target_instance: Node3D) -> void:
    game = game_instance
    target = target_instance
    _attack_timer = randf_range(0.45, 1.25)
    _strafe_sign = -1.0 if randf() < 0.5 else 1.0

func get_save_state() -> Dictionary:
    var saved_parts: Dictionary = {}
    for part_id in PART_IDS:
        saved_parts[String(part_id)] = float(part_health.get(part_id, 0.0))
    return {
        "enemy_type": int(enemy_type),
        "position": global_position,
        "part_health": saved_parts,
        "attack_timer": _attack_timer,
        "stagger_timer": _stagger_timer,
    }

func restore_save_state(state: Dictionary) -> void:
    _dead = false
    var saved_position = state.get("position", global_position)
    if saved_position is Vector3:
        global_position = saved_position
    var saved_parts = state.get("part_health", {})
    for part_id in PART_IDS:
        var maximum := float(part_max_health.get(part_id, 0.0))
        part_health[part_id] = clampf(float(saved_parts.get(String(part_id), maximum)), 0.0, maximum)
    health = _get_total_part_health()
    health_max = 0.0
    for part_id in PART_IDS:
        health_max += float(part_max_health.get(part_id, 0.0))
    _attack_timer = maxf(float(state.get("attack_timer", _attack_timer)), 0.0)
    _stagger_timer = maxf(float(state.get("stagger_timer", 0.0)), 0.0)
    _stagger_duration = _stagger_timer
    velocity = Vector3.ZERO
    _refresh_all_part_damage_visuals()

func apply_difficulty(health_scale: float, damage_scale: float) -> void:
    for part_id in PART_IDS:
        var previous_maximum := maxf(float(part_max_health.get(part_id, 1.0)), 0.01)
        var health_ratio := clampf(float(part_health.get(part_id, 0.0)) / previous_maximum, 0.0, 1.0)
        var scaled_maximum := float(PART_MAX_HEALTH[part_id]) * _part_health_multiplier * health_scale
        part_max_health[part_id] = scaled_maximum
        part_health[part_id] = scaled_maximum * health_ratio
    health_max = 0.0
    for part_id in PART_IDS:
        health_max += float(part_max_health[part_id])
    health = _get_total_part_health()
    attack_damage = _base_attack_damage * damage_scale
    _refresh_all_part_damage_visuals()

func _configure_enemy_type() -> void:
    match enemy_type:
        EnemyType.SCOUT:
            move_speed = 7.0
            attack_damage = 12.0
            attack_interval = 0.95
            _part_health_multiplier = 0.55
            _visual_scale = 0.68
            _attack_origin_height = 2.3
        EnemyType.DRONE:
            move_speed = 5.6
            attack_damage = 11.0
            attack_interval = 1.0
            _part_health_multiplier = 0.50
            _is_flying = true
            _attack_origin_height = 0.65
        EnemyType.SPIDER:
            move_speed = 4.5
            attack_damage = 16.0
            attack_interval = 1.2
            _part_health_multiplier = 0.86
            _visual_scale = 0.85
            _attack_origin_height = 2.3
        _:
            move_speed = 3.2
            health_max = 580.0
            attack_damage = 18.0
            attack_interval = 1.35
    _base_move_speed = move_speed

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    if _is_flying:
        var sphere := SphereShape3D.new()
        sphere.radius = 0.85
        collision.shape = sphere
        collision.position = Vector3(0.0, 0.75, 0.0)
    else:
        var capsule := CapsuleShape3D.new()
        capsule.radius = 1.2 * _visual_scale
        capsule.height = 4.6 * _visual_scale
        collision.shape = capsule
        collision.position = Vector3(0.0, 2.3 * _visual_scale, 0.0)
    add_child(collision)

func _material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.62
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_energy
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return material

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    mesh_instance.set_meta("base_color", color)
    parent.add_child(mesh_instance)
    return mesh_instance

func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.name = "EnemyVisual"
    add_child(_visual)
    match enemy_type:
        EnemyType.SCOUT:
            _build_scout_visual()
        EnemyType.DRONE:
            _build_drone_visual()
        EnemyType.SPIDER:
            _build_spider_visual()
        _:
            _build_heavy_visual()
    _build_damage_markers()
    _visual.scale = Vector3.ONE * _visual_scale

func _build_heavy_visual() -> void:
    var armor_dark := Color(0.12, 0.08, 0.09)
    var armor_mid := Color(0.42, 0.14, 0.13)
    var armor_light := Color(0.68, 0.24, 0.17)
    var warning := Color(1.0, 0.12, 0.05)
    _part_box(&"lower_torso", Vector3(0.0, 2.35, 0.0), Vector3(2.3, 1.7, 1.55), armor_mid)
    _part_box(&"upper_torso", Vector3(0.0, 3.45, 0.0), Vector3(2.3, 1.0, 1.55), armor_mid)
    _part_box(&"upper_torso", Vector3(0.0, 3.25, -0.83), Vector3(1.7, 0.58, 0.08), warning, 2.0)
    _part_box(&"upper_torso", Vector3(0.0, 4.2, 0.0), Vector3(1.5, 1.15, 1.25), armor_dark)
    _part_box(&"upper_torso", Vector3(0.0, 4.25, -0.67), Vector3(0.92, 0.25, 0.08), warning, 3.5)
    _part_box(&"left_arm", Vector3(-1.42, 3.45, 0.0), Vector3(0.55, 1.45, 0.85), armor_dark)
    _part_box(&"right_arm", Vector3(1.42, 3.45, 0.0), Vector3(0.55, 1.45, 0.85), armor_dark)
    _part_box(&"left_arm", Vector3(-1.48, 2.65, -0.75), Vector3(0.62, 0.52, 1.75), armor_light)
    _part_box(&"right_arm", Vector3(1.48, 2.65, -0.75), Vector3(0.62, 0.52, 1.75), armor_light)
    _part_box(&"left_leg", Vector3(-0.68, 1.18, 0.0), Vector3(0.78, 2.35, 1.0), armor_mid)
    _part_box(&"right_leg", Vector3(0.68, 1.18, 0.0), Vector3(0.78, 2.35, 1.0), armor_mid)
    _part_box(&"left_leg", Vector3(-0.68, 0.15, -0.3), Vector3(0.96, 0.3, 1.55), armor_dark)
    _part_box(&"right_leg", Vector3(0.68, 0.15, -0.3), Vector3(0.96, 0.3, 1.55), armor_dark)
    _part_box(&"right_arm", Vector3(1.5, 3.0, -2.25), Vector3(0.42, 0.42, 2.45), Color(0.08, 0.06, 0.07))
    _part_box(&"right_arm", Vector3(1.5, 3.0, -3.58), Vector3(0.18, 0.18, 0.32), warning, 3.0)

func _build_scout_visual() -> void:
    var armor_dark := Color(0.025, 0.12, 0.16)
    var armor_mid := Color(0.08, 0.34, 0.40)
    var armor_light := Color(0.18, 0.70, 0.72)
    var sensor := Color(0.50, 0.96, 0.92)
    var warning := Color(1.0, 0.70, 0.10)
    var chest := _part_box(&"lower_torso", Vector3(0.0, 1.78, 0.0), Vector3(1.35, 1.0, 1.20), armor_mid)
    chest.rotation_degrees.x = -8.0
    _part_box(&"upper_torso", Vector3(0.0, 2.62, -0.04), Vector3(1.18, 0.72, 1.08), armor_light)
    _part_box(&"upper_torso", Vector3(0.0, 2.78, -0.62), Vector3(0.92, 0.20, 0.08), sensor, 3.8)
    _part_box(&"upper_torso", Vector3(0.0, 3.30, -0.10), Vector3(0.62, 0.42, 0.70), armor_dark)
    _part_cylinder(&"upper_torso", Vector3(0.0, 3.66, -0.18), 0.23, 0.48, sensor, 4.0)
    _part_box(&"upper_torso", Vector3(-0.78, 2.70, 0.10), Vector3(0.12, 0.70, 0.82), armor_light, 1.0)
    _part_box(&"upper_torso", Vector3(0.78, 2.70, 0.10), Vector3(0.12, 0.70, 0.82), armor_light, 1.0)
    _part_box(&"left_arm", Vector3(-0.93, 2.48, -0.12), Vector3(0.38, 1.02, 0.58), armor_dark)
    _part_box(&"right_arm", Vector3(0.93, 2.48, -0.12), Vector3(0.38, 1.02, 0.58), armor_dark)
    _part_box(&"left_arm", Vector3(-1.02, 2.08, -0.72), Vector3(0.42, 0.34, 1.18), armor_light)
    _part_box(&"right_arm", Vector3(1.02, 2.08, -0.72), Vector3(0.42, 0.34, 1.18), armor_light)
    _part_box(&"right_arm", Vector3(1.12, 2.40, -1.58), Vector3(0.30, 0.30, 1.55), armor_dark)
    _part_box(&"right_arm", Vector3(1.12, 2.40, -2.42), Vector3(0.14, 0.14, 0.24), warning, 4.0)
    var left_leg := _part_box(&"left_leg", Vector3(-0.48, 1.02, 0.12), Vector3(0.42, 1.90, 0.62), armor_mid)
    left_leg.rotation_degrees.z = -16.0
    var right_leg := _part_box(&"right_leg", Vector3(0.48, 1.02, 0.12), Vector3(0.42, 1.90, 0.62), armor_mid)
    right_leg.rotation_degrees.z = 16.0
    _part_box(&"left_leg", Vector3(-0.70, 0.14, -0.62), Vector3(0.58, 0.28, 1.35), armor_dark)
    _part_box(&"right_leg", Vector3(0.70, 0.14, -0.62), Vector3(0.58, 0.28, 1.35), armor_dark)
    _part_box(&"left_leg", Vector3(-0.70, 0.18, -1.30), Vector3(0.20, 0.12, 0.18), warning, 3.5)
    _part_box(&"right_leg", Vector3(0.70, 0.18, -1.30), Vector3(0.20, 0.12, 0.18), warning, 3.5)

func _build_spider_visual() -> void:
    var armor_dark := Color(0.08, 0.045, 0.16)
    var armor_mid := Color(0.24, 0.10, 0.34)
    var armor_light := Color(0.54, 0.18, 0.58)
    var reactor := Color(0.95, 0.32, 0.86)
    var warning := Color(1.0, 0.56, 0.12)
    _part_box(&"lower_torso", Vector3(0.0, 0.98, 0.08), Vector3(3.05, 0.92, 2.35), armor_mid)
    _part_box(&"lower_torso", Vector3(0.0, 1.15, -1.20), Vector3(2.20, 0.30, 0.12), warning, 2.5)
    _part_box(&"upper_torso", Vector3(0.0, 1.72, -0.08), Vector3(2.35, 0.78, 1.82), armor_light)
    _part_box(&"upper_torso", Vector3(0.0, 2.24, -0.22), Vector3(1.32, 0.62, 1.18), armor_dark)
    _part_box(&"upper_torso", Vector3(0.0, 2.26, -0.84), Vector3(0.86, 0.20, 0.08), reactor, 4.0)
    _part_cylinder(&"upper_torso", Vector3(0.0, 2.62, -0.26), 0.34, 0.28, warning, 3.5)
    _part_box(&"left_arm", Vector3(-1.38, 1.68, -0.98), Vector3(0.54, 0.58, 1.32), armor_dark)
    _part_box(&"right_arm", Vector3(1.38, 1.68, -0.98), Vector3(0.54, 0.58, 1.32), armor_dark)
    _part_box(&"left_arm", Vector3(-1.42, 1.60, -1.92), Vector3(0.42, 0.42, 1.25), armor_light)
    _part_box(&"right_arm", Vector3(1.42, 1.60, -1.92), Vector3(0.42, 0.42, 1.25), armor_light)
    _part_box(&"left_arm", Vector3(-1.42, 1.60, -2.62), Vector3(0.18, 0.18, 0.22), warning, 4.0)
    _part_box(&"right_arm", Vector3(1.42, 1.60, -2.62), Vector3(0.18, 0.18, 0.22), warning, 4.0)
    _build_spider_legs()

func _build_drone_visual() -> void:
    var armor_dark := Color(0.08, 0.12, 0.16)
    var armor_mid := Color(0.18, 0.32, 0.40)
    var armor_light := Color(0.28, 0.68, 0.76)
    var warning := Color(1.0, 0.24, 0.06)
    _part_box(&"lower_torso", Vector3(0.0, 0.30, 0.0), Vector3(1.55, 0.55, 1.20), armor_mid)
    _part_box(&"upper_torso", Vector3(0.0, 0.82, 0.0), Vector3(1.35, 0.55, 1.05), armor_dark)
    _part_box(&"upper_torso", Vector3(0.0, 0.82, -0.58), Vector3(0.72, 0.20, 0.08), armor_light, 2.8)
    _part_box(&"left_arm", Vector3(-0.98, 0.68, 0.0), Vector3(0.25, 0.24, 0.88), armor_light)
    _part_box(&"right_arm", Vector3(0.98, 0.68, 0.0), Vector3(0.25, 0.24, 0.88), armor_light)
    _part_box(&"left_leg", Vector3(-0.54, 0.02, 0.0), Vector3(0.30, 0.18, 0.70), armor_dark)
    _part_box(&"right_leg", Vector3(0.54, 0.02, 0.0), Vector3(0.30, 0.18, 0.70), armor_dark)
    _part_box(&"left_leg", Vector3(-0.48, -0.15, 0.35), Vector3(0.18, 0.18, 0.32), warning, 3.5)
    _part_box(&"right_leg", Vector3(0.48, -0.15, 0.35), Vector3(0.18, 0.18, 0.32), warning, 3.5)
    for side in [-1.0, 1.0]:
        _part_box(&"left_arm" if side < 0.0 else &"right_arm", Vector3(side * 0.76, 0.22, 0.0), Vector3(0.14, 0.10, 1.35), armor_dark)

func _build_spider_legs() -> void:
    var leg_color := Color(0.12, 0.055, 0.19)
    var joint_color := Color(0.92, 0.24, 0.66)
    for leg_index in 4:
        var z_offset := -1.05 + float(leg_index) * 0.70
        for side in [-1.0, 1.0]:
            var part_id: StringName = &"left_leg" if side < 0.0 else &"right_leg"
            var hip_position := Vector3(side * (0.78 + float(leg_index) * 0.08), 1.45 - float(leg_index) * 0.10, z_offset)
            var foot_position := Vector3(side * (1.45 + float(leg_index) * 0.12), 0.62, z_offset + side * 0.32)
            var upper_leg := _part_box(part_id, hip_position, Vector3(0.28, 0.28, 1.05), leg_color)
            upper_leg.rotation_degrees.y = side * 22.0
            _part_cylinder(part_id, hip_position + Vector3(0.0, -0.18, 0.0), 0.17, 0.22, joint_color, 2.8)
            var lower_leg := _part_box(part_id, foot_position, Vector3(0.24, 0.24, 1.15), leg_color)
            lower_leg.rotation_degrees.y = -side * 28.0
            _part_box(part_id, foot_position + Vector3(0.0, -0.12, -0.24), Vector3(0.34, 0.16, 0.36), joint_color, 2.0)

func _part_box(part_id: StringName, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
    var part_visual := _part_visuals.get(part_id) as Node3D
    if part_visual == null:
        part_visual = Node3D.new()
        part_visual.name = String(PART_DISPLAY_NAMES.get(part_id, part_id))
        _visual.add_child(part_visual)
        _part_visuals[part_id] = part_visual
    var mesh_instance := _box(part_visual, position, size, color, emission_energy)
    var meshes: Array = _part_meshes.get(part_id, [])
    meshes.append(mesh_instance)
    _part_meshes[part_id] = meshes
    return mesh_instance

func _part_cylinder(part_id: StringName, position: Vector3, radius: float, height: float, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
    var part_visual := _part_visuals.get(part_id) as Node3D
    if part_visual == null:
        part_visual = Node3D.new()
        part_visual.name = String(PART_DISPLAY_NAMES.get(part_id, part_id))
        _visual.add_child(part_visual)
        _part_visuals[part_id] = part_visual
    var mesh_instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    mesh_instance.set_meta("base_color", color)
    part_visual.add_child(mesh_instance)
    var meshes: Array = _part_meshes.get(part_id, [])
    meshes.append(mesh_instance)
    _part_meshes[part_id] = meshes
    return mesh_instance

func _build_damage_markers() -> void:
    var marker_data: Dictionary
    if enemy_type == EnemyType.DRONE:
        marker_data = {
            &"left_arm": Vector3(-0.98, 0.68, -0.48),
            &"right_arm": Vector3(0.98, 0.68, -0.48),
            &"upper_torso": Vector3(0.0, 0.82, -0.60),
            &"lower_torso": Vector3(0.0, 0.30, -0.66),
            &"left_leg": Vector3(-0.54, 0.02, -0.38),
            &"right_leg": Vector3(0.54, 0.02, -0.38),
        }
    elif enemy_type == EnemyType.SCOUT:
        marker_data = {
            &"left_arm": Vector3(-1.02, 2.08, -0.74),
            &"right_arm": Vector3(1.02, 2.08, -0.74),
            &"upper_torso": Vector3(0.0, 2.78, -0.66),
            &"lower_torso": Vector3(0.0, 1.78, -0.64),
            &"left_leg": Vector3(-0.48, 1.04, -0.50),
            &"right_leg": Vector3(0.48, 1.04, -0.50),
        }
    elif enemy_type == EnemyType.SPIDER:
        marker_data = {
            &"left_arm": Vector3(-1.42, 1.60, -1.90),
            &"right_arm": Vector3(1.42, 1.60, -1.90),
            &"upper_torso": Vector3(0.0, 2.20, -0.82),
            &"lower_torso": Vector3(0.0, 1.12, -1.16),
            &"left_leg": Vector3(-1.45, 0.66, -0.72),
            &"right_leg": Vector3(1.45, 0.66, -0.72),
        }
    else:
        marker_data = {
            &"left_arm": Vector3(-1.50, 3.05, -0.82),
            &"right_arm": Vector3(1.50, 3.05, -0.82),
            &"upper_torso": Vector3(0.0, 3.52, -0.82),
            &"lower_torso": Vector3(0.0, 2.32, -0.80),
            &"left_leg": Vector3(-0.68, 1.12, -0.54),
            &"right_leg": Vector3(0.68, 1.12, -0.54),
        }
    for part_id in PART_IDS:
        var marker_root := Node3D.new()
        marker_root.name = "DamageDetail"
        marker_root.position = marker_data[part_id]
        _visual.add_child(marker_root)
        var exposed_color := Color(1.0, 0.12, 0.025)
        var conduit_color := Color(1.0, 0.62, 0.08)
        _box(marker_root, Vector3.ZERO, Vector3(0.26, 0.12, 0.08), exposed_color, 2.0)
        _box(marker_root, Vector3(-0.12, 0.10, 0.015), Vector3(0.045, 0.30, 0.045), conduit_color, 3.0)
        _box(marker_root, Vector3(0.08, -0.10, 0.02), Vector3(0.045, 0.24, 0.045), conduit_color, 3.0)
        marker_root.visible = false
        _part_damage_markers[part_id] = marker_root

func _update_part_damage_visual(part_id: StringName) -> void:
    var maximum := float(part_max_health.get(part_id, 1.0))
    var current := float(part_health.get(part_id, 0.0))
    var health_ratio := clampf(current / maxf(maximum, 0.01), 0.0, 1.0)
    var damage_amount := 1.0 - health_ratio
    var damage_color := Color(1.0, 0.10, 0.025)
    var meshes: Array = _part_meshes.get(part_id, [])
    for mesh_instance_variant in meshes:
        var mesh_instance := mesh_instance_variant as MeshInstance3D
        if mesh_instance == null:
            continue
        var material := mesh_instance.material_override as StandardMaterial3D
        if material == null:
            continue
        var base_color: Color = mesh_instance.get_meta("base_color", material.albedo_color)
        material.albedo_color = base_color.lerp(damage_color, damage_amount * 0.72)
        if damage_amount > 0.18:
            material.emission_enabled = true
            material.emission = damage_color
            material.emission_energy_multiplier = 0.25 + damage_amount * 2.2
    var marker := _part_damage_markers.get(part_id) as Node3D
    if marker != null:
        marker.visible = current > 0.0 and health_ratio < 0.72
        marker.scale = Vector3.ONE * (0.8 + damage_amount * 0.65)

func _refresh_all_part_damage_visuals() -> void:
    for part_id in PART_IDS:
        _update_part_damage_visual(part_id)

func _initialize_part_health() -> void:
    for part_id in PART_IDS:
        part_max_health[part_id] = float(PART_MAX_HEALTH[part_id]) * _part_health_multiplier
        part_health[part_id] = part_max_health[part_id]
    health = _get_total_part_health()
    health_max = health

func _get_total_part_health() -> float:
    var total := 0.0
    for part_id in PART_IDS:
        total += float(part_health.get(part_id, 0.0))
    return total

func _physics_process(delta: float) -> void:
    if _dead or not is_instance_valid(target):
        return
    if _stagger_timer > 0.0:
        _stagger_timer = maxf(_stagger_timer - delta, 0.0)
        velocity.x = move_toward(velocity.x, 0.0, 26.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 26.0 * delta)
        if not _is_flying:
            if not is_on_floor():
                velocity.y -= 18.0 * delta
            elif velocity.y < 0.0:
                velocity.y = 0.0
        move_and_slide()
        _visual.rotation.z = sin((_stagger_duration - _stagger_timer) * 34.0) * 0.12 * (_stagger_timer / maxf(_stagger_duration, 0.01))
        return
    _visual.rotation.z = move_toward(_visual.rotation.z, 0.0, delta * 3.0)
    _ai_time += delta
    if _is_flying:
        _physics_process_flying(delta)
        return
    var chase_position := target.global_position
    if game != null and game.has_method("get_enemy_target_position"):
        chase_position = game.call("get_enemy_target_position")
    var target_position := chase_position + Vector3(0.0, 2.4, 0.0)
    var to_target := target_position - (global_position + Vector3(0.0, 2.3, 0.0))
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)
    var distance := horizontal.length()
    var direction := horizontal.normalized() if distance > 0.01 else Vector3.ZERO
    if enemy_type == EnemyType.SCOUT and distance < 30.0:
        var scout_side := Vector3(-direction.z, 0.0, direction.x) * _strafe_sign
        target_position += scout_side * (5.0 + sin(_ai_time * 2.2) * 3.0)
        horizontal = Vector3(target_position.x - global_position.x, 0.0, target_position.z - global_position.z)
        direction = horizontal.normalized()
    elif enemy_type == EnemyType.SPIDER and distance < 18.0:
        var spider_side := Vector3(-direction.z, 0.0, direction.x) * _strafe_sign
        target_position += spider_side * 7.0
        horizontal = Vector3(target_position.x - global_position.x, 0.0, target_position.z - global_position.z)
        direction = horizontal.normalized()
    direction = _steer_around_obstacle(target_position, direction)

    var current_move_speed := _get_current_move_speed()
    if distance > 15.0:
        velocity.x = move_toward(velocity.x, direction.x * current_move_speed, 10.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * current_move_speed, 10.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 13.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 13.0 * delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0
    move_and_slide()

    if horizontal.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 6.0, 1.0))
    _attack_timer -= delta
    if _attack_timer <= 0.0 and distance <= attack_range:
        _fire_at_target(target_position)
        _attack_timer = attack_interval + randf_range(-0.18, 0.3)

func _physics_process_flying(delta: float) -> void:
    var chase_position := target.global_position
    if game != null and game.has_method("get_enemy_target_position"):
        chase_position = game.call("get_enemy_target_position")
    var target_position := chase_position + Vector3(0.0, 2.4, 0.0)
    var to_target := target_position - global_position
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)
    var distance := to_target.length()
    var direction := horizontal.normalized() if horizontal.length_squared() > 0.01 else Vector3.ZERO
    var desired_height := chase_position.y + _flight_height
    var vertical_velocity := clampf((desired_height - global_position.y) * 2.5, -move_speed, move_speed)
    var desired_velocity := Vector3(direction.x * move_speed, vertical_velocity, direction.z * move_speed)
    velocity = velocity.move_toward(desired_velocity, 12.0 * delta)
    move_and_slide()
    _hover_phase += delta * 3.0
    _visual.position.y = sin(_hover_phase) * 0.14

    if horizontal.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 6.0, 1.0))
    _attack_timer -= delta
    if _attack_timer <= 0.0 and distance <= attack_range:
        _fire_at_target(target_position)
        _attack_timer = attack_interval + randf_range(-0.18, 0.3)

func _steer_around_obstacle(target_position: Vector3, desired_direction: Vector3) -> Vector3:
    if desired_direction.length_squared() < 0.001:
        return desired_direction
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0.0, 1.2, 0.0), target_position)
    query.collision_mask = 1
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return desired_direction
    var side := Vector3(-desired_direction.z, 0.0, desired_direction.x) * _strafe_sign
    return (desired_direction * 0.35 + side * 0.65).normalized()

func _fire_at_target(target_position: Vector3) -> void:
    var origin := global_position + global_transform.basis * Vector3(0.0, _attack_origin_height, -0.8)
    var direction := origin.direction_to(target_position)
    var ray_end := origin + direction * attack_range
    var query := PhysicsRayQueryParameters3D.create(origin, ray_end)
    query.collision_mask = 1
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    var hit_position := ray_end
    if not hit.is_empty():
        hit_position = hit["position"]
        var collider := hit.get("collider") as Node
        var current := collider
        while current != null:
            if current == target:
                var coordinated_damage := attack_damage
                if game != null and game.has_method("get_enemy_coordination_bonus"):
                    coordinated_damage *= 1.0 + float(game.call("get_enemy_coordination_bonus", self))
                target.call("take_damage", coordinated_damage, hit_position)
                break
            current = current.get_parent()
    if game != null and game.has_method("spawn_tracer"):
        game.call("spawn_tracer", origin, hit_position, Color(1.0, 0.16, 0.08))
    AudioManager.play_sound(&"enemy_fire", global_position, 1.0)

func take_damage(amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
    if _dead:
        return
    var part_id := _get_hit_part(hit_position)
    var current_part_health := float(part_health.get(part_id, 0.0))
    var maximum_part_health := float(part_max_health.get(part_id, 0.0))
    var new_part_health := maxf(current_part_health - amount, 0.0)
    part_health[part_id] = new_part_health
    health = _get_total_part_health()
    _update_part_damage_visual(part_id)
    part_health_changed.emit(part_id, new_part_health, maximum_part_health)
    if current_part_health > 0.0 and is_zero_approx(new_part_health):
        _mark_part_destroyed(part_id)
        part_destroyed.emit(part_id)
        _start_stagger(0.42)
    elif amount >= 24.0:
        _start_stagger(0.24)
    if game != null and game.has_method("spawn_hit_spark"):
        game.call("spawn_hit_spark", hit_position)
    AudioManager.play_sound(&"hit", hit_position, 0.8)
    if is_zero_approx(float(part_health.get(&"upper_torso", 0.0))) and is_zero_approx(float(part_health.get(&"lower_torso", 0.0))):
        _destroy_mech()

func _get_hit_part(hit_position: Vector3) -> StringName:
    if hit_position == Vector3.ZERO:
        return &"lower_torso"
    var local_hit := to_local(hit_position)
    if enemy_type == EnemyType.DRONE:
        if local_hit.y <= 0.20:
            return &"left_leg" if local_hit.x < 0.0 else &"right_leg"
        if absf(local_hit.x) >= 0.72:
            return &"left_arm" if local_hit.x < 0.0 else &"right_arm"
        if local_hit.y >= 0.62:
            return &"upper_torso"
        return &"lower_torso"
    if enemy_type == EnemyType.SCOUT:
        if local_hit.y <= 0.45:
            return &"left_leg" if local_hit.x < 0.0 else &"right_leg"
        if absf(local_hit.x) >= 0.72:
            return &"left_arm" if local_hit.x < 0.0 else &"right_arm"
        if local_hit.y >= 2.35:
            return &"upper_torso"
        return &"lower_torso"
    if enemy_type == EnemyType.SPIDER:
        if local_hit.y <= 0.72 and absf(local_hit.x) >= 0.75:
            return &"left_leg" if local_hit.x < 0.0 else &"right_leg"
        if absf(local_hit.x) >= 1.05 and local_hit.y < 2.15:
            return &"left_arm" if local_hit.x < 0.0 else &"right_arm"
        if local_hit.y >= 1.82:
            return &"upper_torso"
        return &"lower_torso"
    if local_hit.y <= 2.25:
        return &"left_leg" if local_hit.x < 0.0 else &"right_leg"
    if absf(local_hit.x) >= 1.0:
        return &"left_arm" if local_hit.x < 0.0 else &"right_arm"
    if local_hit.y >= 3.25:
        return &"upper_torso"
    return &"lower_torso"

func _start_stagger(duration: float) -> void:
    _stagger_duration = maxf(_stagger_duration, duration)
    _stagger_timer = maxf(_stagger_timer, duration)

func apply_emp(duration: float = 1.8) -> void:
    if _dead:
        return
    _start_stagger(duration)

func get_hit_part_id(hit_position: Vector3) -> StringName:
    return _get_hit_part(hit_position)

func _get_current_move_speed() -> float:
    if _is_flying:
        return _base_move_speed
    var left_leg_damaged := float(part_health.get(&"left_leg", part_max_health[&"left_leg"])) < float(part_max_health[&"left_leg"])
    var right_leg_damaged := float(part_health.get(&"right_leg", part_max_health[&"right_leg"])) < float(part_max_health[&"right_leg"])
    if left_leg_damaged or right_leg_damaged:
        return _base_move_speed * 0.4
    return _base_move_speed

func keep_out_of_hangar(safe_center: Vector3, safe_radius: float) -> void:
    if _dead:
        return
    var offset := Vector3(global_position.x - safe_center.x, 0.0, global_position.z - safe_center.z)
    if offset.length() >= safe_radius:
        return
    if offset.length_squared() < 0.001:
        offset = Vector3(0.0, 0.0, -1.0)
    global_position = safe_center + offset.normalized() * safe_radius
    velocity.x = 0.0
    velocity.z = 0.0

func _mark_part_destroyed(part_id: StringName) -> void:
    var part_visual := _part_visuals.get(part_id) as Node3D
    if part_visual != null:
        part_visual.visible = false
    var damage_marker := _part_damage_markers.get(part_id) as Node3D
    if damage_marker != null:
        damage_marker.visible = false

func _destroy_mech() -> void:
    if _dead:
        return
    _dead = true
    died.emit(self)
    if game != null and game.has_method("spawn_explosion"):
        game.call("spawn_explosion", global_position + Vector3(0.0, 2.5, 0.0), 3.2, Color(1.0, 0.22, 0.06))
    AudioManager.play_sound(&"explosion", global_position, 1.0)
    queue_free()

func get_part_health_snapshot() -> Dictionary:
    return part_health.duplicate()

func get_part_max_health_snapshot() -> Dictionary:
    return part_max_health.duplicate()

func get_part_display_names() -> Dictionary:
    return PART_DISPLAY_NAMES.duplicate()

func get_enemy_type_name() -> String:
    match enemy_type:
        EnemyType.SCOUT:
            return "SCOUT MECH"
        EnemyType.DRONE:
            return "FLYING DRONE"
        EnemyType.SPIDER:
            return "SPIDER MECH"
    return "HEAVY MECH"
