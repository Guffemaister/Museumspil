extends Node3D

const G = preload("res://cistern/architecture.gd")
const Door = preload("res://cistern/door.gd")
const Action = preload("res://cistern/interaction.gd")
const Soundscape = preload("res://cistern/soundscape.gd")
const Player = preload("res://museum/player.gd")
const RADIUS: float = 8.5
const CENTER := Vector3(0, 0, 2)
const CHAMBER := Vector3(30, 0, 0)
const LOBBY_SPAWN := Vector3(0, 0.03, 0.9)
const DOOR_STORIES := [
	["La traviata", "Tæring / tuberkulose"],
	["Tosca", "Fald fra et tårn"],
	["Otello", "Kvælning"],
	["Madame Butterfly", "Rituelt selvmord (hara-kiri)"],
	["Carmen", "Knivstik"],
	["Lucia di Lammermoor", "Vanvid / sindssyge"],
	["Norma", "Brændt på bålet"],
]

@export var experience_duration: float = 48.0
@export var transition_duration: float = 0.5

var player: Node3D
var doors: Array[Area3D] = []
var current_space: String = "lobby"
var transitioning: bool = false
var experience_running: bool = false
var experience_complete: bool = false
var experience_elapsed: float = 0.0
var sequence_stage: int = -1
var chamber: Node3D
var lobby: Node3D
var story: Label3D
var chamber_subtitle: Label3D
var start_action: Area3D
var return_action: Area3D
var candle: OmniLight3D
var flame: MeshInstance3D
var chamber_light: OmniLight3D
var hud_prompt: Label
var hud_location: Label
var desktop_hud: CanvasLayer
var fade_material: StandardMaterial3D
var sound: Node
var ripples: Array[MeshInstance3D] = []
var idle_time: float = 0.0


func _ready() -> void:
	_build_environment()
	lobby = Node3D.new()
	lobby.name = "Lobby"
	add_child(lobby)
	_build_lobby()
	_build_doors()
	_build_chamber()
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.xr_movement_constraint = _constrain_xr
	player.return_requested.connect(return_to_lobby)
	player.relocate(LOBBY_SPAWN, deg_to_rad(30))
	_build_fade()
	_build_hud()
	sound = Soundscape.new()
	add_child(sound)
	print("Seven Doors: lobby ready; door I is playable.")


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("070b10")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a1b4c5")
	environment.ambient_light_energy = 0.44
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("18212a")
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)


