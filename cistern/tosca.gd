extends Node3D

signal completed
signal return_requested

const G = preload("res://cistern/architecture.gd")
const Action = preload("res://cistern/interaction.gd")
const SPAWN := Vector3(0, 0.03, 1.3)
const FIGURE_HOME := Vector3(0, 0.0, -5.65)

@export_range(10.0, 120.0) var duration: float = 42.0

var active: bool = false
var running: bool = false
var finished: bool = false
var elapsed: float = 0.0
var stage: int = -1
var idle_time: float = 0.0
var start_action: Area3D
var return_action: Area3D
var story: Label3D
var figure: Node3D
var scarf: Node3D
var ribbon_parts: Array[Node3D] = []
var lantern: OmniLight3D
var wind: AudioStreamPlayer
var bell: AudioStreamPlayer


func _ready() -> void:
	_build_tower()
	_build_city()
	_build_figure()
	_build_actions()
	wind = AudioStreamPlayer.new()
	wind.stream = _wind_sound()
	wind.volume_db = -25
	add_child(wind)
	bell = AudioStreamPlayer.new()
	bell.stream = _bell_sound()
	bell.volume_db = -25
	add_child(bell)
	reset()


func _build_tower() -> void:
	var stone := G.stone(Color("8f9497"))
	var dark := G.material(Color("252c33"), 0.65)
	var brass := G.material(Color("ab8050"), 0.4, 0.5)
	G.box(self, Vector3(0, -0.22, -0.5), Vector3(8.4, 0.44, 8.4), stone, true)
	G.box(self, Vector3(0, -12.5, -0.5), Vector3(8.2, 24.5, 8.2), dark)
	for x in [-4.1, 4.1]:
		G.box(self, Vector3(x, 0.52, -0.5), Vector3(0.35, 1.04, 8.4), stone, true)
		for i in range(8):
			G.box(self, Vector3(x, 1.2, -4.2 + i * 1.05), Vector3(0.5, 0.4, 0.48), stone)
	for z in [-4.6, 3.6]:
		if z < 0:
			for side in [-1.0, 1.0]:
				G.box(self, Vector3(side * 2.75, 0.52, z), Vector3(2.9, 1.04, 0.4), stone, true)
			_build_railing(brass)
		else:
			G.box(self, Vector3(0, 0.52, z), Vector3(8.4, 1.04, 0.4), stone, true)
		for i in range(9):
			if z > 0 or absf(-4.0 + i) > 1.3:
				G.box(self, Vector3(-4.0 + i, 1.2, z), Vector3(0.48, 0.4, 0.5), stone)
	G.box(self, Vector3(0, -0.1, -5.3), Vector3(3.0, 0.2, 1.2), stone)
	for i in range(7):
		G.box(self, Vector3(0, 0.006, -3.5 + i), Vector3(7.9, 0.008, 0.012), dark)
		G.box(self, Vector3(-3 + i, 0.006, -0.5), Vector3(0.012, 0.008, 7.9), dark)
	# A solid parapet and locomotion bounds keep the viewer on the terrace.
	G.box(self, Vector3(0, 1.5, 3.35), Vector3(2.0, 3.0, 0.12), dark, true)
	G.arch(self, Vector3(0, 3.0, 3.35), 2.1, 0.65, stone)
	G.cylinder(self, Vector3(-2.6, 0.7, -2.2), 0.045, 1.4, brass)
	for y in [1.36, 1.74]:
		G.box(self, Vector3(-2.6, y, -2.2), Vector3(0.3, 0.04, 0.3), brass)
	var glass := G.material(Color("f1c68d"))
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	G.box(self, Vector3(-2.6, 1.55, -2.2), Vector3(0.2, 0.33, 0.2), glass)
	for x in [-2.73, -2.47]:
		for z in [-2.33, -2.07]:
			G.box(self, Vector3(x, 1.55, z), Vector3(0.025, 0.38, 0.025), brass)
	lantern = G.light(self, Vector3(-2.6, 1.65, -2.2), Color("edb578"), 1.5, 7)
	G.light(self, Vector3(1.7, 4.3, 0), Color("a3c1df"), 1.0, 11)
	var title := G.label(self, "II  /  TOSCA", Vector3(0, 3.6, -4.6), 72, Color("e1d0b3"), true)
	title.pixel_size = 0.005
	var subtitle := G.label(self, "FALDET  /  Giacomo Puccini\nEn fri fortolkning på en borgterrasse over Rom", Vector3(0, 3.0, -4.6), 29)
	subtitle.pixel_size = 0.004
	story = G.label(self, "Roms tage. Den første vind.\nBegynd, når du er klar.", Vector3(0, 2.35, -4.5), 43)
	story.pixel_size = 0.004


