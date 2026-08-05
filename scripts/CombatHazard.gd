extends Area3D
class_name CombatHazard

var game: Node3D
var target: Node3D
var radius: float = 5.0
var damage: float = 42.0
var warning_duration: float = 1.15
var active_duration: float = 3.2
var hazard_color: Color = Color(1.0, 0.16, 0.04)
var _warning_remaining: float = 0.0
var _active_remaining: float = 0.0
var _damage_timer: float = 0.0
var _time: float = 0.0
var _active: bool = false
var _marker: MeshInstance3D
var _light: OmniLight3D
var _marker_material: StandardMaterial3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	add_to_group("combat_hazards")
	_build_visual()
	_build_collision()

func setup(game_instance: Node3D, target_instance: Node3D, hazard_position: Vector3, hazard_radius: float = 5.0, damage_amount: float = 42.0, warning_seconds: float = 1.15, active_seconds: float = 3.2, color: Color = Color(1.0, 0.16, 0.04)) -> void:
	game = game_instance
	target = target_instance
	global_position = Vector3(hazard_position.x, 0.04, hazard_position.z)
	radius = maxf(hazard_radius, 1.0)
	damage = damage_amount
	warning_duration = maxf(warning_seconds, 0.1)
	active_duration = maxf(active_seconds, 0.1)
	hazard_color = color
	_warning_remaining = warning_duration
	_active_remaining = active_duration
	_configure_visual()

func _build_visual() -> void:
	_marker = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.06
	_marker.mesh = mesh
	_marker.position.y = 0.03
	_marker_material = StandardMaterial3D.new()
	_marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker.material_override = _marker_material
	add_child(_marker)

	_light = OmniLight3D.new()
	_light.position.y = 1.0
	_light.omni_range = 7.0
	_light.shadow_enabled = false
	add_child(_light)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 2.2
	collision.shape = shape
	collision.position.y = 1.1
	add_child(collision)

func _configure_visual() -> void:
	if _marker == null:
		return
	var mesh := _marker.mesh as CylinderMesh
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	_marker_material.albedo_color = Color(hazard_color.r, hazard_color.g, hazard_color.b, 0.34)
	_marker_material.emission_enabled = true
	_marker_material.emission = hazard_color
	_marker_material.emission_energy_multiplier = 3.0
	_light.light_color = hazard_color
	_light.light_energy = 2.0
	_light.omni_range = radius * 1.6
	var collision := get_child(get_child_count() - 1) as CollisionShape3D
	if collision != null and collision.shape is CylinderShape3D:
		(collision.shape as CylinderShape3D).radius = radius

func _process(delta: float) -> void:
	_time += delta
	if not _active:
		_warning_remaining -= delta
		var pulse := 0.88 + sin(_time * 8.0) * 0.12
		_marker.scale = Vector3(pulse, 1.0, pulse)
		_marker_material.albedo_color.a = 0.22 + pulse * 0.12
		_light.light_energy = 1.2 + pulse * 2.4
		if _warning_remaining <= 0.0:
			_active = true
			_marker.scale = Vector3.ONE
			AudioManager.play_sound(&"hazard", global_position, 1.0)
		return

	_active_remaining -= delta
	_damage_timer = maxf(_damage_timer - delta, 0.0)
	_marker_material.albedo_color.a = 0.42 + sin(_time * 14.0) * 0.12
	_light.light_energy = 3.0 + sin(_time * 14.0) * 1.0
	if target != null and is_instance_valid(target) and _damage_timer <= 0.0:
		var offset := Vector3(target.global_position.x - global_position.x, 0.0, target.global_position.z - global_position.z)
		if offset.length() <= radius and target.has_method("take_damage"):
			target.call("take_damage", damage, target.global_position)
			_damage_timer = 0.65
	if _active_remaining <= 0.0:
		queue_free()
