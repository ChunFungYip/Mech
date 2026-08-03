extends CharacterBody3D
class_name MechPlayer

signal stats_changed
signal view_mode_changed(first_person: bool)
signal announcement(text: String)

@export var move_speed: float = 7.5
@export var boost_multiplier: float = 1.65
@export var acceleration: float = 24.0
@export var gravity: float = 18.0
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

var health: float = health_max
var machinegun_ammo: int = machinegun_magazine_size
var machinegun_reserve: int = machinegun_reserve_max
var rocket_ammo: int = rocket_magazine_size
var rocket_reserve: int = rocket_reserve_max
var first_person: bool = true
var yaw: float = 0.0
var pitch: float = -0.08

var game: Node3D
var _body_visual: Node3D
var _view_pivot: Node3D
var _spring_arm: SpringArm3D
var _first_person_camera: Camera3D
var _third_person_camera: Camera3D
var _machinegun_cooldown: float = 0.0
var _rocket_cooldown: float = 0.0
var _reload_timer: float = 0.0

func setup(game_instance: Node3D) -> void:
    game = game_instance

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    floor_snap_length = 0.5
    floor_stop_on_slope = true
    _build_collision()
    _build_visual()
    _build_cameras()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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

func _process(delta: float) -> void:
    _machinegun_cooldown = maxf(_machinegun_cooldown - delta, 0.0)
    _rocket_cooldown = maxf(_rocket_cooldown - delta, 0.0)
    if _reload_timer > 0.0:
        _reload_timer = maxf(_reload_timer - delta, 0.0)
        if is_zero_approx(_reload_timer):
            _finish_reload()

    if Input.is_action_just_pressed("toggle_view"):
        toggle_view()
    if Input.is_action_just_pressed("reload"):
        _start_reload()
    if Input.is_action_pressed("fire_machinegun"):
        _fire_machinegun()
    if Input.is_action_just_pressed("fire_rocket"):
        _fire_rocket()

func _physics_process(delta: float) -> void:
    var forward_input := Input.get_axis("move_back", "move_forward")
    var strafe_input := Input.get_axis("move_left", "move_right")
    var local_direction := Vector3(strafe_input, 0.0, -forward_input)
    var move_direction := local_direction.rotated(Vector3.UP, yaw)
    if move_direction.length_squared() > 1.0:
        move_direction = move_direction.normalized()

    var speed := move_speed
    if Input.is_action_pressed("boost"):
        speed *= boost_multiplier
    var target_velocity := move_direction * speed
    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0
    move_and_slide()

    _view_pivot.rotation = Vector3(pitch, yaw, 0.0)
    _body_visual.rotation.y = lerp_angle(_body_visual.rotation.y, yaw, minf(delta * 8.0, 1.0))
    stats_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.0025
        pitch = clampf(pitch - event.relative.y * 0.0022, -1.05, 0.72)
    elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_view() -> void:
    first_person = not first_person
    _first_person_camera.current = first_person
    _third_person_camera.current = not first_person
    _body_visual.visible = not first_person
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

func _fire_machinegun() -> void:
    if _machinegun_cooldown > 0.0 or _reload_timer > 0.0:
        return
    if machinegun_ammo <= 0:
        _start_reload()
        return

    _machinegun_cooldown = machinegun_fire_interval
    machinegun_ammo -= 1
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
    if game != null and game.has_method("spawn_tracer"):
        game.call("spawn_tracer", ray_origin, hit_position, Color(1.0, 0.76, 0.20))
    stats_changed.emit()

func _fire_rocket() -> void:
    if _rocket_cooldown > 0.0 or _reload_timer > 0.0 or rocket_ammo <= 0:
        if rocket_ammo <= 0:
            announcement.emit("ROCKET POD // EMPTY")
        return
    _rocket_cooldown = 0.85
    rocket_ammo -= 1
    var aim := _get_aim_ray()
    var ray_origin: Vector3 = aim["origin"]
    var ray_direction: Vector3 = aim["direction"]
    if game != null and game.has_method("spawn_player_rocket"):
        game.call("spawn_player_rocket", ray_origin + ray_direction * 1.2, ray_direction, self)
    stats_changed.emit()

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

func take_damage(amount: float, _hit_position: Vector3 = Vector3.ZERO) -> void:
    health = maxf(health - amount, 0.0)
    if health <= 0.0:
        health = health_max
        global_position = Vector3(0.0, 0.0, 36.0)
        velocity = Vector3.ZERO
        announcement.emit("COCKPIT RESET // PILOT LINK RESTORED")
    stats_changed.emit()
