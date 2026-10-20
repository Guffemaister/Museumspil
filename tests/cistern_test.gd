extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("Cistern tests timed out.")
		quit(1)
	)
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _settle(frames: int = 2) -> void:
	for frame in range(frames):
		await physics_frame


func _transition(scene: Node3D) -> void:
	for frame in range(120):
		if not scene.transitioning:
			return
		await physics_frame
	_check(false, "Room transition did not finish.")


func _face(player: Node3D, target: Area3D) -> void:
	var feet := target.to_global(Vector3(0, 0, 2.4))
	feet.y = 0.03
	player.relocate(feet, target.global_rotation.y)


func _run() -> void:
	var scene = load("res://Cisternerne.tscn").instantiate()
	root.add_child(scene)
	scene.transition_duration = 0.015
	await _settle()
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://Cisternerne.tscn", "F5 must launch the new lobby.")
	_check(scene.current_space == "lobby", "Player must begin in the lobby.")
	_check(scene.doors.size() == 7, "Lobby must have seven doors.")
	_check(scene.player.camera.current, "Desktop fallback must be active.")
	var available := 0
	for door in scene.doors:
		if door.available:
			available += 1
		var distance: float = Vector2(door.position.x, door.position.z - scene.CENTER.z).length()
		_check(absf(distance - (scene.RADIUS - 0.08)) < 0.01, "Doors must follow the curved wall.")
		_check(door.position.z < scene.CENTER.z, "All doors must be on the semicircular side.")
	_check(available == 2 and scene.doors[0].available and scene.doors[1].available, "Doors I and II must be available.")
	_check(not scene.doors[0].is_open, "Door I must begin closed.")
	_check(scene.sound.ambience.playing, "The generated ambience must play.")
	_check(not scene.sound.breathing.playing, "Breathing must wait for the experience to begin.")
	scene.enter_first_door()
	_check(not scene.transitioning, "A closed door must not allow entry.")
	scene.start_experience()
	_check(not scene.experience_running, "The experience must not start from the lobby.")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	_check(scene.player.mouse_captured, "Clicking must enable mouse look.")
	var before: Vector3 = scene.player.desktop.position
	_key(KEY_W, true)
	await _settle(20)
	_key(KEY_W, false)
	_check(scene.player.desktop.position.distance_to(before) > 0.4, "WASD must move the player.")

	# Locked doors must be selectable, but cannot start a scene or swing open.
	_face(scene.player, scene.doors[3])
	await _settle()
	scene.player._update_focus()
	_check(scene.player.focused == scene.doors[3], "The ray must select a locked door.")
	_key(KEY_E, true)
	_key(KEY_E, false)
	_check(not scene.doors[3].is_open and scene.current_space == "lobby", "Placeholder doors must stay closed.")

	# Walk into the closed first door and verify its physical collision.
	_face(scene.player, scene.doors[0])
	await _settle()
	_key(KEY_W, true)
	await _settle(75)
	_key(KEY_W, false)
	var local: Vector3 = scene.doors[0].to_local(scene.player.viewer_position())
	_check(local.z > 0.1, "A closed door must block walking through it.")
	_check(scene.current_space == "lobby", "Touching a closed door must not enter its room.")
	_face(scene.player, scene.doors[0])
	await _settle()
	scene.player._update_focus()
	_check(scene.player.focused == scene.doors[0], "The ray must select door I.")
	_key(KEY_E, true)
	_key(KEY_E, false)
	_check(scene.doors[0].is_open, "E must open door I.")
	_check(scene.current_space == "lobby", "Opening the door alone must not teleport the player.")
	await _settle(80)
	_check(scene.doors[0].leaf.rotation.y > 1.7, "The door panel must visibly swing open.")
	_key(KEY_W, true)
	for frame in range(110):
		if scene.transitioning:
			break
		await physics_frame
	_key(KEY_W, false)
	_check(scene.transitioning, "Walking over the open threshold must start the transition.")
	_check(not scene.player.interaction_enabled, "Interaction must be disabled during the transition.")
	await _transition(scene)
	_check(scene.current_space == "chamber", "The threshold must lead to the first room.")
	_check(scene.player.desktop.position.x > 25, "Player must arrive in the separate chamber.")
	_check(scene.player.interaction_enabled and scene.player.locomotion_enabled, "Controls must resume after the fade.")
	_check(is_zero_approx(scene.fade_material.albedo_color.a), "The room fade must clear.")
	_check(not scene.experience_running, "The sequence must wait for the player's consent to begin.")

	# The same ray/input path starts the sequence at the bedside.
	_face(scene.player, scene.start_action)
	await _settle()
	scene.player._update_focus()
	_check(scene.player.focused == scene.start_action, "The bedside action must be selectable.")
	_key(KEY_E, true)
	_key(KEY_E, false)
	_check(scene.experience_running, "E at the bedside must begin the experience.")
	_check(scene.sound.breathing.playing, "Starting must play the original breathing sound.")
	_check(scene.player.sequence_motion_active, "La traviata must move the player into the first-person bedside viewpoint.")
	# Test the production sequence's timing without waiting 48 seconds.
	scene.set_process(false)
	scene.advance_experience(9)
	_check(scene.player.viewer_position().distance_to(scene.CHAMBER + Vector3(0, 1.3, -1.85)) < 0.08, "The player must experience the scene from the bed.")
	_check(scene.sequence_stage == 1, "The first breathing text must appear.")
	var energy: float = scene.candle.light_energy
	scene.advance_experience(15)
	_check(scene.sequence_stage == 2 and scene.candle.light_energy < energy, "Text and candlelight must progress together.")
	scene.advance_experience(15)
	_check(scene.sequence_stage == 3, "The silence stage must appear before completion.")
	scene.advance_experience(48)
	_check(scene.experience_complete and not scene.experience_running, "The sequence must complete.")
	_check(scene.doors[0].completed, "Completion must be recorded on door I.")
	_check(not scene.flame.visible and is_zero_approx(scene.candle.light_energy), "The candle must go out at the end.")
	_check(not scene.sound.breathing.playing, "Breathing must stop at the end.")
	_check(scene.story.text.contains("Kun rummet"), "The final text must remain visible.")
	_check(scene.fade_material.albedo_color.a > 0.99, "The last breath must end in darkness before restoring the view.")
	await scene.first_recovery.finished
	_check(scene.player.interaction_enabled and not scene.player.sequence_motion_active, "The bedside sequence must restore normal controls after its fade.")
	scene.advance_experience(100)
	_check(scene.experience_elapsed == scene.experience_duration, "An ended sequence must not advance again.")
	scene.set_process(true)

	# The return door and its action must work after completion.
	_face(scene.player, scene.return_action)
	await _settle()
	scene.player._update_focus()
	_check(scene.player.focused == scene.return_action, "The return doorway must be selectable.")
	_key(KEY_E, true)
	_key(KEY_E, false)
	await _transition(scene)
	_check(scene.current_space == "lobby", "The return doorway must lead to the lobby.")
	_check(not scene.doors[0].is_open and scene.doors[0].completed, "The door must close and retain completion.")
	_check(scene.doors[0].hint.text.contains("OPLEVET"), "The lobby must show that door I was experienced.")
	_check(scene.player.desktop.position.distance_to(scene.LOBBY_SPAWN) < 0.1, "Return must restore the lobby spawn.")

	# Re-entry resets the candle and allows an early exit without a false completion.
	scene.doors[0].activate()
	scene.enter_first_door()
	await _transition(scene)
	_check(not scene.experience_complete and scene.flame.visible, "A repeat visit must reset the experience.")
	scene.start_experience()
	scene.advance_experience(10)
	_key(KEY_R, true)
	_key(KEY_R, false)
	await _transition(scene)
	_check(scene.current_space == "lobby" and not scene.experience_running, "R must allow an early exit.")
	_check(not scene.sound.breathing.playing, "Early exit must stop the breathing audio.")
	_check(not scene.player.sequence_motion_active and is_zero_approx(scene.fade_material.albedo_color.a), "Interrupting La traviata must restore the player rig and clear the fade.")
	_check(scene.experience_elapsed < scene.experience_duration, "Early exit must not complete the sequence.")
	# Guard against the old rectangular museum bounds leaking into this scene.
	var constrained: Vector3 = scene._constrain_xr(Vector3(-200, 0, -200))
	_check(Vector2(constrained.x, constrained.z - scene.CENTER.z).length() <= scene.RADIUS, "VR locomotion must respect the curved lobby boundary.")
	scene.current_space = "chamber"
	constrained = scene._constrain_xr(Vector3(200, 0, 200))
	_check(constrained.x > 25 and constrained.x <= 33.5 and constrained.z <= 2.5, "VR bounds must follow the player into the chamber.")
	scene.queue_free()
	await process_frame
	# Audio playback references are released on the mixer thread.
	await create_timer(0.2).timeout
	print("Cistern tests: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
