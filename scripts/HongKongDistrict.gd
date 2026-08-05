extends Node3D
class_name HongKongDistrict

const ROAD_HALF_WIDTH: float = 15.0
const STREET_LENGTH: float = 130.0

var _rng := RandomNumberGenerator.new()

func build(city_seed: int = 2407) -> void:
	_rng.seed = city_seed
	_build_ground()
	_build_road_details()
	_build_buildings()
	_build_street_props()
	_build_authored_combat_spaces()
	_build_lights_and_wires()

func _material(color: Color, emission_energy: float = 0.0, roughness: float = 0.82) -> StandardMaterial3D:
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
	var holder: Node3D
	if collidable:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
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
	var sign := Label3D.new()
	sign.text = text
	sign.position = position
	sign.font_size = font_size
	sign.modulate = color
	sign.outline_size = 8
	sign.outline_modulate = Color(0.01, 0.02, 0.04, 0.95)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.double_sided = true
	add_child(sign)

func _neon_box(position: Vector3, size: Vector3, color: Color, energy: float = 4.0) -> void:
	_box(position, size, color, false, energy)
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy * 0.16
	light.omni_range = maxf(size.length() * 2.4, 3.0)
	light.shadow_enabled = false
	add_child(light)

func _build_ground() -> void:
	_box(Vector3(0.0, -0.35, 0.0), Vector3(100.0, 0.7, STREET_LENGTH + 18.0), Color(0.055, 0.065, 0.075))
	_box(Vector3(0.0, 0.015, 0.0), Vector3(ROAD_HALF_WIDTH * 2.0, 0.06, STREET_LENGTH), Color(0.10, 0.105, 0.115), false)
	_box(Vector3(-20.0, 0.08, 0.0), Vector3(9.0, 0.16, STREET_LENGTH), Color(0.30, 0.30, 0.29), true)
	_box(Vector3(20.0, 0.08, 0.0), Vector3(9.0, 0.16, STREET_LENGTH), Color(0.30, 0.30, 0.29), true)
	for z in range(-60, 61, 4):
		_box(Vector3(-20.0, 0.17, float(z)), Vector3(8.5, 0.015, 0.045), Color(0.16, 0.17, 0.17), false)
		_box(Vector3(20.0, 0.17, float(z)), Vector3(8.5, 0.015, 0.045), Color(0.16, 0.17, 0.17), false)

func _build_road_details() -> void:
	var yellow := Color(0.95, 0.70, 0.08)
	_box(Vector3(-14.0, 0.055, 0.0), Vector3(0.10, 0.015, STREET_LENGTH), yellow, false, 1.6)
	_box(Vector3(14.0, 0.055, 0.0), Vector3(0.10, 0.015, STREET_LENGTH), yellow, false, 1.6)
	for z in range(-58, 61, 8):
		_box(Vector3(0.0, 0.058, float(z)), Vector3(0.12, 0.018, 3.2), Color(0.67, 0.70, 0.68), false, 0.2)
	for index in 9:
		var oil_position := Vector3(_rng.randf_range(-11.0, 11.0), 0.061, _rng.randf_range(-58.0, 58.0))
		_box(oil_position, Vector3(_rng.randf_range(0.8, 2.4), 0.012, _rng.randf_range(0.35, 1.0)), Color(0.035, 0.04, 0.05), false)
	for z in [-34.0, 34.0]:
		for lane in range(-5, 6, 2):
			_box(Vector3(float(lane), 0.07, z), Vector3(0.8, 0.022, 1.8), Color(0.74, 0.75, 0.70), false)

func _build_buildings() -> void:
	var left_blocks := [
		[-55.0, -37.0, 25.0, Color(0.36, 0.39, 0.44)],
		[-34.0, -10.0, 18.0, Color(0.48, 0.37, 0.31)],
		[-7.0, 18.0, 30.0, Color(0.32, 0.35, 0.38)],
		[21.0, 48.0, 23.0, Color(0.42, 0.31, 0.28)],
		[51.0, 66.0, 28.0, Color(0.30, 0.33, 0.38)]
	]
	var right_blocks := [
		[-58.0, -43.0, 21.0, Color(0.47, 0.38, 0.32)],
		[-40.0, -17.0, 28.0, Color(0.34, 0.37, 0.42)],
		[-14.0, 9.0, 20.0, Color(0.43, 0.34, 0.29)],
		[12.0, 36.0, 31.0, Color(0.29, 0.34, 0.40)],
		[39.0, 61.0, 24.0, Color(0.46, 0.35, 0.30)]
	]
	for block in left_blocks:
		_building(-35.5, float(block[0]), float(block[1]) - float(block[0]), float(block[2]), block[3], -1.0)
	for block in right_blocks:
		_building(35.5, float(block[0]), float(block[1]) - float(block[0]), float(block[2]), block[3], 1.0)

