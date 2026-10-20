extends Area3D

signal inspected(exhibit: Area3D)

var title: String = ""
var description: String = ""
var kind: int = 0
var discovered: bool = false
var held: bool = false
var home: Transform3D
var visual: Node3D
var caption: Label3D
var time: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	home = global_transform
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	collision.shape = shape
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	_build_artifact()
	caption = Label3D.new()
	caption.text = title
	caption.position.y = 0.65
	caption.font_size = 36
	caption.pixel_size = 0.003
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.modulate = Color("b8cbd9")
	add_child(caption)


func _process(delta: float) -> void:
	time += delta
	if not held:
		visual.rotation.y += delta * 0.3
		visual.position.y = sin(time * 1.5) * 0.045


func set_focused(focused: bool) -> void:
	caption.modulate = Color("73f2df") if focused else Color("b8cbd9")


func pick_up() -> void:
	held = true
	visual.position.y = 0.0
	caption.visible = false
	if not discovered:
		discovered = true
		inspected.emit(self)


func return_to_display() -> void:
	held = false
	global_transform = home
	caption.visible = true


func _part(mesh: Mesh, color: Color, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.55
	material.roughness = 0.35
	instance.material_override = material
	visual.add_child(instance)
	return instance


func _build_artifact() -> void:
	match kind:
		0:
			var sphere := SphereMesh.new()
			sphere.radius = 0.25
			sphere.height = 0.5
			_part(sphere, Color("b6c9d8"))
			for i in range(7):
				var crater := SphereMesh.new()
				crater.radius = 0.045 + i * 0.004
				crater.height = crater.radius * 2.0
				var angle := i * 2.4
				var direction := Vector3(cos(angle), sin(angle * 0.7), sin(angle)).normalized()
				_part(crater, Color("627789"), direction * 0.22)
		1:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.12
			ring.outer_radius = 0.3
			_part(ring, Color("d9ac6a")).rotation.x = PI / 2.0
			var core := SphereMesh.new()
			core.radius = 0.12
			core.height = 0.24
			_part(core, Color("6cbed0"))
			for i in range(8):
				var bead := SphereMesh.new()
				bead.radius = 0.035
				bead.height = 0.07
				var angle := i * TAU / 8.0
				_part(bead, Color("f5dd99"), Vector3(cos(angle), sin(angle), 0) * 0.25)
		2:
			var base := CylinderMesh.new()
			base.top_radius = 0.27
			base.bottom_radius = 0.27
			base.height = 0.09
			_part(base, Color("b98d4f"))
			var dial := CylinderMesh.new()
			dial.top_radius = 0.23
			dial.bottom_radius = 0.23
			dial.height = 0.012
			_part(dial, Color("e7e4ce"), Vector3(0, 0.055, 0))
			var needle := PrismMesh.new()
			needle.size = Vector3(0.07, 0.025, 0.35)
			_part(needle, Color("c75351"), Vector3(0, 0.075, 0))
