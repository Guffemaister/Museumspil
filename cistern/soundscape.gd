extends Node

var ambience: AudioStreamPlayer
var breathing: AudioStreamPlayer
var bus_name: String = "CisternAmbience"
var owns_bus: bool = false


func _ready() -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		owns_bus = true
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.88
		reverb.damping = 0.6
		reverb.wet = 0.35
		AudioServer.add_bus_effect(index, reverb)
	ambience = AudioStreamPlayer.new()
	ambience.bus = bus_name
	ambience.stream = _tone(false)
	ambience.volume_db = -24
	add_child(ambience)
	ambience.play()
	breathing = AudioStreamPlayer.new()
	breathing.bus = bus_name
	breathing.stream = _tone(true)
	breathing.volume_db = -60
	add_child(breathing)


func begin_breathing() -> void:
	breathing.volume_db = -22
	breathing.play()


func set_breath_progress(value: float) -> void:
	breathing.volume_db = lerpf(-22.0, -60.0, value * value)


func stop_breathing() -> void:
	breathing.stop()


func _exit_tree() -> void:
	for source in [ambience, breathing]:
		if is_instance_valid(source):
			source.stop()
			source.stream = null
	var index := AudioServer.get_bus_index(bus_name)
	if owns_bus and index > 0:
		AudioServer.remove_bus(index)


func _tone(breath: bool) -> AudioStreamWAV:
	# Original synthesized sound only: no opera recordings or external assets.
	const RATE := 22050
	var seconds := 8.0
	var count := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 711
	var filtered_noise := 0.0
	for i in range(count):
		var t := float(i) / RATE
		var sample: float
		if breath:
			filtered_noise = lerpf(filtered_noise, random.randf_range(-1, 1), 0.14)
			var envelope := pow(maxf(0.0, sin(TAU * t / seconds)), 1.5)
			sample = filtered_noise * envelope * 0.75
		else:
			sample = (sin(TAU * 55.0 * t) * 0.18 + sin(TAU * 82.5 * t) * 0.08 + sin(TAU * 110 * t) * 0.03)
			sample *= 0.7 + 0.3 * sin(TAU * t / seconds)
		data.encode_s16(i * 2, int(clampf(sample, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream
