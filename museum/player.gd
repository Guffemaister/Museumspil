extends Node3D

signal status_changed(text: String)
signal return_requested

@export_range(0.1, 10.0) var movement_speed: float = 2.4
@export_range(0.5, 10.0) var interaction_reach: float = 4.0
@export var movement_bounds: Rect2 = Rect2(-5.3, -6.3, 10.6, 12.6)

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
var camera_home_rotation: Vector3
var snap_ready: bool = true
var beam: MeshInstance3D
var mouse_captured: bool = false
var locomotion_enabled: bool = true
var interaction_enabled: bool = true
var xr_movement_constraint: Callable
var sequence_motion_active: bool = false
var sequence_home: Transform3D
var sequence_locomotion_enabled: bool = true


func _ready() -> void:
	desktop = $Desktop
	camera = $Desktop/Camera
	camera_home_rotation = camera.rotation
	pitch = camera_home_rotation.x
	origin = $XROrigin
	head = $XROrigin/Head
	left_hand = $XROrigin/LeftHand
	right_hand = $XROrigin/RightHand
	beam = $XROrigin/RightHand/AimRay
	right_hand.button_pressed.connect(_on_xr_button)
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


func _physics_process(delta: float) -> void:
	if sequence_motion_active:
		desktop.velocity = Vector3.ZERO
	elif xr_active:
		_move_xr(delta)
	else:
		_move_desktop(delta)
	_update_focus()
	if is_instance_valid(held):
		var source: Node3D = right_hand if xr_active else camera
		held.global_transform = source.global_transform.translated_local(Vector3(0.18, -0.15, -0.65))


func _move_desktop(delta: float) -> void:
	var direction := Vector2.ZERO
	if mouse_captured and locomotion_enabled:
		direction = Input.get_vector("museum_left", "museum_right", "museum_forward", "museum_back")
	var movement := desktop.basis * Vector3(direction.x, 0, direction.y)
	desktop.velocity.x = movement.x * movement_speed
	desktop.velocity.z = movement.z * movement_speed
	if not desktop.is_on_floor():
		desktop.velocity.y -= 9.8 * delta
	else:
		desktop.velocity.y = 0.0
	desktop.move_and_slide()


func _move_xr(delta: float) -> void:
	var stick := left_hand.get_vector2("primary")
	if stick.length() > 0.2 and locomotion_enabled:
		var forward := -head.global_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right := forward.cross(Vector3.UP)
		var motion := (right * stick.x + forward * stick.y) * movement_speed * delta
		# Test the tracked head's floor position against scene colliders.
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = desktop.get_node("CollisionShape3D").shape
		query.transform = Transform3D(Basis.IDENTITY, Vector3(head.global_position.x, origin.global_position.y + 0.9, head.global_position.z))
		query.motion = motion
		query.collision_mask = 1
		query.exclude = [desktop.get_rid()]
		var safe := get_world_3d().direct_space_state.cast_motion(query)
		var destination := origin.global_position + motion * safe[0]
		if xr_movement_constraint.is_valid():
			destination = xr_movement_constraint.call(destination)
		else:
			destination.x = clampf(destination.x, movement_bounds.position.x, movement_bounds.end.x)
			destination.z = clampf(destination.z, movement_bounds.position.y, movement_bounds.end.y)
		origin.global_position = destination
	var turn := right_hand.get_vector2("primary").x
	if absf(turn) < 0.3:
		snap_ready = true
	elif absf(turn) > 0.7 and snap_ready and locomotion_enabled:
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
	if is_instance_valid(held) or not interaction_enabled:
		return
	if xr_active and not right_hand.get_is_active():
		return
	var source: Node3D = right_hand if xr_active else camera
	var start := source.global_position
	var query := PhysicsRayQueryParameters3D.create(start, start - source.global_basis.z * interaction_reach, 3)
	query.collide_with_areas = true
	query.exclude = [desktop.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is Area3D and (hit.collider.has_method("pick_up") or hit.collider.has_method("activate")):
		focused = hit.collider
		focused.set_focused(true)


func interact() -> void:
	if not interaction_enabled:
		return
	if is_instance_valid(held):
		held.return_to_display()
		held = null
		status_changed.emit("Returned to its display. Find another exhibit!")
	elif is_instance_valid(focused):
		if focused.has_method("activate"):
			focused.activate()
			return
		held = focused
		focused.set_focused(false)
		focused = null
		held.pick_up()
		status_changed.emit(held.title + "\n" + held.description)


func _on_xr_button(button: String) -> void:
	if xr_active and button == "trigger_click":
		interact()
	elif xr_active and button == "by_button":
		return_requested.emit()


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
		elif event.physical_keycode == KEY_R or event.keycode == KEY_R:
			return_requested.emit()


func relocate(feet: Vector3, yaw: float = 0.0) -> void:
	end_sequence_motion()
	# Preserve the tracked head height and compensate for room-scale X/Z offsets.
	origin.global_rotation = Vector3(0, yaw, 0)
	var offset := head.global_position - origin.global_position
	origin.global_position = feet - Vector3(offset.x, 0, offset.z)
	desktop.global_position = feet
	desktop.global_rotation = Vector3(0, yaw, 0)
	desktop.velocity = Vector3.ZERO
	camera.rotation = camera_home_rotation
	pitch = camera_home_rotation.x
	if is_instance_valid(focused):
		focused.set_focused(false)
	focused = null


func viewer_position() -> Vector3:
	return head.global_position if xr_active else camera.global_position


func begin_sequence_motion() -> void:
	if sequence_motion_active:
		return
	sequence_home = global_transform
	sequence_locomotion_enabled = locomotion_enabled
	sequence_motion_active = true
	locomotion_enabled = false
	desktop.velocity = Vector3.ZERO


func set_sequence_offset(offset: Vector3) -> void:
	if sequence_motion_active:
		# Move the complete rig so live headset/controller poses remain relative to it.
		global_position = sequence_home.origin + offset


func end_sequence_motion() -> void:
	if not sequence_motion_active:
		return
	global_transform = sequence_home
	sequence_motion_active = false
	locomotion_enabled = sequence_locomotion_enabled
	desktop.velocity = Vector3.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not xr_active:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func fade_surface() -> StandardMaterial3D:
	var viewer: Camera3D = head if xr_active else camera
	return viewer.get_node("Fade").material_override