func _build_lobby() -> void:
	var masonry := G.stone(Color("87918c"))
	var black_stone := G.material(Color("1e272b"))
	var wet := G.material(Color("15252c"), 0.13, 0.65)
	G.half_disc(lobby, CENTER + Vector3(0, -0.005, 0), RADIUS, wet)
	G.half_disc(lobby, CENTER + Vector3(0, 4.85, 0), RADIUS, black_stone, true)
	# The floor collision is flat so no stepping or jumping is needed in VR.
	var floor_body := StaticBody3D.new()
	var floor_collider := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(18, 0.3, 11)
	floor_collider.shape = floor_shape
	floor_body.position = Vector3(0, -0.15, -3)
	floor_body.add_child(floor_collider)
	lobby.add_child(floor_body)
	for i in range(90):
		var angle := -PI / 2.0 + (i + 0.5) * PI / 90.0
		var at := CENTER + Vector3(sin(angle), 0, -cos(angle)) * RADIUS
		var doorway := false
		for j in range(7):
			if absf(angle - _door_angle(j)) < deg_to_rad(6.3):
				doorway = true
		if doorway:
			G.box(lobby, at + Vector3(0, 4.05, 0), Vector3(0.32, 1.6, 0.38), masonry, true, -angle)
		else:
			G.box(lobby, at + Vector3(0, 2.4, 0), Vector3(0.32, 4.8, 0.38), masonry, true, -angle)
	G.box(lobby, Vector3(0, 2.4, 2.12), Vector3(17.4, 4.8, 0.25), masonry, true)
	G.box(lobby, Vector3(0, 1.4, 1.94), Vector3(2.0, 2.8, 0.12), black_stone)
	var exit_title := G.label(lobby, "C I S T E R N E R N E", Vector3(0, 3.35, 1.85), 40)
	exit_title.rotation.y = PI
	G.label(lobby, "S E V E N   D E A T H S", Vector3(0, 4.05, -4.65), 86, Color("dfd0b5"), true)
	G.label(lobby, "S Y V   D Ø R E   /   S Y V   A F S L U T N I N G E R", Vector3(0, 3.65, -4.65), 27)
	for degrees in [-55.0, -18.0, 18.0, 55.0]:
		var a := deg_to_rad(degrees)
		var at := CENTER + Vector3(sin(a), 0, -cos(a)) * 5.0
		G.box(lobby, at + Vector3(0, 0.12, 0), Vector3(0.68, 0.24, 0.68), black_stone, true)
		G.cylinder(lobby, at + Vector3(0, 2.1, 0), 0.19, 4.2, masonry, true)
		G.box(lobby, at + Vector3(0, 4.2, 0), Vector3(0.65, 0.18, 0.65), black_stone)
		G.arch(lobby, at + Vector3(0, 3.8, 0), 3.3, 0.85, masonry, -a)
		G.light(lobby, at + Vector3(0, 2.6, 0.4), Color("91b5c7"), 0.55, 5)
	var path := G.material(Color("354348"), 0.55)
	for i in range(55):
		var angle := -PI / 2.0 + (i + 0.5) * PI / 55.0
		var at := CENTER + Vector3(sin(angle), 0, -cos(angle)) * 6.6
		G.box(lobby, at + Vector3(0, 0.003, 0), Vector3(0.35, 0.012, 1.45), path, false, -angle)
	var brass := G.material(Color("af8650"), 0.35, 0.6)
	var destination := CENTER + Vector3(sin(_door_angle(0)), 0, -cos(_door_angle(0))) * 7.4
	for i in range(1, 15):
		var at := LOBBY_SPAWN.lerp(destination, float(i) / 15.0)
		at.y = 0.018
		G.cylinder(lobby, at, 0.025, 0.012, brass)
	var welcome := Node3D.new()
	welcome.position = Vector3(2.5, 0, -0.3)
	welcome.rotation.y = deg_to_rad(-35)
	lobby.add_child(welcome)
	G.box(welcome, Vector3(0, 0.58, 0), Vector3(2.6, 1.16, 0.22), black_stone, true)
	G.label(welcome, "FØLG DET VARME LYS MOD DØR I\n\nÅbn døren. Gå over tærsklen.\nTag dig tid.", Vector3(0, 1.2, 0.17), 31)
	G.label(welcome, "Et selvstændigt VR-studie inspireret af\nMarina Abramović: Seven Deaths", Vector3(0, 0.63, 0.17), 21, Color("8d9b9f"))
	G.label(welcome, "VR: venstre stick · gå / højre stick · drej\nHøjre trigger · vælg / B · retur", Vector3(0, 0.32, 0.17), 20, Color("aab9be"))
	G.light(lobby, Vector3(0, 3.4, 0), Color("97acb7"), 0.65, 8)
	for i in range(5):
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.48
		mesh.outer_radius = 0.5
		ring.mesh = mesh
		ring.material_override = G.material(Color("334b54"), 0.2, 0.6)
		ring.position = Vector3(-3.1 + i * 1.4, 0.014, -3.5 - sin(i * 1.3))
		lobby.add_child(ring)
		ripples.append(ring)


func _door_angle(index: int) -> float:
	return deg_to_rad(-66.0 + index * 22.0)


func _build_doors() -> void:
	var stone := G.stone(Color("a0a49a"))
	for i in range(7):
		var angle := _door_angle(i)
		var at := CENTER + Vector3(sin(angle), 0, -cos(angle)) * (RADIUS - 0.08)
		var door := Door.new()
		door.name = "Door%d" % (i + 1)
		door.number = i + 1
		door.available = i == 0
		door.title = DOOR_STORIES[i][0]
		door.theme = DOOR_STORIES[i][1]
		door.position = at
		door.rotation.y = -angle
		door.selected.connect(_on_door_selected)
		lobby.add_child(door)
		doors.append(door)
		G.arch(lobby, at + Vector3(0, 3.03, 0), 2.0, 0.95, stone, -angle)
		var inward := Vector3(-sin(angle), 0, cos(angle))
		G.light(lobby, at + inward * 0.65 + Vector3(0, 2.5, 0), Color("f3bd77") if i == 0 else Color("7796ab"), 1.8 if i == 0 else 0.45, 4)


