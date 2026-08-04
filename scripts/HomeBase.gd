extends Node3D
class_name HomeBase

const BASE_CENTER := Vector3(0.0, 0.0, 39.0)
const BASE_WIDTH: float = 19.0
const BASE_DEPTH: float = 25.0
const BASE_HEIGHT: float = 10.5
const HANGAR_DOOR_HEIGHT: float = 8.2
const HANGAR_DOOR_OPEN_OFFSET: float = 9.0
const HANGAR_DOOR_OPEN_DISTANCE: float = 6.0
const HANGAR_DOOR_CLOSE_DISTANCE: float = 9.0

var _hangar_door: AnimatableBody3D
var _hangar_door_closed_y: float
var _hangar_door_open: bool = false
var _hangar_door_tween: Tween

func build() -> void:
    _build_structure()
    _build_hangar_door()
    _build_hangar_details()
    _build_spawn_pad()
    _build_lighting()

func _material(color: Color, emission_energy: float = 0.0, roughness: float = 0.76) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    if emission_energy > 0.0:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission_energy
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return material

func _box(position: Vector3, size: Vector3, color: Color, collidable: bool = true, emission_energy: float = 0.0) -> Node3D:
    var holder: Node3D = StaticBody3D.new() if collidable else Node3D.new()
    holder.position = position

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _material(color, emission_energy)
    holder.add_child(mesh_instance)

    if collidable:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        holder.add_child(collision)

    add_child(holder)
    return holder

func _label(text: String, position: Vector3, color: Color, font_size: int = 64) -> void:
    var label := Label3D.new()
    label.text = text
    label.position = position
    label.font_size = font_size
    label.modulate = color
    label.outline_size = 8
    label.outline_modulate = Color(0.005, 0.01, 0.02, 0.96)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.double_sided = true
    add_child(label)

func _neon(position: Vector3, size: Vector3, color: Color, energy: float = 3.5) -> void:
    _box(position, size, color, false, energy)
    var light := OmniLight3D.new()
    light.position = position
    light.light_color = color
    light.light_energy = energy * 0.16
    light.omni_range = maxf(size.length() * 2.2, 3.0)
    light.shadow_enabled = false
    add_child(light)

