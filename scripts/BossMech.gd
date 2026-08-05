extends CharacterBody3D
class_name BossMech

signal defeated(boss: Node)
signal health_changed(current: float, maximum: float)
signal activated
signal phase_changed(phase: int)

@export var health_max: float = 2400.0
@export var move_speed: float = 2.1
@export var attack_range: float = 75.0
@export var attack_damage: float = 34.0
@export var attack_interval: float = 1.1

var health: float = health_max
var target: Node3D
var game: Node3D
var is_boss: bool = true
var is_defeated: bool = false
var active: bool = false
var phase: int = 1
var _dead: bool = false
var _attack_timer: float = 2.0
var _special_attack_timer: float = 4.5
var _special_attack_index: int = 0
var _base_health_max: float
var _base_attack_damage: float
var _visual: Node3D
var _phase_label: Label3D

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.5
    add_to_group("enemy_mechs")
    add_to_group("boss_mechs")
    _build_collision()
    _build_visual()
    _base_health_max = health_max
    _base_attack_damage = attack_damage

func setup(game_instance: Node3D, target_instance: Node3D) -> void:
    game = game_instance
    target = target_instance

func apply_difficulty(health_scale: float, damage_scale: float) -> void:
    var health_ratio := health / maxf(health_max, 0.01)
    health_max = _base_health_max * health_scale
    health = health_max * health_ratio
    attack_damage = _base_attack_damage * damage_scale
    health_changed.emit(health, health_max)

func activate() -> void:
    if active or _dead:
        return
    active = true
    _attack_timer = 1.2
    _special_attack_timer = 4.5
    _apply_phase()
    activated.emit()

func reset_encounter() -> void:
    if _dead:
        return
    active = false
    is_defeated = false
    phase = 1
    health = health_max
    velocity = Vector3.ZERO
    _attack_timer = 2.0
    _special_attack_timer = 4.5
    _special_attack_index = 0
    _apply_phase()

func _apply_phase() -> void:
    match phase:
        2:
            move_speed = 2.7
            attack_damage = 42.0
            attack_interval = 0.82
        3:
            move_speed = 3.3
            attack_damage = 52.0
            attack_interval = 0.58
        _:
            move_speed = 2.1
            attack_damage = 34.0
            attack_interval = 1.1
    if _phase_label != null:
        _phase_label.text = "CENTRAL MARKET // SIEGE CLASS // PHASE %02d" % phase

func _build_collision() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 2.8
    capsule.height = 10.4
    collision.shape = capsule
    collision.position = Vector3(0.0, 5.2, 0.0)
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

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)

func _sphere(parent: Node3D, position: Vector3, radius: float, color: Color, emission_energy: float = 0.0) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)

func _build_visual() -> void:
    _visual = Node3D.new()
    _visual.name = "BossVisual"
    add_child(_visual)

    var armor_dark := Color(0.045, 0.055, 0.08)
    var armor_mid := Color(0.16, 0.20, 0.30)
    var armor_light := Color(0.30, 0.42, 0.56)
    var warning := Color(1.0, 0.12, 0.035)
    var reactor := Color(0.76, 0.06, 0.13)

    _box(_visual, Vector3(0.0, 3.2, 0.0), Vector3(5.6, 3.2, 3.5), armor_mid)
    _box(_visual, Vector3(0.0, 5.0, -1.82), Vector3(4.4, 0.22, 0.12), warning, 3.0)
    _box(_visual, Vector3(0.0, 5.5, 0.0), Vector3(6.4, 1.9, 3.8), armor_light)
    _box(_visual, Vector3(0.0, 6.0, -1.95), Vector3(3.0, 0.72, 0.12), armor_dark)
    _box(_visual, Vector3(0.0, 6.0, -2.02), Vector3(1.55, 0.25, 0.08), warning, 3.5)
    _box(_visual, Vector3(0.0, 7.4, 0.0), Vector3(3.2, 1.9, 2.8), armor_dark)
    _box(_visual, Vector3(0.0, 7.35, -1.42), Vector3(1.75, 0.38, 0.08), warning, 4.0)
    _box(_visual, Vector3(0.0, 8.65, 0.0), Vector3(0.38, 1.0, 0.38), warning, 2.5)

    _box(_visual, Vector3(-3.65, 5.3, 0.0), Vector3(1.4, 2.7, 1.55), armor_mid)
    _box(_visual, Vector3(3.65, 5.3, 0.0), Vector3(1.4, 2.7, 1.55), armor_mid)
    _box(_visual, Vector3(-3.8, 3.55, -0.75), Vector3(1.25, 1.0, 1.45), armor_light)
    _box(_visual, Vector3(3.8, 3.55, -0.75), Vector3(1.25, 1.0, 1.45), armor_light)
    _box(_visual, Vector3(-3.8, 3.55, -2.0), Vector3(0.72, 0.72, 2.3), armor_dark)
    _box(_visual, Vector3(3.8, 3.55, -2.0), Vector3(0.72, 0.72, 2.3), armor_dark)
    _box(_visual, Vector3(-3.8, 3.55, -3.25), Vector3(0.30, 0.30, 0.5), warning, 4.0)
    _box(_visual, Vector3(3.8, 3.55, -3.25), Vector3(0.30, 0.30, 0.5), warning, 4.0)

    _box(_visual, Vector3(-1.65, 1.15, 0.0), Vector3(1.55, 2.3, 1.75), armor_mid)
    _box(_visual, Vector3(1.65, 1.15, 0.0), Vector3(1.55, 2.3, 1.75), armor_mid)
    _box(_visual, Vector3(-1.65, 0.08, -0.45), Vector3(1.9, 0.35, 2.2), armor_dark)
    _box(_visual, Vector3(1.65, 0.08, -0.45), Vector3(1.9, 0.35, 2.2), armor_dark)

    _sphere(_visual, Vector3(0.0, 3.35, -1.82), 0.68, reactor, 5.0)
    _box(_visual, Vector3(0.0, 3.35, -2.42), Vector3(1.55, 0.14, 0.12), warning, 4.0)
    _box(_visual, Vector3(0.0, 1.0, 1.95), Vector3(4.4, 2.4, 0.24), armor_dark)
    _box(_visual, Vector3(0.0, 2.0, 2.10), Vector3(2.8, 0.18, 0.10), reactor, 3.0)

    var light := OmniLight3D.new()
    light.position = Vector3(0.0, 3.5, -2.4)
    light.light_color = Color(1.0, 0.08, 0.05)
    light.light_energy = 2.5
    light.omni_range = 9.0
    light.shadow_enabled = false
    _visual.add_child(light)

    _phase_label = Label3D.new()
    _phase_label.text = "CENTRAL MARKET // SIEGE CLASS // PHASE 01"
    _phase_label.position = Vector3(0.0, 10.4, 0.0)
    _phase_label.font_size = 44
    _phase_label.modulate = Color(1.0, 0.30, 0.16)
    _phase_label.outline_size = 8
    _phase_label.outline_modulate = Color(0.005, 0.01, 0.02, 0.96)
    _phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _phase_label.double_sided = true
    _visual.add_child(_phase_label)