func _build_railing(surface: Material) -> void:
	for y in [0.25, 1.05]:
		G.box(self, Vector3(0, y, -4.6), Vector3(2.6, 0.045, 0.06), surface)
	for i in range(7):
		G.cylinder(self, Vector3(-1.2 + i * 0.4, 0.65, -4.6), 0.018, 0.85, surface)
	# An invisible collision panel closes the gaps between the visible bars.
	var barrier := StaticBody3D.new()
	barrier.position = Vector3(0, 1.0, -4.6)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 2.0, 0.16)
	collision.shape = shape
	barrier.add_child(collision)
	add_child(barrier)


func _build_city() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 1800
	var buildings := G.material(Color("253443"), 0.9)
	var roofs := G.material(Color("3b3840"), 0.8)
	var windows := G.material(Color("bfa178"))
	windows.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	G.box(self, Vector3(0, -28, -35), Vector3(120, 1, 110), G.material(Color("19222c")))
	for row in range(4):
		for column in range(11):
			var x := (column - 5) * 6.5 + random.randf_range(-1.5, 1.5)
			var z := -14.0 - row * 10.0 + random.randf_range(-2, 2)
			var height := random.randf_range(6, 16) if row == 0 else random.randf_range(15, 30)
			var width := random.randf_range(3.5, 5.5)
			G.box(self, Vector3(x, -27 + height / 2, z), Vector3(width, height, 5), buildings)
			var roof := MeshInstance3D.new()
			var mesh := PrismMesh.new()
			mesh.size = Vector3(width + 0.4, 1.6, 5.4)
			roof.mesh = mesh
			roof.material_override = roofs
			roof.position = Vector3(x, -26.2 + height, z)
			add_child(roof)
			for light in range(2):
				G.box(self, Vector3(x - 0.7 + light * 1.4, -29 + height, z + 2.51), Vector3(0.18, 0.35, 0.02), windows)
	var dome := MeshInstance3D.new()
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 4
	dome_mesh.height = 8
	dome.mesh = dome_mesh
	dome.material_override = buildings
	dome.position = Vector3(-15, 0.5, -39)
	add_child(dome)
	G.cylinder(self, Vector3(-15, -7, -39), 4.2, 15, buildings)
	G.cylinder(self, Vector3(-15, 5.5, -39), 0.3, 2.5, roofs)
	var moon := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.1
	sphere.height = 4.2
	moon.mesh = sphere
	moon.position = Vector3(18, 12, -55)
	var moon_surface := G.material(Color("9cabbc"))
	moon_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon.material_override = moon_surface
	add_child(moon)


func _build_figure() -> void:
	figure = Node3D.new()
	figure.name = "ToscaSilhouette"
	figure.position = FIGURE_HOME
	add_child(figure)
	var red := G.material(Color("7f2536"), 0.85)
	var shadow := G.material(Color("2d2630"))
	var gown := MeshInstance3D.new()
	var dress := CylinderMesh.new()
	dress.top_radius = 0.16
	dress.bottom_radius = 0.39
	dress.height = 1.3
	gown.mesh = dress
	gown.material_override = red
	gown.position.y = 0.7
	figure.add_child(gown)
	G.cylinder(figure, Vector3(0, 1.42, 0), 0.18, 0.42, red)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.28
	head.mesh = sphere
	head.material_override = shadow
	head.position.y = 1.8
	figure.add_child(head)
	for side in [-1.0, 1.0]:
		var arm := G.cylinder(figure, Vector3(side * 0.27, 1.27, 0), 0.045, 0.6, red)
		arm.rotation.z = side * 0.35
	scarf = Node3D.new()
	scarf.name = "FallingScarf"
	add_child(scarf)
	for i in range(9):
		var part := G.box(scarf, Vector3(0, -i * 0.14, 0), Vector3(0.27, 0.17, 0.018), red)
		ribbon_parts.append(part)
	G.light(self, Vector3(0, 3, -5.7), Color("c9d5ed"), 0.85, 5)


func _build_actions() -> void:
	start_action = Action.new()
	start_action.name = "BeginTosca"
	start_action.position = Vector3(0, 1.25, -2.7)
	start_action.activated.connect(start)
	add_child(start_action)
	return_action = Action.new()
	return_action.name = "ReturnFromTosca"
	return_action.position = Vector3(0, 1.5, 3.15)
	return_action.rotation.y = PI
	return_action.prompt = "TILBAGE TIL LOBBYEN\nE / trigger · eller R / B"
	return_action.activated.connect(func(): return_requested.emit())
	add_child(return_action)


func enter_room() -> void:
	reset()
	active = true
	wind.volume_db = -25
	wind.play()


func exit_room() -> void:
	active = false
	running = false
	wind.stop()
	bell.stop()


