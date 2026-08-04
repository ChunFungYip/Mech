extends Node3D
class_name RepairBot

const INTERACTION_RANGE: float = 5.5

var game: Node3D
var player: Node3D
var _prompt: Label3D

func setup(game_instance: Node3D, player_instance: Node3D) -> void:
    game = game_instance
    player = player_instance

func _ready() -> void:
    _build_collision()
    _build_visual()
    _build_prompt()

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var distance := global_position.distance_to(player.global_position)
    var can_interact := distance <= INTERACTION_RANGE
    _prompt.visible = can_interact
    if can_interact and Input.is_action_just_pressed("interact") and game != null and game.has_method("open_repair_bot"):
        game.call("open_repair_bot")

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

func _build_collision() -> void:
    var body := StaticBody3D.new()
    body.name = "RepairBotCollision"
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.55
    shape.height = 2.2
    collision.shape = shape
    collision.position = Vector3(0.0, 1.1, 0.0)
    body.add_child(collision)

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)

func _build_visual() -> void:
    var visual := Node3D.new()
    visual.name = "RepairBotVisual"
    add_child(visual)
    var dark := Color(0.05, 0.10, 0.12)
    var teal := Color(0.12, 0.42, 0.45)
    var light := Color(0.32, 0.76, 0.70)
    var orange := Color(1.0, 0.34, 0.08)
    var screen := Color(0.10, 0.82, 0.92)

    _box(visual, Vector3(0.0, 1.0, 0.0), Vector3(1.35, 1.45, 0.9), teal)
    _box(visual, Vector3(0.0, 2.02, 0.0), Vector3(0.85, 0.55, 0.65), dark)
    _box(visual, Vector3(0.0, 2.02, -0.34), Vector3(0.56, 0.18, 0.06), screen, 2.5)
    _box(visual, Vector3(-0.78, 1.15, 0.0), Vector3(0.22, 1.05, 0.24), dark)
    _box(visual, Vector3(0.78, 1.15, 0.0), Vector3(0.22, 1.05, 0.24), dark)
    _box(visual, Vector3(-0.78, 0.62, -0.18), Vector3(0.35, 0.16, 0.35), light, 1.5)
    _box(visual, Vector3(0.78, 0.62, -0.18), Vector3(0.35, 0.16, 0.35), light, 1.5)
    _box(visual, Vector3(0.0, 0.18, 0.0), Vector3(1.65, 0.20, 1.1), dark)
    _box(visual, Vector3(0.0, 2.48, 0.0), Vector3(0.10, 0.65, 0.10), orange, 2.5)

    var light_node := OmniLight3D.new()
    light_node.position = Vector3(0.0, 2.05, -0.5)
    light_node.light_color = screen
    light_node.light_energy = 1.2
    light_node.omni_range = 4.0
    light_node.shadow_enabled = false
    visual.add_child(light_node)

func _build_prompt() -> void:
    _prompt = Label3D.new()
    _prompt.text = "E  //  TALK TO REPAIR BOT"
    _prompt.position = Vector3(0.0, 3.1, 0.0)
    _prompt.font_size = 34
    _prompt.modulate = Color(1.0, 0.78, 0.28)
    _prompt.outline_size = 7
    _prompt.outline_modulate = Color(0.01, 0.02, 0.03, 0.95)
    _prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _prompt.double_sided = true
    _prompt.visible = false
    add_child(_prompt)
