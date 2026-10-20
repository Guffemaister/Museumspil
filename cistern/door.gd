extends Area3D

signal selected(door: Area3D)

@export_range(1, 7) var number: int = 1
@export var available: bool = false
var completed: bool = false
var is_open: bool = false
@export var title: String = ""
@export var theme: String = ""
var leaf: Node3D
var caption: Label3D
var frame_material: StandardMaterial3D
var hint: Label3D
var opening_tween: Tween
var closed_angle: float
@export_range(0.0, 180.0) var open_angle: float = 105.0
@export_range(0.1, 5.0) var opening_duration: float = 1.2


func _ready() -> void:
	leaf = $Leaf
	caption = $Number
	hint = $Hint
	frame_material = $FrameLeft.material_override
	closed_angle = leaf.rotation.y
	$Information.text = title + "\n" + theme
	_refresh_text()


func set_focused(value: bool) -> void:
	frame_material.emission_energy_multiplier = (0.8 if value else 0.3) if available else (0.25 if value else 0.08)
	if value:
		hint.text = ("Gå gennem døren" if is_open else "E / højre trigger · Åbn") if available else "Denne oplevelse kommer senere"
	else:
		_refresh_text()


func activate() -> void:
	selected.emit(self)
	if not available or is_open:
		return
	is_open = true
	opening_tween = create_tween()
	opening_tween.tween_property(leaf, "rotation:y", closed_angle + deg_to_rad(open_angle), opening_duration).set_trans(Tween.TRANS_SINE)
	_refresh_text()


func close() -> void:
	if opening_tween != null and opening_tween.is_valid():
		opening_tween.kill()
	is_open = false
	leaf.rotation.y = closed_angle
	_refresh_text()


func _refresh_text() -> void:
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII"]
	caption.text = numerals[number - 1]
	if available:
		hint.text = "Gå gennem døren" if is_open else ("OPLEVET · Besøg igen" if completed else "E / højre trigger · Åbn")
	else:
		hint.text = "KOMMER SENERE"
