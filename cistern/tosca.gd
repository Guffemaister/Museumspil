extends Node3D

signal completed
signal return_requested

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
@export var gentle_fall: bool = false
var state: String = "ready"
var state_elapsed: float = 0.0
var step_offset := Vector3.ZERO
@export_group("Fall")
@export_range(1.0, 60.0) var full_fall_distance: float = 25.0
@export_range(0.5, 10.0) var short_fall_distance: float = 4.0
@export_range(0.5, 5.0) var confirmation_distance: float = 2.0
@export var scarf_offset := Vector3(0.35, -0.6, -0.5)
@export_group("Navigation")
@export var movement_bounds := Rect2(-3.5, -3.8, 7.0, 6.5)
@export_group("Narrative")
@export_multiline var intro_text: String = "Du står højt over Rom.\nVinden griber dit tøj."
@export_multiline var edge_text: String = "Du nærmer dig kanten.\nEt øjeblik mellem himmel og jord."
@export_multiline var confirm_text: String = "Gå hen til kanten med stick / WASD.\nBekræft med E / trigger, når du er klar."
@export_multiline var ending_text: String = "Faldet er forbi.\nEt sidste ekko over byen."
var ready_text: String
var start_prompt: String
var fall_prompt: String
var lantern_energy: float
var wind_volume: float
var ribbon_homes: Array[Transform3D] = []


func _ready() -> void:
	start_action = $Interactions/BeginTosca
	fall_action = $Interactions/ConfirmFirstPersonFall
	mode_action = $Interactions/FallComfortMode
	return_action = $Interactions/ReturnFromTosca
	story = $Signage/Story
	scarf = $PlayerScarf
	lantern = $Lighting/LanternLight
	wind = $Audio/Wind
	bell = $Audio/Bell
	ready_text = story.text
	start_prompt = start_action.prompt
	fall_prompt = fall_action.prompt
	lantern_energy = lantern.light_energy
	wind_volume = wind.volume_db
	for part in scarf.get_children():
		ribbon_parts.append(part)
		ribbon_homes.append(part.transform)
	start_action.activated.connect(start)
	fall_action.activated.connect(confirm_fall)
	mode_action.activated.connect(toggle_fall_mode)
	return_action.activated.connect(func(): return_requested.emit())
	reset()


func bind_view(viewer: Node3D, surface: StandardMaterial3D) -> void:
	player = viewer
	fade_surface = surface


func enter_room() -> void:
	reset()
	active = true
	wind.volume_db = wind_volume
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
	lantern.light_energy = lantern_energy
	story.text = ready_text
	_action(start_action, true)
	_action(fall_action, false)
	fall_action.set_prompt(fall_prompt)
	_action(mode_action, true)
	start_action.set_prompt(start_prompt)
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
	story.text = intro_text if stage == 0 else edge_text


func confirm_fall() -> void:
	if not active or state != "awaiting_fall" or not is_instance_valid(player):
		return
	var at := to_local(player.viewer_position())
	var confirmation := to_local(fall_action.global_position)
	if Vector2(at.x - confirmation.x, at.z - confirmation.z).length() > confirmation_distance:
		fall_action.set_prompt("Kom tættere på kanten\nE / trigger · Begynd faldet")
		return
	state = "falling"
	state_elapsed = 0
	stage = 2
	_action(fall_action, false)
	var destination: Vector3 = $Markers/FallTarget.global_position
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
		ribbon_parts[i].position.x = ribbon_homes[i].origin.x + sin(idle_time * 1.7 - i * 0.55) * (0.025 + i * 0.012)
		ribbon_parts[i].rotation.z = ribbon_homes[i].basis.get_euler().z + sin(idle_time * 1.7 - i * 0.55) * 0.16


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
				story.text = confirm_text
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
				story.text = ending_text
		elif state == "ending":
			_set_fade(1.0 - smoothstep(0.8, outro_duration, state_elapsed))
			if state_elapsed >= limit:
				_finish()
		else:
			return


func _update_fall() -> void:
	var step := smoothstep(0, 0.7, state_elapsed)
	var progress := clampf((state_elapsed - 0.7) / (fall_duration - 0.7), 0, 1)
	var distance := short_fall_distance if gentle_fall else full_fall_distance
	player.set_sequence_offset(step_offset * step + Vector3(0, -distance * progress * progress, 0))
	# Local head tracking and mouse look remain live; the rig translates without rolling.
	scarf.position = to_local(player.viewer_position()) + scarf_offset
	wind.volume_db = lerpf(wind_volume, wind_volume + 12.0, progress)
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
	wind.volume_db = wind_volume - 5
	_action(start_action, true)
	_action(mode_action, true)
	start_action.set_prompt("DU HAR OPLEVET TOSCAS FALD\nE / trigger · Oplev igen\nR / B · Vend tilbage")
	completed.emit()
	print("Seven Doors: first-person Tosca completed.")


func _exit_tree() -> void:
	for source in [wind, bell]:
		if is_instance_valid(source):
			source.stop()
			source.stream = null