func _build_chamber() -> void:
	chamber = Node3D.new()
	chamber.name = "FirstDeath"
	chamber.position = CHAMBER
	add_child(chamber)
	var stone := G.stone(Color("8d918b"))
	var dark := G.material(Color("171d24"))
	var linen := G.material(Color("b6b2a1"), 0.95)
	var wood := G.material(Color("352a25"))
	G.box(chamber, Vector3(0, -0.15, -1), Vector3(8, 0.3, 8), G.material(Color("283337"), 0.25), true)
	G.box(chamber, Vector3(0, 2.4, -5), Vector3(8, 4.8, 0.3), stone, true)
	G.box(chamber, Vector3(0, 2.4, 3), Vector3(8, 4.8, 0.3), stone, true)
	for x in [-4.0, 4.0]:
		G.box(chamber, Vector3(x, 2.4, -1), Vector3(0.3, 4.8, 8), stone, true)
	G.box(chamber, Vector3(0, 4.85, -1), Vector3(8, 0.2, 8), dark)
	for z in [-3.5, 0.5]:
		G.arch(chamber, Vector3(0, 3.55, z), 7.6, 1.1, stone)
	G.box(chamber, Vector3(0, 0.38, -2.55), Vector3(1.5, 0.45, 2.6), wood, true)
	G.box(chamber, Vector3(0, 0.66, -2.55), Vector3(1.48, 0.14, 2.55), linen)
	G.box(chamber, Vector3(0, 0.79, -3.35), Vector3(0.95, 0.18, 0.47), linen)
	G.box(chamber, Vector3(0, 0.98, -3.88), Vector3(1.55, 1.2, 0.1), wood)
	for x in [-0.65, 0.65]:
		for z in [-3.6, -1.5]:
			G.box(chamber, Vector3(x, 0.19, z), Vector3(0.1, 0.38, 0.1), wood)
	# An empty bed and curtain suggest absence without depicting a body.
	G.box(chamber, Vector3(1.2, 0.45, -2.65), Vector3(0.65, 0.9, 0.65), wood, true)
	G.cylinder(chamber, Vector3(1.2, 0.98, -2.65), 0.13, 0.05, G.material(Color("8d7253"), 0.3, 0.6))
	G.cylinder(chamber, Vector3(1.2, 1.15, -2.65), 0.045, 0.3, G.material(Color("d9c8a5")))
	flame = MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.025
	flame_mesh.height = 0.1
	flame.mesh = flame_mesh
	flame.position = Vector3(1.2, 1.35, -2.65)
	var flame_surface := G.material(Color("ffd095"))
	flame_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.material_override = flame_surface
	chamber.add_child(flame)
	candle = G.light(chamber, Vector3(1.2, 1.5, -2.65), Color("ffc284"), 1.5, 5)
	chamber_light = G.light(chamber, Vector3(-1.5, 3.3, -1), Color("9bacbf"), 0.8, 7)
	G.box(chamber, Vector3(-2.5, 2.35, -4.77), Vector3(1.2, 2.1, 0.05), G.material(Color("314550"), 0.3))
	for x in [-3.15, -2.5, -1.85]:
		G.box(chamber, Vector3(x, 2.35, -4.7), Vector3(0.035, 2.3, 0.06), wood)
	G.box(chamber, Vector3(-2.5, 2.35, -4.7), Vector3(1.4, 0.035, 0.06), wood)
	for i in range(10):
		G.box(chamber, Vector3(2.7 + sin(i * 0.6) * 0.05, 2.2, -4.6 + i * 0.25), Vector3(0.035, 3.5, 0.3), G.material(Color("383b3c")))
	var title := G.label(chamber, "I  /  DET SIDSTE ÅNDEDRAG", Vector3(0, 3.45, -4.76), 64, Color("e3ceb1"), true)
	title.pixel_size = 0.004
	chamber_subtitle = G.label(chamber, "En fri fortolkning af Violettas sidste øjeblikke\nfra Verdis La traviata", Vector3(0, 3.02, -4.76), 26)
	chamber_subtitle.pixel_size = 0.004
	story = G.label(chamber, "Et rum. En seng. Et lys.\nBegynd, når du er klar.", Vector3(0, 2.3, -4.7), 48)
	story.pixel_size = 0.004
	start_action = Action.new()
	start_action.name = "BeginExperience"
	start_action.position = Vector3(0, 1.2, -1.05)
	start_action.prompt = "E / højre trigger\nBEGYND OPLEVELSEN · ca. 48 sek."
	start_action.activated.connect(start_experience)
	chamber.add_child(start_action)
	return_action = Action.new()
	return_action.name = "ReturnToLobby"
	return_action.position = Vector3(0, 1.5, 2.73)
	return_action.rotation.y = PI
	return_action.prompt = "TILBAGE TIL LOBBYEN\nE / trigger · eller R / B"
	return_action.activated.connect(return_to_lobby)
	chamber.add_child(return_action)
	G.box(chamber, Vector3(0, 1.5, 2.83), Vector3(1.9, 3.0, 0.08), dark)
	G.light(chamber, Vector3(0, 2.2, 2.3), Color("95b9c5"), 0.6, 4)


