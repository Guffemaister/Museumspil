extends Area3D

signal activated

@export_multiline var prompt: String = ""
@export var enabled: bool = true
var caption: Label3D
var base_color: Color
var base_outline: Color


func _ready() -> void:
	caption = $Caption
	caption.text = prompt
	base_color = caption.modulate
	base_outline = caption.outline_modulate


func set_focused(value: bool) -> void:
	caption.modulate = Color("fff0cb") if value else base_color
	caption.outline_modulate = Color("332416") if value else base_outline


func activate() -> void:
	if enabled:
		activated.emit()


func set_prompt(value: String) -> void:
	prompt = value
	if is_instance_valid(caption):
		caption.text = prompt
