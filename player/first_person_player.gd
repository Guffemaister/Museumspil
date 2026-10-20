extends CharacterBody3D

@export_range(0.1, 8.0) var walk_speed: float = 2.4
@export_range(0.0001, 0.02) var mouse_sensitivity: float = 0.0022
@export_range(0.0, 0.5) var step_height: float = 0.32
@export var spawn_marker: NodePath
@export var capture_hint: NodePath

var pitch: float = 0.0
var mouse_captured: bool = false
var head_home: Vector3
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera


func _ready() -> void:
	head_home = head.rotation
	pitch = head_home.x
	camera.current = true
	return_to_start()
	_update_hint()


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if mouse_captured:
		direction = Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
	var movement := global_basis * Vector3(direction.x, 0, direction.y)
	velocity.x = movement.x * walk_speed
	velocity.z = movement.z * walk_speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	# Lift only over a low obstacle with clear space above it, e.g. a walkway edge.
	var motion := Vector3(velocity.x, 0, velocity.z) * delta
	if is_on_floor() and motion.length_squared() > 0.000001 and test_move(global_transform, motion):
		var raised := global_transform.translated(Vector3.UP * step_height)
		if not test_move(global_transform, Vector3.UP * step_height) and not test_move(raised, motion):
			global_position.y += step_height
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_capture_mouse(true)
	elif event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		head.rotation.x = pitch
	elif event.is_action_pressed("ui_cancel"):
		_capture_mouse(false)
	elif event.is_action_pressed("return_to_start"):
		return_to_start()


func return_to_start() -> void:
	var spawn := get_node_or_null(spawn_marker) as Marker3D
	if spawn != null:
		global_transform = spawn.global_transform
	velocity = Vector3.ZERO
	head.rotation = head_home
	pitch = head_home.x


func _update_hint() -> void:
	var hint := get_node_or_null(capture_hint) as Control
	if hint != null:
		hint.visible = not mouse_captured


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_capture_mouse(false)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _capture_mouse(value: bool) -> void:
	mouse_captured = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	_update_hint()
