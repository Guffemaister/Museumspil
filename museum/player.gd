extends Node3D

signal status_changed(text: String)

const SPEED: float = 2.4
const REACH: float = 4.0

var xr_active: bool = false
var origin: XROrigin3D
var head: XRCamera3D
var left_hand: XRController3D
var right_hand: XRController3D
var desktop: CharacterBody3D
var camera: Camera3D
var focused: Area3D
var held: Area3D
var pitch: float = 0.0
var snap_ready: bool = true
var beam: MeshInstance3D
var mouse_captured: bool = false


func _ready() -> void:
	_build_desktop()
	_build_xr()
	var xr := XRServer.find_interface("OpenXR")
	if xr != null and xr.is_initialized():
		xr_active = true
		get_viewport().use_xr = true
		head.current = true
		desktop.get_node("CollisionShape3D").disabled = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		camera.current = true
		origin.visible = false
	print("Museum mode: ", "OpenXR" if xr_active else "Desktop")


func _build_desktop() -> void:
	desktop = CharacterBody3D.new()
	desktop.position = Vector3(0, 0, 3.5)
	add_child(desktop)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.85
	desktop.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.65
	camera.fov = 75.0
	desktop.add_child(camera)


func _build_xr() -> void:
	origin = XROrigin3D.new()
	origin.position = Vector3(0, 0, 3.5)
	add_child(origin)
	head = XRCamera3D.new()
	origin.add_child(head)
	left_hand = _controller("left_hand")
	right_hand = _controller("right_hand")
	right_hand.button_pressed.connect(_on_xr_button)
	beam = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.004
	mesh.bottom_radius = 0.004
	mesh.height = REACH
	beam.mesh = mesh
	beam.rotation.x = PI / 2.0
	beam.position.z = -REACH / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("73f2df")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	right_hand.add_child(beam)


func _controller(tracker_name: String) -> XRController3D:
	var controller := XRController3D.new()
	controller.tracker = tracker_name
	controller.pose = "aim"
	origin.add_child(controller)
	var model := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	model.mesh = mesh
	controller.add_child(model)
	return controller


func _physics_process(delta: float) -> void:
	if xr_active:
		_move_xr(delta)
	else:
		_move_desktop(delta)
	_update_focus()
	if is_instance_valid(held):
		var source: Node3D = right_hand if xr_active else camera
		held.global_transform = source.global_transform.translated_local(Vector3(0.18, -0.15, -0.65))


func _move_desktop(delta: float) -> void:
	var direction := Vector2.ZERO
	if mouse_captured:
		direction = Input.get_vector("museum_left", "museum_right", "museum_forward", "museum_back")
	var movement := desktop.basis * Vector3(direction.x, 0, direction.y)
	desktop.velocity.x = movement.x * SPEED
	desktop.velocity.z = movement.z * SPEED
	if not desktop.is_on_floor():
		desktop.velocity.y -= 9.8 * delta
	else:
		desktop.velocity.y = 0.0
	desktop.move_and_slide()


func _move_xr(delta: float) -> void:
	var stick := left_hand.get_vector2("primary")
	if stick.length() > 0.2:
		var forward := -head.global_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right := forward.cross(Vector3.UP)
		origin.position += (right * stick.x + forward * stick.y) * SPEED * delta
		origin.position.x = clampf(origin.position.x, -5.3, 5.3)
		origin.position.z = clampf(origin.position.z, -6.3, 6.3)
	var turn := right_hand.get_vector2("primary").x
	if absf(turn) < 0.3:
		snap_ready = true
	elif absf(turn) > 0.7 and snap_ready:
		snap_ready = false
		var angle := -signf(turn) * PI / 6.0
		var pivot := head.global_position
		var offset := origin.global_position - pivot
		origin.rotate_y(angle)
		origin.global_position = pivot + offset.rotated(Vector3.UP, angle)


func _update_focus() -> void:
	if is_instance_valid(focused):
		focused.set_focused(false)
	focused = null
	if is_instance_valid(held):
		return
	if xr_active and not right_hand.get_is_active():
		return
	var source: Node3D = right_hand if xr_active else camera
	var start := source.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - source.global_basis.z * REACH, 3)
	query.collide_with_areas = true
	query.exclude = [desktop.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is Area3D and hit.collider.has_method("pick_up"):
		focused = hit.collider
		focused.set_focused(true)


func interact() -> void:
	if is_instance_valid(held):
		held.return_to_display()
		held = null
		status_changed.emit("Returned to its display. Find another exhibit!")
	elif is_instance_valid(focused):
		held = focused
		focused.set_focused(false)
		focused = null
		held.pick_up()
		status_changed.emit(held.title + "\n" + held.description)


func _on_xr_button(button: String) -> void:
	if xr_active and button == "trigger_click":
		interact()


func _unhandled_input(event: InputEvent) -> void:
	if xr_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and mouse_captured:
		desktop.rotate_y(-event.relative.x * 0.0025)
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.35, 1.35)
		camera.rotation.x = pitch
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			mouse_captured = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_E or event.keycode == KEY_E:
			interact()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not xr_active:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
