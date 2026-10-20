extends Area3D

signal inspected(exhibit: Area3D)

@export var title: String = ""
@export_multiline var description: String = ""
@export_range(0.0, 3.0) var rotation_speed: float = 0.3
@export_range(0.0, 0.5) var bob_height: float = 0.045
var discovered: bool = false
var held: bool = false
var home: Transform3D
var visual: Node3D
var caption: Label3D
var time: float = 0.0
var visual_home: Vector3
var caption_color: Color


func _ready() -> void:
	home = global_transform
	visual = $Visual
	visual_home = visual.position
	caption = $Caption
	caption.text = title
	caption_color = caption.modulate


func _process(delta: float) -> void:
	time += delta
	if not held:
		visual.rotation.y += delta * rotation_speed
		visual.position.y = visual_home.y + sin(time * 1.5) * bob_height


func set_focused(focused: bool) -> void:
	caption.modulate = Color("73f2df") if focused else caption_color


func pick_up() -> void:
	held = true
	visual.position = visual_home
	caption.visible = false
	if not discovered:
		discovered = true
		inspected.emit(self)


func return_to_display() -> void:
	held = false
	global_transform = home
	caption.visible = true
