extends Node3D

signal completed
signal return_requested

const G = preload("res://cistern/architecture.gd")
const Action = preload("res://cistern/interaction.gd")
const SPAWN := Vector3(0, 0.03, 1.3)
const EDGE_FEET := Vector3(0, 0.03, -5.65)

@export_range(3.0, 30.0) var intro_duration: float = 10.0
@export_range(2.0, 8.0) var fall_duration: float = 4.8
@export_range(2.0, 8.0) var outro_duration: float = 3.0

var active: bool = false
var running: bool = false
var finished: bool = false
var elapsed: float = 0.0
var stage: int = -1
var idle_time: float = 0.0
var start_action: Area3D
var return_action: Area3D
var story: Label3D
var scarf: Node3D
var ribbon_parts: Array[Node3D] = []
var lantern: OmniLight3D
var wind: AudioStreamPlayer
var bell: AudioStreamPlayer
var player: Node3D
var fade_surface: StandardMaterial3D
var fall_action: Area3D
var mode_action: Area3D
var gentle_fall: bool = false
var state: String = "ready"
var state_elapsed: float = 0.0
var step_offset := Vector3.ZERO


func _ready() -> void:
	_build_tower()
	_build_city()
	_build_scarf()
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
	story = G.label(self, "Du er Tosca. Roms tage ligger under dig.\nBegynd, når du er klar.", Vector3(0, 2.35, -4.5), 43)
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


func _build_scarf() -> void:
	var red := G.material(Color("7f2536"), 0.85)
	scarf = Node3D.new()
	scarf.name = "PlayerScarf"
	add_child(scarf)
	for i in range(9):
		var part := G.box(scarf, Vector3(0, -i * 0.14, 0), Vector3(0.2, 0.17, 0.018), red)
		ribbon_parts.append(part)


func _build_actions() -> void:
	start_action = Action.new()
	start_action.name = "BeginTosca"
	start_action.position = Vector3(0, 1.25, -2.7)
	start_action.activated.connect(start)
	add_child(start_action)
	fall_action = Action.new()
	fall_action.name = "ConfirmFirstPersonFall"
	fall_action.position = Vector3(0, 1.25, -4.05)
	fall_action.prompt = "E / højre trigger · BEGYND FALDET\nR / B · tilbage når som helst"
	fall_action.activated.connect(confirm_fall)
	add_child(fall_action)
	mode_action = Action.new()
	mode_action.name = "FallComfortMode"
	mode_action.position = Vector3(-2.1, 1.4, -1.2)
	mode_action.rotation.y = 0.35
	mode_action.activated.connect(toggle_fall_mode)
	add_child(mode_action)
	mode_action.caption.font_size = 26
	return_action = Action.new()
	return_action.name = "ReturnFromTosca"
	return_action.position = Vector3(0, 1.5, 3.15)
	return_action.rotation.y = PI
	return_action.prompt = "TILBAGE TIL LOBBYEN\nE / trigger · eller R / B"
	return_action.activated.connect(func(): return_requested.emit())
	add_child(return_action)


func bind_view(viewer: Node3D, surface: StandardMaterial3D) -> void:
	player = viewer
	fade_surface = surface


func enter_room() -> void:
	reset()
	active = true
	wind.volume_db = -25
	wind.play()


func suspend_for_transition() -> void:
	active = false
	running = false
	wind.stop()
	bell.stop()


func exit_room() -> void:
	suspend_for_transition()
	if is_instance_valid(player):
		player.end_sequence_motion()


func _action(action: Area3D, enabled: bool) -> void:
	action.enabled = enabled
	action.visible = enabled
	action.collision_layer = 2 if enabled else 0


func reset() -> void:
	running = false
	finished = false
	elapsed = 0
	state_elapsed = 0
	stage = -1
	state = "ready"
	scarf.visible = false
	lantern.light_energy = 1.5
	story.text = "Du er Tosca. Roms tage ligger under dig.\nBegynd, når du er klar."
	_action(start_action, true)
	_action(fall_action, false)
	fall_action.set_prompt("E / højre trigger · BEGYND FALDET\nR / B · tilbage når som helst")
	_action(mode_action, true)
	start_action.set_prompt("E / højre trigger\nBEGYND TOSCA · i første person")
	_update_mode_prompt()
	bell.stop()


