extends Node

@export var room_ambience_db: float = -36.0
@export var breath_end_db: float = -60.0
var ambience: AudioStreamPlayer
var breathing: AudioStreamPlayer
var lobby_ambience_db: float
var breath_start_db: float


func _ready() -> void:
	ambience = $Ambience
	breathing = $Breathing
	lobby_ambience_db = ambience.volume_db
	breath_start_db = breathing.volume_db


func begin_breathing() -> void:
	breathing.volume_db = breath_start_db
	breathing.play()


func set_breath_progress(value: float) -> void:
	breathing.volume_db = lerpf(breath_start_db, breath_end_db, value * value)


func stop_breathing() -> void:
	breathing.stop()


func _exit_tree() -> void:
	for source in [ambience, breathing]:
		if is_instance_valid(source):
			source.stop()
			source.stream = null
