extends Node

var press_count: int = 0

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	status_label.text = "Godot test works!\nThis script was added by ChatGPT.\nPress Space or Enter to test input."
	print("Godot test works! Tester.gd loaded successfully.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		press_count += 1
		status_label.text = "Input works! You pressed Space or Enter %d time(s)." % press_count
		print("Input test passed: %d" % press_count)