func _physics_process(delta: float) -> void:
    if not active or _dead or not is_instance_valid(target):
        return
    var chase_position := target.global_position
    if game != null and game.has_method("get_enemy_target_position"):
        chase_position = game.call("get_enemy_target_position")
    var target_position := chase_position + Vector3(0.0, 2.4, 0.0)
    var to_target := target_position - (global_position + Vector3(0.0, 5.0, 0.0))
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)
    var distance := horizontal.length()
    var direction := horizontal.normalized() if distance > 0.01 else Vector3.ZERO

    if distance > 23.0:
        velocity.x = move_toward(velocity.x, direction.x * move_speed, 7.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, 7.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0
    move_and_slide()

    if horizontal.length_squared() > 0.01:
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 4.0, 1.0))
    _attack_timer -= delta
    if _attack_timer <= 0.0 and distance <= attack_range:
        _fire_at_target(target_position)
        _attack_timer = attack_interval + randf_range(-0.15, 0.25)
    _special_attack_timer -= delta
    if phase >= 2 and _special_attack_timer <= 0.0:
        _fire_special_attack()
        _special_attack_index += 1
        _special_attack_timer = 5.6 if phase == 2 else 3.8

func _fire_special_attack() -> void:
    if game == null or not is_instance_valid(target):
        return
    var origin := global_position + global_transform.basis * Vector3(0.0, 6.8, -2.2)
    var target_position := target.global_position + Vector3(0.0, 2.0, 0.0)
    var direction := origin.direction_to(target_position)
    if _special_attack_index % 2 == 0:
        if game.has_method("spawn_boss_missile_salvo"):
            game.call("spawn_boss_missile_salvo", origin, direction, self, target, 32.0 if phase == 2 else 44.0, 3.6 if phase == 2 else 4.8)
        AudioManager.play_sound(&"boss_attack", global_position, 1.25)
    elif game.has_method("spawn_boss_hazard"):
        game.call("spawn_boss_hazard", target.global_position, 5.5 if phase == 2 else 7.0, 38.0 if phase == 2 else 52.0, 1.2 if phase == 2 else 0.8, 3.4 if phase == 2 else 4.2)
        AudioManager.play_sound(&"hazard", global_position, 1.2)

func _fire_at_target(target_position: Vector3) -> void:
    var origin := global_position + global_transform.basis * Vector3(0.0, 6.1, -2.0)
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
        game.call("spawn_tracer", origin, hit_position, Color(1.0, 0.05, 0.02))
    AudioManager.play_sound(&"enemy_fire", global_position, 1.5)

func take_damage(amount: float, hit_position: Vector3 = Vector3.ZERO) -> void:
    if _dead or not active:
        return
    health = maxf(health - amount, 0.0)
    health_changed.emit(health, health_max)
    AudioManager.play_sound(&"hit", hit_position, 1.2)
    if game != null and game.has_method("spawn_hit_spark"):
        game.call("spawn_hit_spark", hit_position)
    if health <= 0.0:
        _dead = true
        is_defeated = true
        defeated.emit(self)
        if game != null and game.has_method("spawn_explosion"):
            game.call("spawn_explosion", global_position + Vector3(0.0, 5.0, 0.0), 7.0, Color(1.0, 0.10, 0.03))
        AudioManager.play_sound(&"explosion", global_position, 1.8)
        queue_free()
        return
    var next_phase := 1
    if health <= health_max * 0.25:
        next_phase = 3
    elif health <= health_max * 0.50:
        next_phase = 2
    if next_phase > phase:
        phase = next_phase
        _apply_phase()
        phase_changed.emit(phase)

func get_health_percent() -> float:
    return health / maxf(health_max, 0.01)

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
