extends Area3D

signal activated

var prompt: String = ""
var enabled: bool = true
var caption: Label3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.5, 0.25)
	collider.shape = shape
	add_child(collider)
	caption = Label3D.new()
	caption.position = Vector3(0, 0.1, 0.18)
	caption.font_size = 34
	caption.pixel_size = 0.003
	caption.modulate = Color("d9b98c")
	caption.text = prompt
	add_child(caption)


func set_focused(value: bool) -> void:
	caption.modulate = Color("fff0cb") if value else Color("d9b98c")
	caption.outline_modulate = Color("332416") if value else Color("080b10")


func activate() -> void:
	if enabled:
		activated.emit()


func set_prompt(value: String) -> void:
	prompt = value
	if is_instance_valid(caption):
		caption.text = prompt
