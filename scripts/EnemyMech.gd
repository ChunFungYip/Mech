extends CharacterBody3D
class_name EnemyMech

signal died(enemy: Node)

@export var move_speed: float = 3.2
@export var health_max: float = 180.0
@export var attack_range: float = 48.0
@export var attack_damage: float = 18.0
@export var attack_interval: float = 1.35

var health: float = health_max
var target: Node3D
var game: Node3D
var _attack_timer: float = 0.7
var _dead: bool = false
var _visual: Node3D

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.45
    add_to_group("enemy_mechs")
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
    _box(_visual, Vector3(0.0, 2.75, 0.0), Vector3(2.3, 2.5, 1.55), armor_mid)
    _box(_visual, Vector3(0.0, 3.25, -0.83), Vector3(1.7, 0.58, 0.08), warning, 2.0)
    _box(_visual, Vector3(0.0, 4.2, 0.0), Vector3(1.5, 1.15, 1.25), armor_dark)
    _box(_visual, Vector3(0.0, 4.25, -0.67), Vector3(0.92, 0.25, 0.08), warning, 3.5)
    _box(_visual, Vector3(-1.42, 3.45, 0.0), Vector3(0.55, 1.45, 0.85), armor_dark)
    _box(_visual, Vector3(1.42, 3.45, 0.0), Vector3(0.55, 1.45, 0.85), armor_dark)
    _box(_visual, Vector3(-1.48, 2.65, -0.75), Vector3(0.62, 0.52, 1.75), armor_light)
    _box(_visual, Vector3(1.48, 2.65, -0.75), Vector3(0.62, 0.52, 1.75), armor_light)
    _box(_visual, Vector3(-0.68, 1.18, 0.0), Vector3(0.78, 2.35, 1.0), armor_mid)
    _box(_visual, Vector3(0.68, 1.18, 0.0), Vector3(0.78, 2.35, 1.0), armor_mid)
    _box(_visual, Vector3(-0.68, 0.15, -0.3), Vector3(0.96, 0.3, 1.55), armor_dark)
    _box(_visual, Vector3(0.68, 0.15, -0.3), Vector3(0.96, 0.3, 1.55), armor_dark)
    _box(_visual, Vector3(1.5, 3.0, -2.25), Vector3(0.42, 0.42, 2.45), Color(0.08, 0.06, 0.07))
    _box(_visual, Vector3(1.5, 3.0, -3.58), Vector3(0.18, 0.18, 0.32), warning, 3.0)

func _physics_process(delta: float) -> void:
    if _dead or not is_instance_valid(target):
        return
    var target_position := target.global_position + Vector3(0.0, 2.4, 0.0)
    var to_target := target_position - (global_position + Vector3(0.0, 2.3, 0.0))
    var horizontal := Vector3(to_target.x, 0.0, to_target.z)
    var distance := horizontal.length()
    var direction := horizontal.normalized() if distance > 0.01 else Vector3.ZERO

    if distance > 15.0:
        velocity.x = move_toward(velocity.x, direction.x * move_speed, 10.0 * delta)
        velocity.z = move_toward(velocity.z, direction.z * move_speed, 10.0 * delta)
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
    health = maxf(health - amount, 0.0)
    if game != null and game.has_method("spawn_hit_spark"):
        game.call("spawn_hit_spark", hit_position)
    if health <= 0.0:
        _dead = true
        died.emit(self)
        if game != null and game.has_method("spawn_explosion"):
            game.call("spawn_explosion", global_position + Vector3(0.0, 2.5, 0.0), 3.2, Color(1.0, 0.22, 0.06))
        queue_free()