func _build_fade() -> void:
	fade_material = G.material(Color(0, 0, 0, 0))
	fade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fade_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fade_material.cull_mode = BaseMaterial3D.CULL_FRONT
	fade_material.no_depth_test = true
	fade_material.render_priority = 127
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.25
	mesh.height = 0.5
	sphere.mesh = mesh
	sphere.material_override = fade_material
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var camera: Camera3D = player.head if player.xr_active else player.camera
	camera.add_child(sphere)


func _build_hud() -> void:
	if player.xr_active:
		return
	var layer := CanvasLayer.new()
	desktop_hud = layer
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(24, 22)
	panel.size = Vector2(440, 100)
	panel.color = Color(0.025, 0.035, 0.045, 0.86)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud_location = Label.new()
	hud_location.position = Vector2(38, 30)
	hud_location.add_theme_font_size_override("font_size", 22)
	hud_location.add_theme_color_override("font_color", Color("ddc8a7"))
	hud_location.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_location)
	var controls := Label.new()
	controls.position = Vector2(38, 66)
	controls.text = "Klik: se dig omkring  ·  WASD: gå  ·  E: vælg\nEsc: slip musen  ·  R: tilbage til lobbyen"
	controls.add_theme_font_size_override("font_size", 15)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(controls)
	hud_prompt = Label.new()
	hud_prompt.add_theme_font_size_override("font_size", 20)
	hud_prompt.add_theme_color_override("font_color", Color("ead7b8"))
	hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_prompt)
	var reticle := Label.new()
	reticle.text = "·"
	reticle.add_theme_font_size_override("font_size", 32)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(reticle)
	var resize := func():
		var size := get_viewport().get_visible_rect().size
		hud_prompt.position = Vector2(0, size.y - 75)
		hud_prompt.size.x = size.x
		reticle.position = size / 2.0 - Vector2(4, 22)
	get_viewport().size_changed.connect(resize)
	resize.call()


func _process(delta: float) -> void:
	idle_time += delta
	for i in range(ripples.size()):
		var size := 0.15 + fmod(idle_time * 0.12 + i * 0.23, 1.0) * 1.7
		ripples[i].scale = Vector3(size, 1, size)
	if current_space == "lobby" and not transitioning and is_instance_valid(player):
		var local := doors[0].to_local(player.viewer_position())
		if doors[0].is_open and absf(local.x) < 0.9 and local.z < -0.35 and local.z > -1.8:
			enter_first_door()
	if experience_running:
		advance_experience(delta)
	elif not experience_complete:
		candle.light_energy = 1.45 + sin(idle_time * 2.1) * 0.05
	if is_instance_valid(hud_location):
		desktop_hud.visible = not transitioning
		hud_location.text = "SEVEN DEATHS  /  " + ("LOBBY" if current_space == "lobby" else "DET SIDSTE ÅNDEDRAG")
		hud_prompt.text = _context_prompt()
		# Keep the desktop overlay out of the black room transition.
		hud_prompt.modulate.a = 1.0 - fade_material.albedo_color.a


func _context_prompt() -> String:
	if transitioning:
		return ""
	if is_instance_valid(player.focused):
		var target: Area3D = player.focused
		if target.has_method("set_prompt"):
			return target.prompt.replace("\n", "  ·  ")
		if target.available:
			return "Gå gennem dør I" if target.is_open else "E · Åbn dør I — Det sidste åndedrag"
		return "%s · %s · Kommer senere" % [target.title, target.theme]
	if current_space == "lobby":
		return "Følg de gyldne punkter til dør I"
	return "R · Tilbage til lobbyen når som helst"