func reset() -> void:
	running = false
	finished = false
	elapsed = 0
	stage = -1
	figure.position = FIGURE_HOME
	figure.rotation = Vector3.ZERO
	figure.visible = true
	scarf.position = FIGURE_HOME + Vector3(0.3, 1.6, 0.1)
	scarf.visible = true
	lantern.light_energy = 1.5
	story.text = "Roms tage. Den første vind.\nBegynd, når du er klar."
	start_action.enabled = true
	start_action.set_prompt("E / højre trigger\nBEGYND TOSCA · ca. 42 sek.")
	bell.stop()


func start() -> void:
	if not active or running:
		return
	reset()
	running = true
	start_action.enabled = false
	start_action.set_prompt("Se gennem rækværket mod skikkelsen.\nR / B · tilbage når som helst")
	bell.play()
	advance(0)


func _process(delta: float) -> void:
	if not active:
		return
	idle_time += delta
	if running:
		advance(delta)
	for i in range(ribbon_parts.size()):
		ribbon_parts[i].position.x = sin(idle_time * 1.7 - i * 0.55) * (0.025 + i * 0.012)
		ribbon_parts[i].rotation.z = sin(idle_time * 1.7 - i * 0.55) * 0.16


func advance(delta: float) -> void:
	if not running:
		return
	elapsed = minf(elapsed + maxf(delta, 0), duration)
	var amount := clampf(elapsed / maxf(duration, 0.01), 0, 1)
	var next_stage := 0
	if amount >= 1.0:
		next_stage = 4
	elif amount >= 0.82:
		next_stage = 3
	elif amount >= 0.58:
		next_stage = 2
	elif amount >= 0.25:
		next_stage = 1
	if next_stage != stage:
		stage = next_stage
		var lines := [
			"Højt over Rom.\nEt navn bliver til et ekko.",
			"Et øjeblik på kanten.\nVinden tager fat i det røde stof.",
			"Skikkelsen forlader muren.\nSe ned gennem rækværket.",
			"Tårnet står tilbage.\nKun vinden svarer.",
			"Faldet er forbi.\nEt tomrum over byen.",
		]
		story.text = lines[stage]
	var fall := clampf((amount - 0.58) / 0.24, 0, 1)
	# The figure falls through the set; the viewer's camera remains on the terrace.
	figure.position = FIGURE_HOME + Vector3(0, -25 * fall * fall, -fall * 1.5)
	figure.rotation = Vector3(-fall * 0.45, 0, fall * 0.3)
	figure.visible = fall < 1.0
	scarf.position = FIGURE_HOME + Vector3(0.3 + fall * 1.2, 1.6 - 7 * fall * fall, 0.1 - fall * 0.5)
	scarf.visible = amount < 0.97
	lantern.light_energy = lerpf(1.5, 0.5, amount)
	wind.volume_db = lerpf(-25.0, -17.0, sin(amount * PI))
	if amount >= 1.0:
		running = false
		finished = true
		wind.volume_db = -30
		start_action.enabled = true
		start_action.set_prompt("TOSCA ER OPLEVET\nE / trigger · Oplev igen\nR / B · Vend tilbage")
		completed.emit()
		print("Seven Doors: Tosca completed.")


func _wind_sound() -> AudioStreamWAV:
	const RATE := 22050
	var data := PackedByteArray()
	var count := RATE * 8
	data.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 1800
	var smooth := 0.0
	for i in range(count):
		var time := float(i) / RATE
		smooth = lerpf(smooth, random.randf_range(-1, 1), 0.07)
		var envelope := 0.5 + 0.5 * pow(sin(PI * time / 8.0), 2)
		# Fade the loop seam into silence to avoid a click.
		var seam := minf(1.0, minf(time, 8.0 - time) * 10.0)
		data.encode_s16(i * 2, int(smooth * envelope * seam * 22000))
	return _wav(data, RATE, true)


func _bell_sound() -> AudioStreamWAV:
	const RATE := 22050
	var data := PackedByteArray()
	data.resize(RATE * 4 * 2)
	for i in range(RATE * 4):
		var time := float(i) / RATE
		var tone := sin(TAU * 220 * time) + sin(TAU * 553 * time) * 0.25
		var envelope := exp(-time * 1.7) * minf(time * 40, 1)
		data.encode_s16(i * 2, int(tone * envelope * 15000))
	return _wav(data, RATE, false)


func _wav(data: PackedByteArray, rate: int, loop: bool) -> AudioStreamWAV:
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = rate
	result.data = data
	if loop:
		result.loop_mode = AudioStreamWAV.LOOP_FORWARD
		result.loop_end = data.size() / 2
	return result


func _exit_tree() -> void:
	for source in [wind, bell]:
		if is_instance_valid(source):
			source.stop()
			source.stream = null
