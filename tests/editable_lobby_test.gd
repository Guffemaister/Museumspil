extends "res://tests/cistern_test.gd"


func _run() -> void:
	var layout = load("res://Lobby.tscn").instantiate()
	# These nodes must exist before _ready runs, as they do in the 3D editor.
	_check(layout.find_children("*", "MeshInstance3D", true, false).size() > 100, "Lobby meshes must be saved in the scene for visual editing.")
	_check(layout.get_node("Doors").get_child_count() == 7, "All seven doors must be editable nodes.")
	_check(layout.has_node("Architecture/Walls") and layout.has_node("Architecture/Columns"), "Walls and columns must have named editing groups.")
	_check(layout.has_node("Lighting/WorldEnvironment") and layout.has_node("PlayerSpawn"), "Lighting and player spawn must be editable.")
	var node_count: int = layout.find_children("*", "Node", true, false).size()
	root.add_child(layout)
	await _settle()
	_check(layout.find_children("*", "Node", true, false).size() == node_count, "Starting the scene must not duplicate saved door geometry.")
	_check(layout.get_node("Doors/Door2").title == "Tosca", "Door metadata must survive saving and loading.")
	layout.queue_free()
	await process_frame

	var game = load("res://Cisternerne.tscn").instantiate()
	var lobby: Node3D = game.get_node("Lobby")
	lobby.position = Vector3(2, 0, 1)
	lobby.rotation.y = 0.2
	var wall: Node3D = lobby.get_node("Architecture/Walls/Wall01")
	var edited_wall := wall.position + Vector3(0.4, 0, 0)
	wall.position = edited_wall
	var door: Area3D = lobby.get_node("Doors/Door2")
	var edited_door := door.position + Vector3(0, 0.12, 0)
	door.position = edited_door
	var spawn: Marker3D = lobby.get_node("PlayerSpawn")
	spawn.position.x += 0.2
	root.add_child(game)
	await _settle()
	# Let the mixer register the newly started ambience before this short test exits.
	await create_timer(0.3).timeout
	_check(wall.position.is_equal_approx(edited_wall), "Game startup must preserve edited walls.")
	_check(door.position.is_equal_approx(edited_door), "Game startup must preserve edited door transforms.")
	_check(game.player.desktop.global_position.distance_to(spawn.global_position) < 0.1, "The game must use the editable spawn marker.")
	_check(game.doors[1] == door, "Gameplay must use the actual edited door instance.")
	var bounded: Vector3 = lobby.to_local(game._constrain_xr(Vector3(-200, 0, -200)))
	_check(Vector2(bounded.x, bounded.z - game.CENTER.z).length() <= game.RADIUS, "VR bounds must follow a moved and rotated lobby.")
	var packed := PackedScene.new()
	_check(packed.pack(lobby) == OK, "The editable layout must remain saveable.")
	var path := "user://editable_lobby_test.tscn"
	_check(ResourceSaver.save(packed, path) == OK, "Godot must save layout edits.")
	var restored = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	_check(restored.get_node("Architecture/Walls/Wall01").position.is_equal_approx(edited_wall), "Wall changes must survive a save and reload.")
	_check(restored.get_node("Doors/Door2").position.is_equal_approx(edited_door), "Door changes must survive a save and reload.")
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("Editable lobby tests: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