func _on_door_selected(door: Area3D) -> void:
	if not door.available:
		print("Dør %d er en pladsholder i denne prototype." % door.number)


func enter_first_door() -> void:
	if transitioning or current_space != "lobby" or not doors[0].is_open:
		return
	_change_space("chamber")


func return_to_lobby() -> void:
	if transitioning or current_space == "lobby":
		return
	_change_space("lobby")


func _change_space(destination: String) -> void:
	transitioning = true
	player.locomotion_enabled = false
	player.interaction_enabled = false
	var tween := create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, transition_duration)
	await tween.finished
	experience_running = false
	sound.stop_breathing()
	current_space = destination
	if destination == "chamber":
		_reset_chamber()
		player.relocate(CHAMBER + Vector3(0, 0.03, 1.8))
	else:
		doors[0].close()
		player.relocate(LOBBY_SPAWN, deg_to_rad(30))
	tween = create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 0.0, transition_duration)
	await tween.finished
	transitioning = false
	player.locomotion_enabled = true
	player.interaction_enabled = true
	print("Seven Doors: ", current_space)


func _reset_chamber() -> void:
	experience_elapsed = 0
	sequence_stage = -1
	experience_complete = false
	story.text = "Et rum. En seng. Et lys.\nBegynd, når du er klar."
	start_action.enabled = true
	start_action.set_prompt("E / højre trigger\nBEGYND OPLEVELSEN · ca. 48 sek.")
	candle.light_energy = 1.5
	chamber_light.light_energy = 0.8
	flame.visible = true


func start_experience() -> void:
	if current_space != "chamber" or transitioning or experience_running:
		return
	_reset_chamber()
	experience_running = true
	start_action.enabled = false
	start_action.set_prompt("Lyt. Tag dig tid.\nR / B · tilbage når som helst")
	sound.begin_breathing()
	advance_experience(0)


func advance_experience(delta: float) -> void:
	if not experience_running:
		return
	experience_elapsed = minf(experience_elapsed + maxf(delta, 0.0), experience_duration)
	var amount := clampf(experience_elapsed / maxf(experience_duration, 0.01), 0.0, 1.0)
	var stage := 0
	if amount >= 1.0:
		stage = 4
	elif amount >= 0.77:
		stage = 3
	elif amount >= 0.47:
		stage = 2
	elif amount >= 0.18:
		stage = 1
	if stage != sequence_stage:
		sequence_stage = stage
		var lines := [
			"Du er her.\nLyt til rummet.",
			"Et åndedrag ind.\nEt åndedrag ud.",
			"Lyset holder fast.\nÅndedrættet bliver svagere.",
			"Der er næsten stille.",
			"Det sidste åndedrag.\nKun rummet bliver tilbage.",
		]
		story.text = lines[stage]
	var breath := 0.92 + 0.08 * sin(experience_elapsed * TAU / 8.0)
	candle.light_energy = 1.5 * (1.0 - amount) * breath
	chamber_light.light_energy = lerpf(0.8, 0.18, amount)
	sound.set_breath_progress(amount)
	if amount >= 1.0:
		experience_running = false
		experience_complete = true
		doors[0].completed = true
		sound.stop_breathing()
		flame.visible = false
		start_action.enabled = true
		start_action.set_prompt("OPLEVELSEN ER SLUT\nE / trigger · Oplev igen\nR / B · Vend tilbage")
		print("Seven Doors: first experience completed.")


func _constrain_xr(destination: Vector3) -> Vector3:
	var head_offset: Vector3 = player.head.global_position - player.origin.global_position
	var feet := destination + Vector3(head_offset.x, 0, head_offset.z)
	if current_space == "lobby":
		feet.z = minf(feet.z, CENTER.z - 0.4)
		var radial := Vector2(feet.x - CENTER.x, feet.z - CENTER.z)
		var limit := RADIUS + 0.8 if doors[0].is_open else RADIUS - 0.4
		radial = radial.limit_length(limit)
		feet.x = CENTER.x + radial.x
		feet.z = CENTER.z + radial.y
	else:
		feet.x = clampf(feet.x, CHAMBER.x - 3.5, CHAMBER.x + 3.5)
		feet.z = clampf(feet.z, -4.5, 2.5)
	return feet - Vector3(head_offset.x, 0, head_offset.z)