func _update_mode_prompt() -> void:
	mode_action.set_prompt("FALD: " + ("KORT" if gentle_fall else "FULDT") + "\nE / trigger · Skift\nSynsfeltet bevæger sig\nunder faldet")


func toggle_fall_mode() -> void:
	if active and not running:
		gentle_fall = not gentle_fall
		_update_mode_prompt()


func start() -> void:
	if not active or running or not is_instance_valid(player):
		return
	reset()
	running = true
	state = "intro"
	_action(start_action, false)
	_action(mode_action, false)
	bell.play()
	_update_intro()


func _update_intro() -> void:
	stage = 0 if state_elapsed < intro_duration * 0.5 else 1
	story.text = "Du står højt over Rom.\nVinden griber dit tøj." if stage == 0 else "Du nærmer dig kanten.\nEt øjeblik mellem himmel og jord."


func confirm_fall() -> void:
	if not active or state != "awaiting_fall" or not is_instance_valid(player):
		return
	var at := to_local(player.viewer_position())
	if Vector2(at.x, at.z + 4.1).length() > 2.0:
		fall_action.set_prompt("Kom tættere på kanten\nE / trigger · Begynd faldet")
		return
	state = "falling"
	state_elapsed = 0
	stage = 2
	_action(fall_action, false)
	var destination := to_global(EDGE_FEET)
	var view: Vector3 = player.viewer_position()
	step_offset = Vector3(destination.x - view.x, 0, destination.z - view.z)
	player.begin_sequence_motion()
	player.interaction_enabled = false
	scarf.visible = true
	_update_fall()


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
	if not active or not running:
		return
	var remaining := maxf(delta, 0)
	# Time can pass through the fall/outro, but never through the confirmation gate.
	while remaining > 0 and running:
		if state == "awaiting_fall":
			return
		var limit := intro_duration
		if state == "falling":
			limit = fall_duration
		elif state == "ending":
			limit = outro_duration
		var consumed := minf(remaining, maxf(0, limit - state_elapsed))
		state_elapsed += consumed
		elapsed += consumed
		remaining -= consumed
		if state == "intro":
			_update_intro()
			if state_elapsed >= limit:
				state = "awaiting_fall"
				state_elapsed = 0
				story.text = "Gå hen til kanten med stick / WASD.\nBekræft med E / trigger, når du er klar."
				_action(fall_action, true)
		elif state == "falling":
			_update_fall()
			if state_elapsed >= limit:
				_set_fade(1)
				player.end_sequence_motion()
				player.locomotion_enabled = false
				scarf.visible = false
				state = "ending"
				state_elapsed = 0
				stage = 3
				story.text = "Faldet er forbi.\nEt sidste ekko over byen."
		elif state == "ending":
			_set_fade(1.0 - smoothstep(0.8, outro_duration, state_elapsed))
			if state_elapsed >= limit:
				_finish()
		else:
			return


func _update_fall() -> void:
	var step := smoothstep(0, 0.7, state_elapsed)
	var progress := clampf((state_elapsed - 0.7) / (fall_duration - 0.7), 0, 1)
	var distance := 4.0 if gentle_fall else 25.0
	player.set_sequence_offset(step_offset * step + Vector3(0, -distance * progress * progress, 0))
	# Local head tracking and mouse look remain live; the rig translates without rolling.
	scarf.position = to_local(player.viewer_position()) + Vector3(0.35, -0.6, -0.5)
	wind.volume_db = lerpf(-25.0, -13.0, progress)
	if gentle_fall:
		_set_fade(smoothstep(0.25, 0.65, progress))
	else:
		_set_fade(smoothstep(0.75, 0.98, progress))


func _set_fade(value: float) -> void:
	if fade_surface != null:
		var color := fade_surface.albedo_color
		color.a = clampf(value, 0, 1)
		fade_surface.albedo_color = color


func _finish() -> void:
	_set_fade(0)
	running = false
	finished = true
	state = "complete"
	stage = 4
	player.locomotion_enabled = true
	player.interaction_enabled = true
	wind.volume_db = -30
	_action(start_action, true)
	_action(mode_action, true)
	start_action.set_prompt("DU HAR OPLEVET TOSCAS FALD\nE / trigger · Oplev igen\nR / B · Vend tilbage")
	completed.emit()
	print("Seven Doors: first-person Tosca completed.")


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
