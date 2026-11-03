extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("Player tests timed out")
		quit(1))
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for i in range(count): await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func reset(player: CharacterBody3D) -> void:
	key(KEY_R,true)
	key(KEY_R,false)
	await frames(8)

func _run() -> void:
	var map = load("res://cistern/CisternMap.tscn").instantiate()
	check(map.has_node("Floor/Floor mesh/StaticBody3D/CollisionShape3D"),"F5's map must include the user's floor and collision")
	check(map.get_node("Player") is CharacterBody3D,"The user's player must be a CharacterBody3D")
	check(map.has_node("Player/CollisionShape3D") and map.has_node("Player/BodyMesh") and map.has_node("Player/Head/Camera3D"),"Player body, collision and camera must be saved editable nodes")
	var count: int = map.find_children("*","Node",true,false).size()
	root.add_child(map)
	await frames(10)
	var player: CharacterBody3D = map.get_node("Player")
	var spawn: Marker3D = map.get_node("FuturePlayerSpawn")
	check(map.find_children("*","Node",true,false).size()==count,"The controller must not create nodes at startup")
	check(player.is_on_floor(),"The player must stand on the visible floor")
	check(absf(player.position.y)<0.015,"The rotated floor instance must put its surface at the map's floor height")
	check(Vector2(player.position.x,player.position.z).distance_to(Vector2(spawn.position.x,spawn.position.z))<0.01,"The player must use the editable map spawn")
	check(player.camera.is_current(),"The player's camera must replace the static preview camera")
	check(player.mouse_captured,"F5 must enable walking immediately")
	check((player.camera.cull_mask & player.get_node("BodyMesh").layers)==0,"The camera must not clip inside its own body mesh")
	check((player.camera.cull_mask & 2)!=0,"Hiding the body must preserve the map's water layer")

	var start := player.position
	key(KEY_W,true)
	await frames(30)
	key(KEY_W,false)
	var walked: float = start.distance_to(player.position)
	check(player.position.z < start.z-1.0,"Physical W input must move forward")
	check(absf(player.position.x-start.x)<0.03,"Forward movement must not drift sideways")
	await reset(player)
	check(Vector2(player.position.x,player.position.z).distance_to(Vector2(spawn.position.x,spawn.position.z))<0.02,"R must return to the editable spawn")
	start = player.position
	key(KEY_W,true)
	key(KEY_D,true)
	await frames(30)
	key(KEY_W,false)
	key(KEY_D,false)
	check(absf(start.distance_to(player.position)-walked)<0.12,"Diagonal input must not increase walking speed")
	check(player.position.x>start.x+0.5 and player.position.z<start.z-0.5,"Combined W/D input must move diagonally")
	await reset(player)
	player.rotation.y = PI/2
	start = player.position
	key(KEY_W,true)
	await frames(20)
	key(KEY_W,false)
	check(player.position.x<start.x-0.7 and absf(player.position.z-start.z)<0.03,"Walking must follow the player's facing direction")
	await reset(player)
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(100,-40)
	player._unhandled_input(mouse)
	check(player.rotation.y< -0.1 and player.head.rotation.x>0.05,"Mouse motion must turn the body and tilt the head")
	mouse.relative = Vector2(0,-100000)
	player._unhandled_input(mouse)
	check(player.head.rotation.x<=1.4,"Looking up must be clamped")
	mouse.relative = Vector2(0,100000)
	player._unhandled_input(mouse)
	check(player.head.rotation.x>=-1.4,"Looking down must be clamped")
	await reset(player)
	check(absf(player.head.rotation.x)<0.001,"Returning to spawn must reset the view")

	# Test actual saved pillar, wall, and floor collisions.
	player.position = Vector3(2.25,0.04,23.5)
	player.rotation = Vector3.ZERO
	await frames(8)
	key(KEY_W,true)
	await frames(60)
	key(KEY_W,false)
	check(player.position.z>22.1,"The capsule must not pass through a pillar")
	player.position = Vector3(15.3,0.05,24.0)
	await frames(8)
	key(KEY_D,true)
	await frames(40)
	key(KEY_D,false)
	check(player.position.x<15.8,"The capsule must not pass through the outer wall")
	check(player.is_on_floor(),"The floor must support the player near the outer wall")

	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	check(not player.mouse_captured,"Esc must release mouse look")
	start = player.position
	key(KEY_W,true)
	await frames(10)
	key(KEY_W,false)
	check(player.position.distance_to(start)<0.03,"Releasing the mouse must stop walking")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player._unhandled_input(click)
	check(player.mouse_captured,"Click must resume mouse look")
	player._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not player.mouse_captured,"Losing window focus must release controls")
	player._unhandled_input(click)

	# Save/reload proves that Inspector edits survive startup and that spawn
	# coordinates continue working when the entire map is moved and rotated.
	map.position = Vector3(4,0,8)
	map.rotation.y = 0.3
	spawn.position.x = 0.35
	spawn.rotation.y = 0.2
	player.speed = 4.0
	player.camera.fov = 80.0
	player.get_node("CollisionShape3D").shape = player.get_node("CollisionShape3D").shape.duplicate()
	player.get_node("CollisionShape3D").shape.radius = 0.28
	var packed := PackedScene.new()
	check(packed.pack(map)==OK,"The complete edited map and player must pack")
	var path := "user://player_edit_test.tscn"
	check(ResourceSaver.save(packed,path)==OK,"Godot must save player edits")
	map.queue_free()
	await frames()
	var loaded = ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	root.add_child(loaded)
	await frames(10)
	player = loaded.get_node("Player")
	spawn = loaded.get_node("FuturePlayerSpawn")
	check(is_equal_approx(player.speed,4.0) and is_equal_approx(player.camera.fov,80.0),"Inspector speed and camera edits must survive save/reload")
	check(is_equal_approx(player.get_node("CollisionShape3D").shape.radius,0.28),"Collision shape edits must survive startup")
	check(Vector2(player.global_position.x,player.global_position.z).distance_to(Vector2(spawn.global_position.x,spawn.global_position.z))<0.02,"The player must follow a moved and rotated map's spawn")
	check(is_equal_approx(player.global_rotation.y,spawn.global_rotation.y),"Spawn orientation must work in a rotated map")
	check(player.camera.is_current() and player.is_on_floor(),"The reloaded player must have a working camera and grounded body")
	loaded.queue_free()
	await frames()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Player tests: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