func _child_box(parent: Node3D, position: Vector3, size: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = position
    mesh_instance.material_override = _material(color, emission_energy)
    parent.add_child(mesh_instance)
    return mesh_instance

func _build_structure() -> void:
    var center_z := BASE_CENTER.z
    var side_x := BASE_WIDTH * 0.5
    var front_z := center_z - BASE_DEPTH * 0.5
    var back_z := center_z + BASE_DEPTH * 0.5
    var wall_color := Color(0.075, 0.12, 0.15)
    var trim_color := Color(0.15, 0.28, 0.30)
    var floor_color := Color(0.12, 0.14, 0.15)

    _box(Vector3(0.0, -0.12, center_z), Vector3(BASE_WIDTH, 0.24, BASE_DEPTH), floor_color)
    _box(Vector3(-side_x, BASE_HEIGHT * 0.5, center_z), Vector3(0.55, BASE_HEIGHT, BASE_DEPTH), wall_color)
    _box(Vector3(side_x, BASE_HEIGHT * 0.5, center_z), Vector3(0.55, BASE_HEIGHT, BASE_DEPTH), wall_color)
    _box(Vector3(0.0, BASE_HEIGHT, center_z), Vector3(BASE_WIDTH + 0.8, 0.55, BASE_DEPTH + 0.8), wall_color)
    _box(Vector3(0.0, BASE_HEIGHT * 0.5, back_z), Vector3(BASE_WIDTH, BASE_HEIGHT, 0.55), wall_color)

    _box(Vector3(-side_x + 0.36, BASE_HEIGHT * 0.5, center_z), Vector3(0.18, BASE_HEIGHT - 0.6, BASE_DEPTH - 0.7), trim_color, false)
    _box(Vector3(side_x - 0.36, BASE_HEIGHT * 0.5, center_z), Vector3(0.18, BASE_HEIGHT - 0.6, BASE_DEPTH - 0.7), trim_color, false)
    _box(Vector3(0.0, BASE_HEIGHT - 0.38, front_z + 0.3), Vector3(BASE_WIDTH - 0.8, 0.22, 0.22), trim_color, false)

    _neon(Vector3(-side_x + 0.34, 5.2, front_z + 0.4), Vector3(0.12, 5.6, 0.18), Color(0.05, 0.78, 0.90), 3.0)
    _neon(Vector3(side_x - 0.34, 5.2, front_z + 0.4), Vector3(0.12, 5.6, 0.18), Color(1.0, 0.22, 0.08), 3.0)
    _neon(Vector3(0.0, BASE_HEIGHT - 0.35, front_z + 0.42), Vector3(BASE_WIDTH - 1.2, 0.18, 0.18), Color(1.0, 0.64, 0.12), 3.5)
    _label("HK-05 // PILOT HOME BASE", Vector3(0.0, BASE_HEIGHT - 0.7, front_z + 0.12), Color(1.0, 0.72, 0.24), 48)

func _build_hangar_door() -> void:
    var front_z := BASE_CENTER.z - BASE_DEPTH * 0.5
    var door_width := BASE_WIDTH - 1.0
    _hangar_door_closed_y = HANGAR_DOOR_HEIGHT * 0.5
    _hangar_door = AnimatableBody3D.new()
    _hangar_door.name = "UpwardHangarDoor"
    _hangar_door.position = Vector3(0.0, _hangar_door_closed_y, front_z + 0.28)
    add_child(_hangar_door)

    var door_color := Color(0.045, 0.09, 0.11)
    var door_trim := Color(0.14, 0.30, 0.32)
    _child_box(_hangar_door, Vector3.ZERO, Vector3(door_width, HANGAR_DOOR_HEIGHT, 0.42), door_color)
    _child_box(_hangar_door, Vector3(0.0, 0.0, -0.23), Vector3(door_width - 0.6, 0.16, 0.08), door_trim)
    _child_box(_hangar_door, Vector3(0.0, -2.9, -0.23), Vector3(door_width - 0.6, 0.16, 0.08), door_trim)
    for x in [-6.5, -3.25, 0.0, 3.25, 6.5]:
        _child_box(_hangar_door, Vector3(x, 0.0, -0.24), Vector3(0.12, HANGAR_DOOR_HEIGHT - 0.4, 0.06), Color(0.10, 0.20, 0.22), 0.2)
    _child_box(_hangar_door, Vector3(-door_width * 0.5 + 0.28, 0.0, -0.25), Vector3(0.12, HANGAR_DOOR_HEIGHT - 0.25, 0.08), Color(0.05, 0.60, 0.68), 2.5)
    _child_box(_hangar_door, Vector3(door_width * 0.5 - 0.28, 0.0, -0.25), Vector3(0.12, HANGAR_DOOR_HEIGHT - 0.25, 0.08), Color(1.0, 0.26, 0.08), 2.5)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(door_width, HANGAR_DOOR_HEIGHT, 0.42)
    collision.shape = shape
    _hangar_door.add_child(collision)
    _label("HANGAR DOOR // AUTO LIFT", Vector3(0.0, BASE_HEIGHT + 0.75, front_z - 0.15), Color(0.36, 0.86, 0.88), 30)

func update_hangar_door(player_position: Vector3) -> void:
    if _hangar_door == null:
        return
    var front_z := BASE_CENTER.z - BASE_DEPTH * 0.5
    var distance_from_front := front_z - player_position.z
    if not _hangar_door_open and distance_from_front >= -HANGAR_DOOR_OPEN_DISTANCE:
        set_hangar_door_open(true)
    elif _hangar_door_open and distance_from_front < -HANGAR_DOOR_CLOSE_DISTANCE:
        set_hangar_door_open(false)

func set_hangar_door_open(open: bool) -> void:
    if _hangar_door == null or _hangar_door_open == open:
        return
    _hangar_door_open = open
    if _hangar_door_tween != null and _hangar_door_tween.is_running():
        _hangar_door_tween.kill()
    var target_y := _hangar_door_closed_y + HANGAR_DOOR_OPEN_OFFSET if open else _hangar_door_closed_y
    _hangar_door_tween = create_tween()
    _hangar_door_tween.set_trans(Tween.TRANS_QUAD)
    _hangar_door_tween.set_ease(Tween.EASE_IN_OUT)
    _hangar_door_tween.tween_property(_hangar_door, "position:y", target_y, 1.0)

func _build_hangar_details() -> void:
    var center_z := BASE_CENTER.z
    var back_z := center_z + BASE_DEPTH * 0.5
    var console_color := Color(0.06, 0.20, 0.23)
    var screen_color := Color(0.08, 0.76, 0.86)
    var hazard_color := Color(0.94, 0.30, 0.06)

    _box(Vector3(-6.0, 1.2, back_z - 1.2), Vector3(4.2, 2.4, 0.75), console_color)
    _box(Vector3(-6.0, 2.25, back_z - 1.62), Vector3(2.2, 0.72, 0.08), screen_color, false, 2.5)
    _label("PILOT LINK", Vector3(-6.0, 2.75, back_z - 1.70), screen_color, 28)

    _box(Vector3(6.0, 1.2, back_z - 1.2), Vector3(4.2, 2.4, 0.75), console_color)
    _box(Vector3(6.0, 2.25, back_z - 1.62), Vector3(2.2, 0.72, 0.08), hazard_color, false, 2.5)
    _label("ARMORY", Vector3(6.0, 2.75, back_z - 1.70), hazard_color, 28)

    for z in range(int(center_z - 8.0), int(center_z + 10.0), 3):
        _box(Vector3(-9.25, 4.0, float(z)), Vector3(0.12, 2.8, 0.42), Color(0.26, 0.35, 0.36), false)
        _box(Vector3(9.25, 4.0, float(z)), Vector3(0.12, 2.8, 0.42), Color(0.26, 0.35, 0.36), false)

    _neon(Vector3(0.0, 6.2, center_z + 11.7), Vector3(10.0, 0.12, 0.12), Color(0.12, 0.78, 0.92), 2.5)
    _label("NEON HARBOUR // LAUNCH BAY", Vector3(0.0, 6.7, center_z + 11.15), Color(0.42, 0.88, 0.92), 34)

func _build_spawn_pad() -> void:
    var pad_position := Vector3(0.0, 0.02, BASE_CENTER.z - 0.5)
    _box(pad_position, Vector3(6.0, 0.06, 8.0), Color(0.09, 0.18, 0.19), false)
    _neon(Vector3(-2.8, 0.07, pad_position.z), Vector3(0.10, 0.04, 7.0), Color(0.10, 0.85, 0.92), 2.2)
    _neon(Vector3(2.8, 0.07, pad_position.z), Vector3(0.10, 0.04, 7.0), Color(0.10, 0.85, 0.92), 2.2)
    _neon(Vector3(0.0, 0.07, pad_position.z - 3.3), Vector3(5.6, 0.04, 0.10), Color(1.0, 0.38, 0.08), 2.2)
    _label("SPAWN // TITAN READY", Vector3(0.0, 0.16, pad_position.z + 3.2), Color(0.92, 0.72, 0.34), 24)

func _build_lighting() -> void:
    var center_z := BASE_CENTER.z
    for position in [Vector3(-6.5, 8.8, center_z - 5.0), Vector3(6.5, 8.8, center_z - 5.0), Vector3(0.0, 8.8, center_z + 8.0)]:
        var light := OmniLight3D.new()
        light.position = position
        light.light_color = Color(0.20, 0.62, 0.72)
        light.light_energy = 1.4
        light.omni_range = 12.0
        light.shadow_enabled = false
        add_child(light)
