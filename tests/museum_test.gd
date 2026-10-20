extends SceneTree

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	# A script failure must not leave the test runner hanging indefinitely.
	create_timer(20.0).timeout.connect(func():
		push_error("Museum tests timed out.")
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


func _run() -> void:
	var museum = load("res://Museum.tscn").instantiate()
	root.add_child(museum)
	await physics_frame
	await physics_frame
	_check(museum.exhibits.size() == 3, "Expected three artifacts.")
	_check(museum.visited == 0, "Tour must begin with zero discoveries.")
	_check(museum.player.camera.current, "Desktop camera must be active with --xr-mode off.")
	_check(not museum.player.xr_active, "Tests must run without a headset.")
	_check(museum.hud.text.contains("0 / 3"), "Desktop instructions must show initial progress.")
	var map: OpenXRActionMap = load("res://openxr_action_map.tres")
	_check(map.get_action_sets().size() > 0, "Controller action set must be saved.")
	var quest_bound := false
	for profile in map.get_interaction_profiles():
		if profile.interaction_profile_path == "/interaction_profiles/oculus/touch_controller":
			quest_bound = profile.get_bindings().size() > 0
	_check(quest_bound, "Quest Touch controller bindings must exist.")

	# Exercise actual input and physics rather than directly changing velocity.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	var before: Vector3 = museum.player.desktop.position
	_key(KEY_W, true)
	for frame in range(20):
		await physics_frame
	_key(KEY_W, false)
	await physics_frame
	_check(museum.player.desktop.position.z < before.z - 0.4, "W must move the player forward.")
	_check(absf(museum.player.desktop.position.y) < 0.1, "The player must stand on the floor.")
	museum.player.desktop.position = Vector3(5.3, 0.01, 1)
	_key(KEY_D, true)
	for frame in range(30):
		await physics_frame
	_key(KEY_D, false)
	await physics_frame
	_check(museum.player.desktop.position.x < 5.75, "The gallery wall must block movement.")
	_key(KEY_ESCAPE, true)
	_key(KEY_ESCAPE, false)
	before = museum.player.desktop.position
	_key(KEY_W, true)
	for frame in range(4):
		await physics_frame
	_key(KEY_W, false)
	_check(absf(museum.player.desktop.position.z - before.z) < 0.05, "Movement must stop when the mouse is released.")

	for artifact in museum.exhibits:
		museum.player.desktop.position = Vector3(artifact.home.origin.x, 0.01, artifact.home.origin.z + 2.2)
		museum.player.camera.look_at(artifact.global_position)
		await physics_frame
		await physics_frame
		museum.player._update_focus()
		_check(museum.player.focused == artifact, "Ray must select " + artifact.title)
		_key(KEY_E, true)
		await physics_frame
		_key(KEY_E, false)
		await physics_frame
		_check(museum.player.held == artifact and artifact.held, "E must pick up " + artifact.title)
		_check(artifact.global_position.distance_to(artifact.home.origin) > 0.3, "Held artifact must follow the camera.")
		_check(museum.information.text.contains(artifact.title), "Inspecting must display the artifact story.")
		_key(KEY_E, true)
		await physics_frame
		_key(KEY_E, false)
		await physics_frame
		_check(not artifact.held and museum.player.held == null, "E must release the artifact.")
		_check(artifact.global_position.is_equal_approx(artifact.home.origin), "Release must return the artifact to its display.")
		var visited_before: int = museum.visited
		museum.player._update_focus()
		museum.player.interact()
		museum.player.interact()
		_check(museum.visited == visited_before, "Repeated pickup must not double-count a discovery.")

	_check(museum.visited == 3, "All three discoveries must be counted.")
	_check(museum.progress.text.contains("TOUR COMPLETE"), "Finishing must display the completion message.")
	_check(museum.hud.text.contains("3 / 3"), "Desktop progress must update on completion.")

	# A solid obstacle must occlude an otherwise selectable artifact.
	var target: Area3D = museum.exhibits[2]
	museum.player._update_focus()
	_check(museum.player.focused == target, "Target must be visible before adding the obstacle.")
	var blocker := StaticBody3D.new()
	blocker.position = (museum.player.camera.global_position + target.global_position) / 2.0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 2, 0.2)
	collider.shape = shape
	blocker.add_child(collider)
	museum.add_child(blocker)
	await physics_frame
	await physics_frame
	museum.player._update_focus()
	_check(museum.player.focused == null, "Artifacts must not be selectable through walls.")
	museum.queue_free()
	await process_frame
	print("Museum tests: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
