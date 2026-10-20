extends Area3D

signal selected(door: Area3D)

var number: int = 1
var available: bool = false
var completed: bool = false
var is_open: bool = false
var title: String = ""
var leaf: Node3D
var caption: Label3D
var frame_material: StandardMaterial3D
var hint: Label3D
var opening_tween: Tween


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.55, 2.9, 0.3)
	collision.shape = shape
	collision.position = Vector3(0, 1.45, 0.25)
	add_child(collision)
	frame_material = StandardMaterial3D.new()
	frame_material.albedo_color = Color("bd9564") if available else Color("52606b")
	frame_material.emission_enabled = true
	frame_material.emission = frame_material.albedo_color
	frame_material.emission_energy_multiplier = 0.3 if available else 0.08
	_box(self, Vector3(-0.86, 1.5, 0), Vector3(0.12, 3.1, 0.28), frame_material)
	_box(self, Vector3(0.86, 1.5, 0), Vector3(0.12, 3.1, 0.28), frame_material)
	_box(self, Vector3(0, 3.02, 0), Vector3(1.84, 0.1, 0.28), frame_material)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("0b1017")
	dark.roughness = 0.6
	_box(self, Vector3(0, 1.48, -0.75), Vector3(1.65, 2.96, 0.1), dark)
	leaf = Node3D.new()
	leaf.position.x = -0.77
	add_child(leaf)
	_box(leaf, Vector3(0.77, 1.45, 0), Vector3(1.54, 2.9, 0.14), dark)
	var body := StaticBody3D.new()
	var panel_collider := CollisionShape3D.new()
	var panel_shape := BoxShape3D.new()
	panel_shape.size = Vector3(1.54, 2.9, 0.14)
	panel_collider.shape = panel_shape
	body.position = Vector3(0.77, 1.45, 0)
	body.add_child(panel_collider)
	leaf.add_child(body)
	_box(leaf, Vector3(1.25, 1.1, 0.13), Vector3(0.04, 0.35, 0.06), frame_material)
	for x in [0.2, 1.34]:
		_box(leaf, Vector3(x, 1.45, 0.09), Vector3(0.012, 2.55, 0.01), frame_material)
	caption = _label("", Vector3(0, 3.5, 0.12), 58)
	hint = _label("", Vector3(0, 0.5, 0.19), 25)
	_refresh_text()


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)


func _label(text: String, at: Vector3, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = Color("dbc29f") if available else Color("8d9da5")
	add_child(label)
	return label


func set_focused(value: bool) -> void:
	frame_material.emission_energy_multiplier = (0.8 if value else 0.3) if available else (0.25 if value else 0.08)
	if value:
		hint.text = ("Gå gennem døren" if is_open else "E / højre trigger · Åbn") if available else "Denne oplevelse kommer senere"
	else:
		_refresh_text()


func activate() -> void:
	selected.emit(self)
	if not available or is_open:
		return
	is_open = true
	opening_tween = create_tween()
	opening_tween.tween_property(leaf, "rotation:y", deg_to_rad(105.0), 1.2).set_trans(Tween.TRANS_SINE)
	_refresh_text()


func close() -> void:
	if opening_tween != null and opening_tween.is_valid():
		opening_tween.kill()
	is_open = false
	leaf.rotation.y = 0.0
	_refresh_text()


func _refresh_text() -> void:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII"]
	caption.text = numerals[number - 1]
	if available:
		hint.text = "Gå gennem døren" if is_open else ("OPLEVET · Besøg igen" if completed else title)
	else:
		hint.text = "KOMMER SENERE"
