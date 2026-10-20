extends RefCounted


static func material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


static func stone(color: Color) -> StandardMaterial3D:
	var result := material(color)
	var noise := FastNoiseLite.new()
	noise.seed = 711
	noise.frequency = 0.035
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color("a4a4a4"))
	ramp.set_color(1, Color("dfdfdf"))
	texture.color_ramp = ramp
	result.albedo_texture = texture
	result.uv1_scale = Vector3(1, 1, 1)
	return result


static func box(parent: Node3D, at: Vector3, size: Vector3, surface: Material, solid: bool = false, yaw: float = 0.0) -> Node3D:
	var group := Node3D.new()
	group.position = at
	group.rotation.y = yaw
	parent.add_child(group)
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = surface
	group.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		group.add_child(body)
	return group


static func label(parent: Node3D, text: String, at: Vector3, size: int = 38, color: Color = Color("d6c9b3"), serif: bool = false) -> Label3D:
	var result := Label3D.new()
	result.text = text
	result.position = at
	result.font_size = size
	result.pixel_size = 0.003
	result.modulate = color
	result.outline_size = 5
	result.outline_modulate = Color("080b10")
	if serif:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "Times New Roman"])
		result.font = font
	parent.add_child(result)
	return result


static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, surface: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = surface
	parent.add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
	return instance


static func half_disc(parent: Node3D, center: Vector3, radius: float, surface: Material, ceiling: bool = false) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(90):
		var a := -PI / 2.0 + i * PI / 90.0
		var b := a + PI / 90.0
		var points := [Vector3.ZERO, Vector3(sin(b), 0, -cos(b)) * radius, Vector3(sin(a), 0, -cos(a)) * radius]
		if ceiling:
			points.reverse()
		for point in points:
			builder.set_normal(Vector3.DOWN if ceiling else Vector3.UP)
			builder.set_uv(Vector2(point.x, point.z) * 0.2)
			builder.add_vertex(point)
	var instance := MeshInstance3D.new()
	instance.mesh = builder.commit()
	instance.material_override = surface
	instance.position = center
	parent.add_child(instance)


static func arch(parent: Node3D, at: Vector3, width: float, rise: float, surface: Material, yaw: float = 0.0) -> void:
	var group := Node3D.new()
	group.position = at
	group.rotation.y = yaw
	parent.add_child(group)
	for i in range(16):
		var a := PI * float(i) / 16.0
		var b := PI * float(i + 1) / 16.0
		var start := Vector3(cos(a) * width / 2.0, sin(a) * rise, 0)
		var end := Vector3(cos(b) * width / 2.0, sin(b) * rise, 0)
		var segment := cylinder(group, (start + end) / 2.0, 0.105, start.distance_to(end) + 0.015, surface)
		segment.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


static func light(parent: Node3D, at: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var result := OmniLight3D.new()
	result.position = at
	result.light_color = color
	result.light_energy = energy
	result.omni_range = reach
	parent.add_child(result)
	return result