func _building(center_x: float, z_start: float, depth: float, height: float, color: Color, side: float) -> void:
	_box(Vector3(center_x, height * 0.5, z_start + depth * 0.5), Vector3(25.0, height, depth), color)
	_box(Vector3(center_x, height + 0.35, z_start + depth * 0.5), Vector3(25.35, 0.7, depth + 0.3), color.darkened(0.24), false)
	_box(Vector3(center_x + _rng.randf_range(-5.0, 5.0), height + 1.6, z_start + depth * 0.5), Vector3(2.8, 2.5, 2.8), Color(0.16, 0.18, 0.20), false)

	var facade_x := center_x - side * 12.56
	var floors := maxi(2, int(height / 3.0) - 1)
	var columns := maxi(2, int(depth / 3.0))
	var window_colors := [
		Color(0.05, 0.10, 0.15),
		Color(0.92, 0.57, 0.20),
		Color(0.24, 0.78, 0.88),
		Color(0.78, 0.24, 0.22),
		Color(0.75, 0.84, 0.70)
	]
	for floor in range(1, floors + 1):
		for column in range(columns):
			if (floor * 5 + column * 3) % 7 == 0:
				continue
			var window_color: Color = window_colors[(floor + column) % window_colors.size()]
			var window_y := float(floor) * 3.0 + 1.25
			var window_z := z_start + 1.5 + float(column) * (depth - 3.0) / float(maxi(columns - 1, 1))
			var window_energy := 2.0 if window_color != window_colors[0] else 0.0
			_box(Vector3(facade_x, window_y, window_z), Vector3(0.09, 1.25, 1.55), window_color, false, window_energy)
			if floor % 3 == 0 and column % 2 == 0:
				_box(Vector3(facade_x + side * 0.18, window_y - 0.7, window_z), Vector3(0.35, 0.28, 0.8), Color(0.38, 0.40, 0.42), false)

	var sign_colors: Array[Color] = [Color(1.0, 0.12, 0.20), Color(0.08, 0.86, 0.95), Color(1.0, 0.63, 0.08)]
	var sign_color: Color = sign_colors[int(absf(center_x)) % sign_colors.size()]
	_neon_box(Vector3(facade_x + side * 0.15, minf(height - 2.0, 12.0), z_start + depth * 0.55), Vector3(0.12, 2.0, minf(depth * 0.68, 10.0)), sign_color, 3.5)
	_label("MONG KOK // " + ("EAST" if side < 0.0 else "WEST"), Vector3(facade_x + side * 0.35, minf(height - 1.2, 12.5), z_start + depth * 0.55), sign_color, 42)

func _build_street_props() -> void:
	for z in [-45.0, -19.0, 7.0, 29.0, 53.0]:
		_streetlight(-17.2, z, Color(1.0, 0.62, 0.23))
		_streetlight(17.2, z + 5.0, Color(0.18, 0.80, 0.96))
	_hawker_stall(-18.0, -4.0, Color(0.96, 0.16, 0.20), "NIGHT MARKET")
	_hawker_stall(18.0, 22.0, Color(0.12, 0.85, 0.90), "HARBOUR CARGO")
	_parked_vehicle(Vector3(-7.5, 1.0, -28.0), Color(0.19, 0.24, 0.28))
	_parked_vehicle(Vector3(8.0, 1.0, 15.0), Color(0.47, 0.16, 0.12))
	_footbridge(43.0)

func _build_authored_combat_spaces() -> void:
	_market_plaza()
	_tram_intersection()
	_cargo_lane()

func _market_plaza() -> void:
	_box(Vector3(0.0, 0.095, 0.0), Vector3(24.0, 0.035, 22.0), Color(0.13, 0.11, 0.12), false)
	_box(Vector3(-10.5, 0.9, -8.0), Vector3(2.6, 1.8, 2.0), Color(0.20, 0.12, 0.12), true)
	_box(Vector3(10.5, 0.9, 8.0), Vector3(2.6, 1.8, 2.0), Color(0.10, 0.18, 0.20), true)
	_neon_box(Vector3(-10.5, 2.15, -9.05), Vector3(2.2, 0.22, 0.10), Color(1.0, 0.18, 0.12), 3.5)
	_neon_box(Vector3(10.5, 2.15, 8.95), Vector3(2.2, 0.22, 0.10), Color(0.10, 0.84, 0.94), 3.5)
	_label("CENTRAL MARKET // SIEGE PLAZA", Vector3(0.0, 0.24, -10.2), Color(1.0, 0.40, 0.18), 34)
	for position in [Vector3(-8.5, 0.85, 6.5), Vector3(8.5, 0.85, -6.5)]:
		_box(position, Vector3(1.0, 1.7, 3.0), Color(0.24, 0.25, 0.25), true)
		_box(position + Vector3(0.0, 1.15, 0.0), Vector3(1.25, 0.08, 3.25), Color(0.82, 0.22, 0.12), false, 1.2)

