extends Node3D
class_name HomingMissile

var game: Node3D
var shooter: Node
var target: Node3D
var target_group: StringName = &"enemy_mechs"
var direction: Vector3 = Vector3.FORWARD
var speed: float = 28.0
var turn_rate: float = 4.8
var damage: float = 46.0
var explosion_radius: float = 2.8
var lifetime: float = 8.0
var _detonated: bool = false
var _smoke_timer: float = 0.0

func setup(game_instance: Node3D, shooter_instance: Node, start: Vector3, heading: Vector3, target_instance: Node3D = null, damage_amount: float = 46.0, explosion_radius_amount: float = 2.8, target_group_name: StringName = &"enemy_mechs") -> void:
    game = game_instance
    shooter = shooter_instance
    target = target_instance
    global_position = start
    direction = heading.normalized()
    damage = damage_amount
    explosion_radius = explosion_radius_amount
    target_group = target_group_name

func _ready() -> void:
    add_to_group("projectiles")
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.16
    mesh.height = 0.62
    mesh_instance.mesh = mesh
    mesh_instance.scale = Vector3(0.72, 0.72, 1.7)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.42, 0.06)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.12, 0.02)
    material.emission_energy_multiplier = 5.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.16, 0.03)
    light.light_energy = 1.2
    light.omni_range = 3.2
    light.shadow_enabled = false
    add_child(light)

func _physics_process(delta: float) -> void:
    if _detonated:
        return
    lifetime -= delta
    if lifetime <= 0.0:
        _detonate(global_position, null)
        return

    if target != null and not is_instance_valid(target):
        target = null
    if target != null:
        var target_position := target.global_position + Vector3(0.0, 2.2, 0.0)
        if global_position.distance_to(target_position) <= 1.6:
            _detonate(global_position, target)
            return
        var desired_direction := global_position.direction_to(target_position)
        direction = direction.lerp(desired_direction, clampf(turn_rate * delta, 0.0, 1.0)).normalized()

    var next_position := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
    query.collision_mask = 1
    query.exclude = []
    if shooter is CollisionObject3D:
        query.exclude.append(shooter.get_rid())
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        _detonate(hit["position"], hit.get("collider") as Node)
        return

    global_position = next_position
    look_at_from_position(global_position, global_position + direction, Vector3.UP)
    _smoke_timer -= delta
    if _smoke_timer <= 0.0 and game != null and game.has_method("spawn_smoke_puff"):
        game.call("spawn_smoke_puff", global_position, Color(0.24, 0.28, 0.32, 0.38))
        _smoke_timer = 0.055

func _find_damage_target(collider: Node) -> Node:
    var current := collider
    while current != null:
        if current.has_method("take_damage"):
            return current
        current = current.get_parent()
    return null

func _detonate(position: Vector3, collider: Node) -> void:
    if _detonated:
        return
    _detonated = true
    global_position = position
    AudioManager.play_sound(&"explosion", position, clampf(explosion_radius / 2.8, 0.5, 1.4))

    var direct_target := _find_damage_target(collider)
    if direct_target != null and direct_target != shooter:
        direct_target.call("take_damage", damage, position)
        if shooter != null and shooter.has_method("notify_weapon_hit"):
            shooter.call("notify_weapon_hit", direct_target, position)

    for candidate_variant in get_tree().get_nodes_in_group(target_group):
        var candidate := candidate_variant as Node3D
        if candidate == null or not is_instance_valid(candidate) or candidate == direct_target:
            continue
        var candidate_position := candidate.global_position + Vector3(0.0, 2.2, 0.0)
        if position.distance_to(candidate_position) <= explosion_radius:
            candidate.call("take_damage", damage * 0.72, position)
            if shooter != null and shooter.has_method("notify_weapon_hit"):
                shooter.call("notify_weapon_hit", candidate, position)

    if game != null and game.has_method("spawn_explosion"):
        game.call("spawn_explosion", position, explosion_radius, Color(1.0, 0.28, 0.04))
    queue_free()
