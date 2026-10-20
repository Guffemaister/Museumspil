extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("Environment tests timed out")
		quit(1))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	var hall = load("res://Cisterne.tscn").instantiate()
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://Cisterne.tscn", "F5 must open the new environment")
	check(hall.get_node("Architecture/Pillars").get_child_count() == 28, "Pillars must exist as saved nodes before startup")
	check(hall.get_node("Architecture/Vaults").get_child_count() == 18, "Vaults must exist as saved nodes before startup")
	check(hall.get_node("WaterInstallations").get_child_count() == 4, "Water installations must be editable saved scenes")
	check(hall.has_node("Water/ReflectiveSurface") and hall.has_node("Lighting/WaterReflections"), "Water and its reflection probe must be saved")
	check(hall.has_node("Player/Head/Camera") and hall.has_node("Player/CollisionShape3D"), "The player camera and body must be editable")
	var count: int = hall.find_children("*", "Node", true, false).size()
	# Exercise actual editor-style changes, including a nested component override.
	var pillar: Node3D = hall.get_node("Architecture/Pillars/Pillar_2_2")
	pillar.position.x -= 0.15
	var edited_pillar := pillar.position
	hall.get_node("WaterInstallations/Installation1/PoolSpotlight").light_energy = 4.5
	hall.get_node("Player/Head/Camera").fov = 77.0
	hall.get_node("PlayerSpawn").position.x = 0.1
	var packed := PackedScene.new()
	check(packed.pack(hall) == OK, "The complete editable environment must pack")
	var path := "user://cistern_edit_test.tscn"
	check(ResourceSaver.save(packed, path) == OK, "Godot must save changes made in the editor")
	hall.free()
	hall = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	root.add_child(hall)
	var player: CharacterBody3D = hall.get_node("Player")
	await frames(5)
	check(hall.find_children("*", "Node", true, false).size() == count, "Startup must not generate or duplicate content")
	check(hall.get_node("Architecture/Pillars/Pillar_2_2").position.is_equal_approx(edited_pillar), "Edited pillars must survive save/reload")
	check(is_equal_approx(hall.get_node("WaterInstallations/Installation1/PoolSpotlight").light_energy, 4.5), "Edited installation lighting must survive save/reload")
	check(is_equal_approx(player.camera.fov,77.0), "Edited camera properties must survive startup")
	check(absf(player.position.x - 0.1) < 0.02, "The player must use the editable spawn marker")
	check(player.is_on_floor(), "The player must stand on the walkway")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	check(player.mouse_captured, "Click must enable mouse look and walking")
	check(not hall.get_node("Controls/Screen/ClickHint").visible, "The click hint must hide during exploration")
	var start: Vector3 = player.position
	key(KEY_W, true)
	await frames(40)
	key(KEY_W, false)
	check(player.position.z < start.z - 0.9, "Physical W input must move the player down the hall")
	check(absf(player.position.x - start.x) < 0.05, "Forward movement must not drift sideways")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(70,-20)
	player._unhandled_input(mouse)
	check(player.rotation.y < -0.1 and player.head.rotation.x > 0.02, "Mouse motion must turn and tilt the camera")
	key(KEY_R, true)
	key(KEY_R, false)
	await frames()
	check(player.position.distance_to(hall.get_node("PlayerSpawn").position) < 0.04, "R must restore the editable starting position")

	# Walk into a real pillar and an outside wall; neither may be crossed.
	player.position = Vector3(2.4,0.14,-1.1)
	player.rotation = Vector3.ZERO
	await frames()
	key(KEY_W,true)
	await frames(65)
	key(KEY_W,false)
	check(player.position.z > -2.5, "Pillar collision must block the player")
	player.position = Vector3(6.6,0.14,-4.6)
	await frames()
	key(KEY_D,true)
	await frames(40)
	key(KEY_D,false)
	check(player.position.x < 7.1, "The room boundary must prevent walking outside")

	# Approach the central walkway from the shallow basin and climb its edge.
	player.position = Vector3(1.5,-0.145,-7)
	player.rotation = Vector3.ZERO
	await frames(8)
	key(KEY_A,true)
	await frames(34)
	key(KEY_A,false)
	await frames(5)
	check(absf(player.position.x) < 0.45 and player.position.y > 0.08, "The player must be able to step back onto a walkway")
	check(player.is_on_floor(), "The player must settle on the walkway after a step")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	player._unhandled_input(esc)
	check(not player.mouse_captured, "Esc must release mouse look")
	check(hall.get_node("Controls/Screen/ClickHint").visible, "The click hint must return when the mouse is released")
	var paused: Vector3 = player.position
	key(KEY_W,true)
	await frames(10)
	key(KEY_W,false)
	check(player.position.distance_to(paused) < 0.02, "Movement must pause while the mouse is released")
	hall.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Environment tests: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
