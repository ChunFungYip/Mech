extends Node3D

const HongKongDistrictScript = preload("res://scripts/HongKongDistrict.gd")
const MechPlayerScript = preload("res://scripts/MechPlayer.gd")
const EnemyMechScript = preload("res://scripts/EnemyMech.gd")
const RocketProjectileScript = preload("res://scripts/RocketProjectile.gd")
const HomingMissileScript = preload("res://scripts/HomingMissile.gd")
const GameHUDScript = preload("res://scripts/GameHUD.gd")
const SettingsMenuScript = preload("res://scripts/SettingsMenu.gd")

var player: Node3D
var district: Node3D
var hud: CanvasLayer
var settings_menu: CanvasLayer
var wave: int = 1
var kills: int = 0
var _next_wave_timer: float = 0.0
var _wave_clear_announced: bool = false

func _ready() -> void:
    _build_environment()
    district = HongKongDistrictScript.new()
    district.name = "MongKokDistrict"
    add_child(district)
    district.call("build", 2407)
    _spawn_player()
    _spawn_wave()
    _spawn_hud()
    _spawn_settings_menu()

func _build_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.012, 0.020, 0.045)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.24, 0.32, 0.48)
    environment.ambient_light_energy = 0.72
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-56.0, -28.0, 0.0)
    moon.light_color = Color(0.42, 0.54, 0.78)
    moon.light_energy = 0.9
    moon.shadow_enabled = true
    add_child(moon)

    var rim_light := DirectionalLight3D.new()
    rim_light.rotation_degrees = Vector3(-20.0, 148.0, 0.0)
    rim_light.light_color = Color(0.95, 0.25, 0.13)
    rim_light.light_energy = 0.20
    rim_light.shadow_enabled = false
    add_child(rim_light)

func _spawn_player() -> void:
    player = MechPlayerScript.new()
    player.name = "HK05Titan"
    add_child(player)
    player.global_position = Vector3(0.0, 0.0, 36.0)
    player.call("setup", self)

func _spawn_wave() -> void:
    var spawn_positions: Array[Vector3] = [
        Vector3(-10.0, 0.0, 10.0),
        Vector3(11.0, 0.0, 0.0),
        Vector3(-12.0, 0.0, -18.0),
        Vector3(13.0, 0.0, -31.0)
    ]
    if wave >= 2:
        spawn_positions.append(Vector3(0.0, 0.0, -49.0))
    if wave >= 3:
        spawn_positions.append(Vector3(-6.0, 0.0, -6.0))
    for index in spawn_positions.size():
        var enemy: Node3D = EnemyMechScript.new()
        enemy.name = "HostileMech_%02d_%02d" % [wave, index + 1]
        add_child(enemy)
        enemy.global_position = spawn_positions[index]
        enemy.call("setup", self, player)
        enemy.connect("died", Callable(self, "_on_enemy_died"))
    _wave_clear_announced = false

func _process(delta: float) -> void:
    if get_enemy_count() == 0:
        if not _wave_clear_announced:
            _wave_clear_announced = true
            _next_wave_timer = 2.5
            if hud != null and hud.has_method("_on_announcement"):
                hud.call("_on_announcement", "MARKET APPROACH CLEAR // NEXT WAVE INBOUND")
        else:
            _next_wave_timer -= delta
            if _next_wave_timer <= 0.0:
                wave += 1
                _spawn_wave()
                if hud != null and hud.has_method("_on_announcement"):
                    hud.call("_on_announcement", "HOSTILE WAVE %02d // ENGAGE" % wave)

func _spawn_hud() -> void:
    hud = GameHUDScript.new()
    add_child(hud)
    hud.call("setup", player, self)

func _spawn_settings_menu() -> void:
    settings_menu = SettingsMenuScript.new()
    settings_menu.name = "SettingsMenu"
    add_child(settings_menu)

func get_enemy_count() -> int:
    return get_tree().get_nodes_in_group("enemy_mechs").size()

func _on_enemy_died(_enemy: Node) -> void:
    kills += 1
    if hud != null and hud.has_method("_on_announcement"):
        hud.call("_on_announcement", "HOSTILE DISABLED // CONFIRMED %02d" % kills)

func spawn_player_rocket(origin: Vector3, direction: Vector3, shooter: Node) -> void:
    var rocket: Node3D = RocketProjectileScript.new()
    add_child(rocket)
    rocket.call("setup", self, shooter, origin, direction, &"enemy_mechs")

func spawn_player_missile_salvo(origin: Vector3, direction: Vector3, shooter: Node, target: Node3D) -> void:
    var side := direction.cross(Vector3.UP).normalized()
    if side.length_squared() < 0.001:
        side = Vector3.RIGHT
    var up := side.cross(direction).normalized()
    var launch_offsets: Array[Vector2] = [
        Vector2(-0.72, 0.18),
        Vector2(-0.48, 0.18),
        Vector2(-0.24, 0.18),
        Vector2(0.00, 0.18),
        Vector2(0.24, -0.18),
        Vector2(0.48, -0.18),
        Vector2(0.72, -0.18),
        Vector2(0.00, -0.42),
    ]
    for offset in launch_offsets:
        var missile: Node3D = HomingMissileScript.new()
        add_child(missile)
        var launch_position := origin + side * offset.x + up * offset.y
        var launch_direction := (direction + side * offset.x * 0.045 + up * offset.y * 0.045).normalized()
        missile.call("setup", self, shooter, launch_position, launch_direction, target)

func spawn_tracer(start: Vector3, finish: Vector3, color: Color) -> void:
    var difference := finish - start
    if difference.length_squared() < 0.0001:
        return
    var tracer := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.055, 0.055, difference.length())
    tracer.mesh = mesh
    tracer.position = (start + finish) * 0.5
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 4.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    tracer.material_override = material
    add_child(tracer)
    tracer.look_at_from_position(tracer.position, finish, Vector3.UP)
    get_tree().create_timer(0.075).timeout.connect(Callable(tracer, "queue_free"))

func spawn_hit_spark(position: Vector3) -> void:
    spawn_explosion(position, 0.42, Color(1.0, 0.78, 0.24))

func spawn_explosion(position: Vector3, radius: float, color: Color = Color(1.0, 0.34, 0.05)) -> void:
    var flash := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.25
    mesh.height = 0.5
    flash.mesh = mesh
    flash.position = position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 5.0
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    flash.material_override = material
    add_child(flash)

    var light := OmniLight3D.new()
    light.position = position
    light.light_color = color
    light.light_energy = 5.0
    light.omni_range = maxf(radius * 2.0, 2.0)
    light.shadow_enabled = false
    add_child(light)

    var tween := create_tween()
    tween.tween_property(flash, "scale", Vector3.ONE * maxf(radius * 0.32, 0.9), 0.16)
    tween.tween_callback(Callable(flash, "queue_free"))
    get_tree().create_timer(0.22).timeout.connect(Callable(light, "queue_free"))
