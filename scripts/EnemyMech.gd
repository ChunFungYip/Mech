extends CharacterBody3D
class_name EnemyMech

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

var health: float = health_max
var target: Node3D
var game: Node3D
var _attack_timer: float = 0.7
var _dead: bool = false
var _visual: Node3D
var _base_move_speed: float
var part_health: Dictionary = {}
var _part_visuals: Dictionary = {}

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.45
    add_to_group("enemy_mechs")
    _initialize_part_health()
    _base_move_speed = move_speed
    _build_collision()
    _build_visual()

func setup(game_instance: Node3D, target_instance: Node3D) -> void:
    game = game_instance
    target = target_instance
    _attack_timer = randf_range(0.45, 1.25)

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 1.2
    capsule.height = 4.6
    collision.shape = capsule
    collision.position = Vector3(0.0, 2.3, 0.0)
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

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)

func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.name = "EnemyVisual"
    add_child(_visual)
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

func _part_box(part_id: StringName, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> void:
    var part_visual := _part_visuals.get(part_id) as Node3D
    if part_visual == null:
        part_visual = Node3D.new()
        part_visual.name = String(PART_DISPLAY_NAMES.get(part_id, part_id))
        _visual.add_child(part_visual)
        _part_visuals[part_id] = part_visual
    _box(part_visual, position, size, color, emission_energy)

func _initialize_part_health() -> void:
    for part_id in PART_IDS:
        part_health[part_id] = float(PART_MAX_HEALTH[part_id])
    health = _get_total_part_health()

func _get_total_part_health() -> float:
    var total := 0.0
    for part_id in PART_IDS:
        total += float(part_health.get(part_id, 0.0))
    return total

func _physics_process(delta: float) -> void:
    if _dead or not is_instance_valid(target):
        return
    var target_position := target.global_position + Vector3(0.0, 2.4, 0.0)
    var to_target := target_position - (global_position + Vector3(0.0, 2.3, 0.0))
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)
    var distance := horizontal.length()
    var direction := horizontal.normalized() if distance > 0.01 else Vector3.ZERO

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

func _fire_at_target(target_position: Vector3) -> void:
    var origin := global_position + Vector3(0.0, 3.15, -0.8)
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
                target.call("take_damage", attack_damage, hit_position)
                break
            current = current.get_parent()
    if game != null and game.has_method("spawn_tracer"):
        game.call("spawn_tracer", origin, hit_position, Color(1.0, 0.16, 0.08))

func take_damage(amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
    if _dead:
        return
    var part_id := _get_hit_part(hit_position)
    var current_part_health := float(part_health.get(part_id, 0.0))
    var maximum_part_health := float(PART_MAX_HEALTH.get(part_id, 0.0))
    var new_part_health := maxf(current_part_health - amount, 0.0)
    part_health[part_id] = new_part_health
    health = _get_total_part_health()
    part_health_changed.emit(part_id, new_part_health, maximum_part_health)
    if current_part_health > 0.0 and is_zero_approx(new_part_health):
        _mark_part_destroyed(part_id)
        part_destroyed.emit(part_id)
    if game != null and game.has_method("spawn_hit_spark"):
        game.call("spawn_hit_spark", hit_position)
    if is_zero_approx(float(part_health.get(&"upper_torso", 0.0))) and is_zero_approx(float(part_health.get(&"lower_torso", 0.0))):
        _destroy_mech()

func _get_hit_part(hit_position: Vector3) -> StringName:
    if hit_position == Vector3.ZERO:
        return &"lower_torso"
    var local_hit := to_local(hit_position)
    if local_hit.y <= 2.25:
        return &"left_leg" if local_hit.x < 0.0 else &"right_leg"
    if absf(local_hit.x) >= 1.0:
        return &"left_arm" if local_hit.x < 0.0 else &"right_arm"
    if local_hit.y >= 3.25:
        return &"upper_torso"
    return &"lower_torso"

func _get_current_move_speed() -> float:
    var left_leg_damaged := float(part_health.get(&"left_leg", PART_MAX_HEALTH[&"left_leg"])) < float(PART_MAX_HEALTH[&"left_leg"])
    var right_leg_damaged := float(part_health.get(&"right_leg", PART_MAX_HEALTH[&"right_leg"])) < float(PART_MAX_HEALTH[&"right_leg"])
    if left_leg_damaged or right_leg_damaged:
        return _base_move_speed * 0.4
    return _base_move_speed

func _mark_part_destroyed(part_id: StringName) -> void:
    var part_visual := _part_visuals.get(part_id) as Node3D
    if part_visual != null:
        part_visual.visible = false

func _destroy_mech() -> void:
    if _dead:
        return
    _dead = true
    died.emit(self)
    if game != null and game.has_method("spawn_explosion"):
        game.call("spawn_explosion", global_position + Vector3(0.0, 2.5, 0.0), 3.2, Color(1.0, 0.22, 0.06))
    queue_free()

func get_part_health_snapshot() -> Dictionary:
    return part_health.duplicate()

func get_part_max_health_snapshot() -> Dictionary:
    return PART_MAX_HEALTH.duplicate()

func get_part_display_names() -> Dictionary:
    return PART_DISPLAY_NAMES.duplicate()
