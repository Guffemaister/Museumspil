extends Node3D

const RADIUS: float = 8.5
const CENTER := Vector3(0, 0, 2)
const CHAMBER := Vector3(30, 0, 0)
const TOSCA_ROOM := Vector3(70, 0, 0)
# Compatibility property; the room owns its editable duration.
var experience_duration: float:
	get:
		return $LaTraviata.duration
	set(value):
		$LaTraviata.duration = value
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
var tosca: Node3D
var first_view_offset := Vector3.ZERO
var first_recovery: Tween
var candle_energy: float
var room_energy: float
var ready_text: String
var start_prompt: String
var ripple_scales: Array[Vector3] = []


func _ready() -> void:
	lobby = $Lobby
	chamber = $LaTraviata
	tosca = $Tosca
	player = $Player
	sound = $Soundscape
	story = $LaTraviata/Signage/Story
	chamber_subtitle = $LaTraviata/Signage/Subtitle
	start_action = $LaTraviata/Interactions/BeginExperience
	return_action = $LaTraviata/Interactions/ReturnToLobby
	candle = $LaTraviata/CandleTable/CandleLight
	flame = $LaTraviata/CandleTable/Flame
	chamber_light = $LaTraviata/Lighting/RoomLight
	candle_energy = candle.light_energy
	room_energy = chamber_light.light_energy
	ready_text = story.text
	start_prompt = start_action.prompt
	start_action.set_prompt(start_prompt.replace("{duration}", str(int(experience_duration))))
	start_action.activated.connect(start_experience)
	return_action.activated.connect(return_to_lobby)
	for i in range(7):
		var door: Area3D = lobby.get_node("Doors/Door%d" % (i + 1))
		door.selected.connect(_on_door_selected)
		doors.append(door)
	for ring in lobby.get_node("WaterRipples").get_children():
		ripples.append(ring)
		ripple_scales.append(ring.scale)
	tosca.completed.connect(_on_tosca_completed)
	tosca.return_requested.connect(return_to_lobby)
	player.xr_movement_constraint = _constrain_xr
	player.return_requested.connect(return_to_lobby)
	_place_in_lobby()
	fade_material = player.fade_surface()
	tosca.bind_view(player, fade_material)
	desktop_hud = $DesktopHUD
	desktop_hud.visible = not player.xr_active
	hud_location = $DesktopHUD/Screen/Location
	hud_prompt = $DesktopHUD/Screen/Prompt
	print("Seven Doors: lobby ready; doors I and II are playable.")


func _place_in_lobby() -> void:
	var spawn: Marker3D = lobby.get_node("PlayerSpawn")
	player.relocate(spawn.global_position, spawn.global_rotation.y)


func _process(delta: float) -> void:
	idle_time += delta
	for i in range(ripples.size()):
		var size := 0.15 + fmod(idle_time * 0.12 + i * 0.23, 1.0) * 1.7
		ripples[i].scale = ripple_scales[i] * Vector3(size, 1, size)
	if current_space == "lobby" and not transitioning and is_instance_valid(player):
		for i in range(2):
			var local := doors[i].to_local(player.viewer_position())
			if doors[i].is_open and absf(local.x) < 0.9 and local.z < -0.35 and local.z > -1.8:
				enter_door(i)
				break
	if experience_running:
		advance_experience(delta)
	elif not experience_complete:
		candle.light_energy = candle_energy * (0.96667 + sin(idle_time * 2.1) * 0.03333)
	if is_instance_valid(hud_location):
		desktop_hud.visible = not player.xr_active and not transitioning and not player.sequence_motion_active and fade_material.albedo_color.a < 0.1
		var titles := {"lobby": "LOBBY", "chamber": "DET SIDSTE ÅNDEDRAG", "tosca": "TOSCA / FALDET"}
		hud_location.text = "SEVEN DEATHS  /  " + titles.get(current_space, "LOBBY")
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
			return "Gå gennem dør " + target.caption.text if target.is_open else "E · Åbn dør %s — %s" % [target.caption.text, target.title]
		return "%s · %s · Kommer senere" % [target.title, target.theme]
	if current_space == "lobby":
		return "Vælg dør I · La traviata  /  dør II · Tosca"
	return "R · Tilbage til lobbyen når som helst"


func _on_door_selected(door: Area3D) -> void:
	if not door.available:
		print("Dør %d er en pladsholder i denne prototype." % door.number)


func enter_first_door() -> void:
	enter_door(0)


func enter_door(index: int) -> void:
	if transitioning or current_space != "lobby" or index < 0 or index >= 2:
		return
	if not doors[index].available or not doors[index].is_open:
		return
	_change_space("chamber" if index == 0 else "tosca")


func _on_tosca_completed() -> void:
	doors[1].completed = true


func return_to_lobby() -> void:
	if transitioning or current_space == "lobby":
		return
	_change_space("lobby")


