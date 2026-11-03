extends CharacterBody3D

@export_range(0.1, 12.0) var speed: float = 3.0
@export_range(0.1, 80.0) var fall_acceleration: float = 20.0
@export_range(0.0001, 0.02) var mouse_sensitivity: float = 0.0022
@export var capture_mouse_on_start: bool = true
@export_node_path("Marker3D") var spawn_marker: NodePath

var mouse_captured: bool = false
var pitch: float = 0.0
var starting_transform: Transform3D
var head_rotation: Vector3
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	starting_transform = global_transform
	head_rotation = head.rotation
	pitch = head_rotation.x
	return_to_start()
	camera.make_current()
	_capture_mouse(capture_mouse_on_start)


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if mouse_captured:
		direction = Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
	var movement := global_basis.orthonormalized() * Vector3(direction.x, 0, direction.y)
	velocity.x = movement.x * speed
	velocity.z = movement.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= fall_acceleration * delta
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
	global_transform = spawn.global_transform if spawn != null else starting_transform
	velocity = Vector3.ZERO
	head.rotation = head_rotation
	pitch = head_rotation.x


func _capture_mouse(value: bool) -> void:
	mouse_captured = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_capture_mouse(false)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
