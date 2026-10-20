extends Node3D

@export_group("Playback")
@export_range(1.0, 180.0) var duration: float = 48.0
@export var narrative: PackedStringArray = PackedStringArray([
	"Du er Violetta.\nDu hviler på lejet.",
	"Et åndedrag ind.\nEt åndedrag ud.",
	"Lyset holder fast.\nÅndedrættet bliver svagere.",
	"Der er næsten stille.",
	"Det sidste åndedrag.\nKun rummet bliver tilbage.",
])
@export_group("Navigation")
@export var movement_bounds: Rect2 = Rect2(-3.5, -4.5, 7.0, 7.0)
