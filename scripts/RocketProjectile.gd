extends Node3D
class_name RocketProjectile

var game: Node3D
var shooter: Node
var direction: Vector3 = Vector3.FORWARD
var target_group: StringName = &"enemy_mechs"
var speed: float = 32.0
var damage: float = 110.0
var explosion_radius: float = 5.0
var lifetime: float = 7.0
var _detonated: bool = false
var _smoke_timer: float = 0.0

func setup(game_instance: Node3D, shooter_instance: Node, start: Vector3, heading: Vector3, group_name: StringName, damage_amount: float = 110.0, explosion_radius_amount: float = 5.0) -> void:
    game = game_instance
    shooter = shooter_instance
    global_position = start
    direction = heading.normalized()
    target_group = group_name
    damage = damage_amount
    explosion_radius = explosion_radius_amount

func _ready() -> void:
    add_to_group("projectiles")
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.24
    mesh.height = 0.48
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.34, 0.05)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.15, 0.02)
    material.emission_energy_multiplier = 5.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_instance.material_override = material
    add_child(mesh_instance)

    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.16, 0.04)
    light.light_energy = 1.6
    light.omni_range = 4.5
    light.shadow_enabled = false
    add_child(light)

func _physics_process(delta: float) -> void:
    if _detonated:
        return
    lifetime -= delta
    if lifetime <= 0.0:
        _detonate(global_position, null)
        return

    var next_position := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
    query.collision_mask = 1
    query.exclude = []
    if shooter is CollisionObject3D:
        query.exclude = [shooter.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        _detonate(hit["position"], hit.get("collider") as Node)
        return
    global_position = next_position
    _smoke_timer -= delta
    if _smoke_timer <= 0.0 and game != null and game.has_method("spawn_smoke_puff"):
        game.call("spawn_smoke_puff", global_position, Color(0.28, 0.30, 0.32, 0.42))
        _smoke_timer = 0.06

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
    AudioManager.play_sound(&"explosion", position, clampf(explosion_radius / 5.0, 0.6, 1.5))
    var direct_target := _find_damage_target(collider)
    var damaged: Array[Node] = []
    if direct_target != null and direct_target != shooter:
        direct_target.call("take_damage", damage, position)
        if shooter != null and shooter.has_method("notify_weapon_hit"):
            shooter.call("notify_weapon_hit", direct_target, position)
        damaged.append(direct_target)

    for candidate in get_tree().get_nodes_in_group(target_group):
        var target := candidate as Node
        if target == null or not is_instance_valid(target) or damaged.has(target):
            continue
        var target_position := (target as Node3D).global_position + Vector3(0.0, 2.2, 0.0)
        if position.distance_to(target_position) <= explosion_radius:
            target.call("take_damage", damage * 0.72, position)
            if shooter != null and shooter.has_method("notify_weapon_hit"):
                shooter.call("notify_weapon_hit", target, position)

    if game != null and game.has_method("spawn_explosion"):
        game.call("spawn_explosion", position, explosion_radius, Color(1.0, 0.34, 0.05))
    queue_free()