func _change_space(destination: String) -> void:
	transitioning = true
	if first_recovery != null and first_recovery.is_valid():
		first_recovery.kill()
	tosca.suspend_for_transition()
	experience_running = false
	player.locomotion_enabled = false
	player.interaction_enabled = false
	var tween := create_tween()
	tween.tween_property(fade_material, "albedo_color:a", 1.0, transition_duration)
	await tween.finished
	experience_running = false
	sound.stop_breathing()
	tosca.exit_room()
	player.end_sequence_motion()
	player.locomotion_enabled = false
	sound.ambience.volume_db = sound.lobby_ambience_db
	current_space = destination
	if destination == "chamber":
		_reset_chamber()
		_place_at(chamber.get_node("Markers/PlayerSpawn"))
	elif destination == "tosca":
		tosca.enter_room()
		sound.ambience.volume_db = sound.room_ambience_db
		_place_at(tosca.get_node("Markers/PlayerSpawn"))
	else:
		for door in doors:
			door.close()
		_place_in_lobby()
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
	story.text = ready_text
	start_action.enabled = true
	start_action.set_prompt(start_prompt.replace("{duration}", str(int(experience_duration))))
	candle.light_energy = candle_energy
	chamber_light.light_energy = room_energy
	flame.visible = true


func start_experience() -> void:
	if current_space != "chamber" or transitioning or experience_running:
		return
	_reset_chamber()
	experience_running = true
	player.begin_sequence_motion()
	player.interaction_enabled = false
	first_view_offset = chamber.get_node("Bed/FirstPersonView").global_position - player.viewer_position()
	start_action.enabled = false
	start_action.set_prompt("Lyt. Tag dig tid.\nR / B · tilbage når som helst")
	sound.begin_breathing()
	advance_experience(0)


func advance_experience(delta: float) -> void:
	if not experience_running:
		return
	experience_elapsed = minf(experience_elapsed + maxf(delta, 0.0), experience_duration)
	var amount := clampf(experience_elapsed / maxf(experience_duration, 0.01), 0.0, 1.0)
	player.set_sequence_offset(first_view_offset * smoothstep(0, 0.12, amount))
	var shade := fade_material.albedo_color
	shade.a = smoothstep(0.8, 1.0, amount)
	fade_material.albedo_color = shade
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
		if not chamber.narrative.is_empty():
			story.text = chamber.narrative[mini(stage, chamber.narrative.size() - 1)]
	var breath := 0.92 + 0.08 * sin(experience_elapsed * TAU / 8.0)
	candle.light_energy = candle_energy * (1.0 - amount) * breath
	chamber_light.light_energy = room_energy * lerpf(1.0, 0.225, amount)
	sound.set_breath_progress(amount)
	if amount >= 1.0:
		experience_running = false
		experience_complete = true
		doors[0].completed = true
		sound.stop_breathing()
		flame.visible = false
		start_action.enabled = true
		start_action.set_prompt("OPLEVELSEN ER SLUT\nE / trigger · Oplev igen\nR / B · Vend tilbage")
		# Restore the standing position while the view is black, then reveal the room.
		player.end_sequence_motion()
		player.locomotion_enabled = false
		first_recovery = create_tween()
		first_recovery.tween_interval(0.5)
		first_recovery.tween_property(fade_material, "albedo_color:a", 0.0, 1.2)
		first_recovery.tween_callback(_finish_first_view)
		print("Seven Doors: first experience completed.")


func _finish_first_view() -> void:
	if current_space == "chamber" and not transitioning:
		player.locomotion_enabled = true
		player.interaction_enabled = true


func _constrain_xr(destination: Vector3) -> Vector3:
	var head_offset: Vector3 = player.head.global_position - player.origin.global_position
	var feet := destination + Vector3(head_offset.x, 0, head_offset.z)
	if current_space == "lobby":
		var local_feet := lobby.to_local(feet)
		local_feet.z = minf(local_feet.z, CENTER.z - 0.4)
		var radial := Vector2(local_feet.x - CENTER.x, local_feet.z - CENTER.z)
		var passage_open: bool = doors[0].is_open or doors[1].is_open
		var limit := RADIUS + 0.8 if passage_open else RADIUS - 0.4
		radial = radial.limit_length(limit)
		local_feet.x = CENTER.x + radial.x
		local_feet.z = CENTER.z + radial.y
		feet = lobby.to_global(local_feet)
	else:
		var room: Node3D = tosca if current_space == "tosca" else chamber
		var local_feet := room.to_local(feet)
		var bounds: Rect2 = room.movement_bounds
		local_feet.x = clampf(local_feet.x, bounds.position.x, bounds.end.x)
		local_feet.z = clampf(local_feet.z, bounds.position.y, bounds.end.y)
		feet = room.to_global(local_feet)
	return feet - Vector3(head_offset.x, 0, head_offset.z)


func _place_at(spawn: Marker3D) -> void:
	player.relocate(spawn.global_position, spawn.global_rotation.y)