func _tram_intersection() -> void:
	_box(Vector3(0.0, 0.10, 32.0), Vector3(28.0, 0.04, 12.0), Color(0.16, 0.16, 0.15), false)
	for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		_box(Vector3(float(x), 0.13, 32.0), Vector3(0.16, 0.02, 11.0), Color(0.52, 0.54, 0.53), false, 0.25)
	for x in [-12.0, 12.0]:
		_box(Vector3(float(x), 1.15, 32.0), Vector3(1.1, 2.3, 3.4), Color(0.30, 0.24, 0.21), true)
		_neon_box(Vector3(float(x), 2.45, 30.25), Vector3(0.9, 0.18, 2.8), Color(1.0, 0.62, 0.10), 2.8)
	_label("TRAM LOOP // PLATFORM 02", Vector3(0.0, 0.26, 36.0), Color(0.18, 0.82, 0.92), 30)

func _cargo_lane() -> void:
	for cargo_index in 4:
		var side := -1.0 if cargo_index % 2 == 0 else 1.0
		var cargo_z := 45.0 + float(cargo_index % 2) * 6.0
		var cargo_position := Vector3(side * 10.0, 1.1, cargo_z)
		_box(cargo_position, Vector3(5.0, 2.2, 3.0), Color(0.16, 0.25, 0.28) if cargo_index % 2 == 0 else Color(0.28, 0.18, 0.18), true)
		_box(cargo_position + Vector3(0.0, 1.15, -1.55), Vector3(4.3, 0.18, 0.08), Color(0.12, 0.82, 0.88) if cargo_index % 2 == 0 else Color(0.96, 0.24, 0.10), false, 3.0)
	_label("HARBOUR CARGO // SERVICE LANE", Vector3(0.0, 0.24, 54.0), Color(1.0, 0.68, 0.18), 30)

func _streetlight(x: float, z: float, color: Color) -> void:
	_box(Vector3(x, 3.5, z), Vector3(0.20, 7.0, 0.20), Color(0.10, 0.12, 0.14), false)
	_box(Vector3(x - signf(x) * 1.1, 7.0, z), Vector3(2.2, 0.16, 0.16), Color(0.10, 0.12, 0.14), false)
	_neon_box(Vector3(x - signf(x) * 2.0, 6.75, z), Vector3(0.55, 0.22, 0.32), color, 3.0)

func _hawker_stall(x: float, z: float, color: Color, name: String) -> void:
	_box(Vector3(x, 1.1, z), Vector3(4.5, 2.2, 3.0), Color(0.18, 0.20, 0.21), true)
	_box(Vector3(x, 2.45, z), Vector3(5.3, 0.18, 3.7), color.darkened(0.32), false)
	_neon_box(Vector3(x, 2.35, z - 1.65), Vector3(3.8, 0.35, 0.10), color, 4.0)
	_label(name, Vector3(x, 2.55, z - 1.78), color, 32)

func _parked_vehicle(position: Vector3, color: Color) -> void:
	_box(position, Vector3(3.2, 1.5, 6.2), color, true)
	_box(position + Vector3(0.0, 1.1, -0.45), Vector3(2.5, 0.9, 2.4), Color(0.08, 0.12, 0.16), false)
	_box(position + Vector3(0.0, 1.0, 2.55), Vector3(2.5, 0.18, 0.12), Color(0.95, 0.20, 0.12), false, 2.0)

func _footbridge(z: float) -> void:
	_box(Vector3(0.0, 8.6, z), Vector3(57.0, 0.7, 3.0), Color(0.22, 0.25, 0.28), true)
	_box(Vector3(0.0, 10.0, z - 1.25), Vector3(57.0, 2.4, 0.18), Color(0.10, 0.13, 0.16), false)
	for x in [-25.0, -10.0, 10.0, 25.0]:
		_box(Vector3(x, 4.3, z), Vector3(0.55, 8.6, 0.55), Color(0.18, 0.20, 0.22), true)
	_neon_box(Vector3(0.0, 9.0, z - 1.58), Vector3(12.0, 0.22, 0.10), Color(1.0, 0.18, 0.32), 3.5)
	_label("HARBOUR LINE // 04", Vector3(0.0, 9.55, z - 1.8), Color(1.0, 0.44, 0.16), 38)

func _build_lights_and_wires() -> void:
	for z in [-52.0, -26.0, 0.0, 26.0, 52.0]:
		_wire(Vector3(-31.0, 13.5, z), Vector3(31.0, 13.5, z + 5.0))
		_wire(Vector3(-31.0, 14.2, z + 3.0), Vector3(31.0, 14.2, z - 2.0))

func _wire(start: Vector3, finish: Vector3) -> void:
	var middle := (start + finish) * 0.5
	middle.y -= 0.7
	var difference := finish - start
	var wire := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, difference.length())
	wire.mesh = mesh
	wire.material_override = _material(Color(0.035, 0.04, 0.045))
	add_child(wire)
	wire.look_at_from_position(middle, finish, Vector3.UP)

func signf(value: float) -> float:
	return -1.0 if value < 0.0 else 1.0
