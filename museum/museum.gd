extends Node3D

const Exhibit = preload("res://museum/exhibit.gd")
const Player = preload("res://museum/player.gd")

var player: Node3D
var exhibits: Array[Area3D] = []
var progress: Label3D
var information: Label3D
var hud: Label
var visited: int = 0


func _ready() -> void:
	_build_lighting()
	_build_gallery()
	_build_exhibits()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.status_changed.connect(_show_information)
	_build_hud()
	_refresh_progress()


func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
	return material


func _box(at: Vector3, size: Vector3, color: Color, solid: bool = false, glow: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color, glow)
	add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		body.position = at
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _label(text: String, at: Vector3, size: int = 48) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = Color("e0edf2")
	add_child(label)
	return label


func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("101b2b")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b6d3e5")
	settings.ambient_light_energy = 0.65
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	for x in [-3.6, 0.0, 3.6]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 3.3, -3.5)
		light.omni_range = 7.0
		light.light_energy = 1.7
		light.light_color = Color("ffe8c4")
		add_child(light)
	var entrance_light := OmniLight3D.new()
	entrance_light.position = Vector3(0, 3, 3)
	entrance_light.omni_range = 8.0
	entrance_light.light_energy = 1.5
	entrance_light.light_color = Color("b3e1ed")
	add_child(entrance_light)


func _build_gallery() -> void:
	_box(Vector3(0, -0.15, 0), Vector3(12, 0.3, 14), Color("233341"), true)
	_box(Vector3(0, 2, -7), Vector3(12, 4, 0.25), Color("142332"), true)
	_box(Vector3(0, 2, 7), Vector3(12, 4, 0.25), Color("142332"), true)
	for x in [-6.0, 6.0]:
		_box(Vector3(x, 2, 0), Vector3(0.25, 4, 14), Color("1b2d3c"), true)
		_box(Vector3(x * 0.975, 0.15, 0), Vector3(0.03, 0.04, 13.5), Color("4cc9be"), false, true)
	_box(Vector3(0, 4.1, 0), Vector3(12, 0.2, 14), Color("162330"))
	for x in [-3.6, 0.0, 3.6]:
		_box(Vector3(x, 3.98, -2), Vector3(0.08, 0.03, 9), Color("dcebf1"), false, true)
	for z in range(-6, 7, 2):
		_box(Vector3(0, 0.005, z), Vector3(11.7, 0.008, 0.012), Color("3b4c59"))
	for x in range(-4, 5, 2):
		_box(Vector3(x, 0.005, 0), Vector3(0.012, 0.008, 13.7), Color("3b4c59"))
	_label("M U S E U M   /   A F T E R   H O U R S", Vector3(0, 3.25, -6.82), 62)
	_label("A small journey through three extraordinary objects", Vector3(0, 2.83, -6.82), 28)
	progress = _label("", Vector3(0, 2.35, -6.82), 38)
	information = _label("Point at an artifact and pick it up to discover its story.", Vector3(0, 1.85, -6.82), 25)
	_label("01   /   SPACE", Vector3(-3.6, 0.8, -3.48), 28)
	_label("02   /   CRAFT", Vector3(0, 0.8, -4.78), 28)
	_label("03   /   NAVIGATION", Vector3(3.6, 0.8, -3.48), 28)
	var welcome := _label("WELCOME, EXPLORER\n\nDiscover all 3 artifacts.\nPick up, inspect, then return each one.\n\nVR: left stick moves / right stick turns\nRight trigger picks up or returns\n\nDesktop: click to look / WASD moves\nE picks up or returns / Esc frees mouse", Vector3(-5.82, 2, 2), 28)
	welcome.rotation.y = PI / 2.0
	var safety := _label("YOUR REAL ROOM COMES FIRST\n\nClear your play space.\nKeep your headset boundary enabled.\nUse the stick to explore the gallery.\nStop if movement feels uncomfortable.", Vector3(5.82, 2, 2), 28)
	safety.rotation.y = -PI / 2.0


func _build_exhibits() -> void:
	var data := [
		["Moon fragment", "Moon rocks preserve the history of our solar system.\nThis stylized model is an imaginary museum specimen.", Vector3(-3.6, 1.55, -4.0)],
		["Sun pendant", "People have used jewelry to tell stories for millennia.\nThis fictional pendant celebrates the sun.", Vector3(0, 1.55, -5.3)],
		["Explorer's compass", "A compass uses a magnetic needle to indicate direction.\nThis model invites you to imagine your next journey.", Vector3(3.6, 1.55, -4.0)],
	]
	for i in range(data.size()):
		var at: Vector3 = data[i][2]
		_box(Vector3(at.x, 0.55, at.z), Vector3(1.0, 1.1, 1.0), Color("344958"), true)
		_box(Vector3(at.x, 1.115, at.z), Vector3(1.08, 0.03, 1.08), Color("73f2df"), false, true)
		var artifact := Exhibit.new()
		artifact.name = "Exhibit%d" % (i + 1)
		artifact.title = data[i][0]
		artifact.description = data[i][1]
		artifact.kind = i
		artifact.position = at
		artifact.inspected.connect(_on_inspected)
		add_child(artifact)
		exhibits.append(artifact)


func _build_hud() -> void:
	# VR instructions stay in the world; a CanvasLayer is only used on desktop.
	if player.xr_active:
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(16, 16)
	backdrop.size = Vector2(570, 154)
	backdrop.color = Color(0.025, 0.055, 0.085, 0.9)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backdrop)
	hud = Label.new()
	hud.position = Vector2(30, 25)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7, -16)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	# Explicit viewport sizing also works when the HUD is tested headlessly.
	get_viewport().size_changed.connect(func(): crosshair.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(7, 16))
	crosshair.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(7, 16)


func _on_inspected(_exhibit: Area3D) -> void:
	visited += 1
	_refresh_progress()
	if visited == exhibits.size():
		progress.modulate = Color("73f2df")
		print("Museum tour complete: all 3 artifacts discovered.")


func _refresh_progress() -> void:
	progress.text = "DISCOVERED   %d / %d" % [visited, exhibits.size()]
	if visited == exhibits.size():
		progress.text = "TOUR COMPLETE   /   ALL 3 ARTIFACTS DISCOVERED"
	if is_instance_valid(hud):
		hud.text = "MUSEUM / AFTER HOURS    |    %d / 3 discovered\nClick to look  |  WASD to move  |  E to pick up / return\nEsc releases the mouse\nPoint the center crosshair at an artifact." % visited


func _show_information(text: String) -> void:
	information.text = text
