extends "res://tests/cistern_test.gd"


func _run() -> void:
	# The editor instantiates scenes without running _ready. Everything must
	# already exist, including colliders, cameras, text, controllers and audio.
	var required := {
		"LaTraviata": ["Architecture/Floor", "Bed/Mattress", "Bed/FirstPersonView", "CandleTable/CandleLight", "Interactions/BeginExperience/CollisionShape3D", "Markers/PlayerSpawn"],
		"Tosca": ["Tower/TerraceFloor", "Tower/Railing", "City/Building44/Roof", "PlayerScarf/Ribbon01", "Audio/Wind", "Markers/PlayerSpawn", "Markers/FallTarget"],
		"Player": ["Desktop/CollisionShape3D", "Desktop/Camera/Fade", "XROrigin/Head/Fade", "XROrigin/RightHand/AimRay", "XROrigin/LeftHand/ControllerModel"],
		"DesktopHUD": ["Screen/Panel", "Screen/Location", "Screen/Controls", "Screen/Prompt", "Screen/Reticle"],
		"Soundscape": ["Ambience", "Breathing"],
		"Museum": ["Architecture/Part01/Collision", "Exhibits/Exhibit1/Visual", "Exhibits/Exhibit3/Caption", "DesktopHUD/Screen/Information", "Player/Desktop/Camera"],
	}
	for scene_name in required:
		var layout = load("res://%s.tscn" % scene_name).instantiate()
		for path in required[scene_name]:
			_check(layout.has_node(path), "%s must save editable node %s." % [scene_name, path])
		var count: int = layout.find_children("*", "Node", true, false).size()
		root.add_child(layout)
		await _settle()
		_check(layout.find_children("*", "Node", true, false).size() == count, "%s must not create additional nodes at startup." % scene_name)
		await create_timer(0.3).timeout
		layout.queue_free()
		await create_timer(0.2).timeout

	var game = load("res://Cisternerne.tscn").instantiate()
	var room: Node3D = game.get_node("LaTraviata")
	room.position += Vector3(3, 0, 5)
	room.rotation.y = 0.35
	room.duration = 20.0
	room.narrative[0] = "Redigeret fortælling"
	room.get_node("Bed").position.x += 0.3
	room.get_node("Markers/PlayerSpawn").position.z -= 0.2
	room.get_node("Markers/PlayerSpawn").rotation.y = 0.15
	room.get_node("CandleTable/CandleLight").light_energy = 2.0
	room.get_node("Signage/Story").text = "Mit værelse"
	room.get_node("Interactions/BeginExperience").prompt = "Min starttekst"
	var tower: Node3D = game.get_node("Tosca")
	tower.position += Vector3(4, 0, -3)
	tower.rotation.y = -0.3
	tower.get_node("Markers/PlayerSpawn").position.x = 0.25
	tower.get_node("Markers/FallTarget").position.x = 0.6
	tower.get_node("Interactions").position.z = 0.1
	tower.full_fall_distance = 12.0
	tower.intro_duration = 5.0
	tower.intro_text = "Min introduktion"
	game.get_node("Player/Desktop/Camera").position.y = 1.7
	game.get_node("Player/Desktop/Camera").fov = 80.0
	game.get_node("DesktopHUD/Screen/Controls").text = "Mine kontroller"
	game.get_node("Soundscape/Ambience").volume_db = -28.0

	# Save exactly like an edited main scene, then start the reloaded result.
	var packed := PackedScene.new()
	_check(packed.pack(game) == OK, "The composed game must remain saveable.")
	var path := "user://editable_scenes_test.tscn"
	_check(ResourceSaver.save(packed, path) == OK, "Godot must save all scene edits.")
	game.free()
	game = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	room = game.get_node("LaTraviata")
	tower = game.get_node("Tosca")
	var count: int = game.find_children("*", "Node", true, false).size()
	root.add_child(game)
	game.set_process(false)
	tower.set_process(false)
	game.player.set_physics_process(false)
	game.transition_duration = 0.01
	await _settle()
	_check(game.find_children("*", "Node", true, false).size() == count, "The complete game must use only its saved nodes.")
	_check(room.position.is_equal_approx(Vector3(33, 0, 5)) and is_equal_approx(room.rotation.y, 0.35), "Room transforms must survive saving and startup.")
	_check(game.story.text == "Mit værelse" and game.start_action.prompt == "Min starttekst", "Edited room text must survive saving and startup.")
	_check(is_equal_approx(game.player.camera.fov, 80.0) and is_equal_approx(game.player.camera.position.y, 1.7), "Player camera settings must survive saving and startup.")
	_check(game.get_node("DesktopHUD/Screen/Controls").text == "Mine kontroller", "Saved HUD text must not be overwritten.")
	_check(is_equal_approx(game.sound.ambience.volume_db, -28.0), "Audio levels must use the saved settings.")
	_check(game.player.fade_surface() == game.fade_material, "Transitions must use the saved active camera's fade material.")
	_check(game.player.head.get_node("Fade").material_override == game.fade_material, "Desktop and OpenXR fades must share the same instance-local transition material.")

	game.doors[0].is_open = true
	game.enter_first_door()
	await _transition(game)
	var spawn: Marker3D = room.get_node("Markers/PlayerSpawn")
	_check(game.player.desktop.global_position.distance_to(spawn.global_position) < 0.01, "La traviata must use the edited spawn in the moved and rotated room.")
	_check(is_equal_approx(game.player.desktop.global_rotation.y, spawn.global_rotation.y), "The editable spawn's facing direction must be respected.")
	_check(game.story.text == "Mit værelse" and is_equal_approx(game.candle.light_energy, 2.0), "Re-entering a room must restore edited text and light settings.")
	game.start_experience()
	game.advance_experience(2.5)
	_check(game.story.text == "Redigeret fortælling", "Edits to narrative entries must survive save/reload and appear during playback.")
	game.advance_experience(1.5)
	_check(game.story.text == room.narrative[1], "The sequence must use the room's editable narrative.")
	_check(is_equal_approx(game.experience_duration, 20.0), "La traviata must use the room's Inspector duration.")
	_check(game.player.viewer_position().distance_to(room.get_node("Bed/FirstPersonView").global_position) < 0.01, "The first-person viewpoint must follow the moved bed and room.")
	var bounded: Vector3 = room.to_local(game._constrain_xr(room.to_global(Vector3(100, 0, 100))))
	_check(room.movement_bounds.has_point(Vector2(bounded.x, bounded.z) - Vector2(0.001, 0.001)), "VR limits must follow La traviata's edited room transform.")
	game.return_to_lobby()
	await _transition(game)
	game.doors[1].is_open = true
	game.enter_door(1)
	await _transition(game)
	spawn = tower.get_node("Markers/PlayerSpawn")
	_check(game.player.desktop.global_position.distance_to(spawn.global_position) < 0.01, "Tosca must use the edited spawn in the moved and rotated room.")
	game.tosca.start()
	_check(game.tosca.story.text == "Min introduktion", "Tosca must use edited narrative text.")
	game.tosca.advance(5.0)
	_check(game.tosca.state == "awaiting_fall", "Tosca must use its edited intro duration.")
	var confirmation: Vector3 = game.tosca.fall_action.global_position
	game.player.relocate(Vector3(confirmation.x, 0.03, confirmation.z), tower.global_rotation.y)
	game.tosca.confirm_fall()
	_check(game.tosca.state == "falling", "Fall confirmation must follow the moved interactions and room.")
	game.tosca.advance(0.7)
	var target: Vector3 = tower.get_node("Markers/FallTarget").global_position
	var view: Vector3 = game.player.viewer_position()
	_check(Vector2(view.x, view.z).distance_to(Vector2(target.x, target.z)) < 0.01, "The player must step to the edited fall marker.")
	var height: float = view.y
	game.tosca.advance((game.tosca.fall_duration - 0.7) * 0.5)
	_check(is_equal_approx(height - game.player.viewer_position().y, 3.0), "Fall distance must use the Inspector setting (half time gives one-quarter distance).")
	game.return_to_lobby()
	await _transition(game)
	_check(is_equal_approx(game.sound.ambience.volume_db, -28.0), "Returning must restore the edited lobby audio level.")
	await create_timer(0.3).timeout
	game.queue_free()
	await create_timer(0.2).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Editable scene tests: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
