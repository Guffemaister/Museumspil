extends Node3D

@export var progress_template: String = "DISCOVERED   {visited} / {total}"
@export var completion_text: String = "TOUR COMPLETE   /   ALL 3 ARTIFACTS DISCOVERED"
var hud_template: String

var player: Node3D
var exhibits: Array[Area3D] = []
var progress: Label3D
var information: Label3D
var hud: Label
var visited: int = 0


func _ready() -> void:
	player = $Player
	progress = $Signage/Progress
	information = $Signage/Information
	hud = $DesktopHUD/Screen/Information
	hud_template = hud.text
	$DesktopHUD.visible = not player.xr_active
	for artifact in $Exhibits.get_children():
		exhibits.append(artifact)
		artifact.inspected.connect(_on_inspected)
	player.status_changed.connect(_show_information)
	_refresh_progress()


func _on_inspected(_exhibit: Area3D) -> void:
	visited += 1
	_refresh_progress()
	if visited == exhibits.size():
		progress.modulate = Color("73f2df")
		print("Museum tour complete: all 3 artifacts discovered.")


func _refresh_progress() -> void:
	progress.text = progress_template.replace("{visited}", str(visited)).replace("{total}", str(exhibits.size()))
	if visited == exhibits.size():
		progress.text = completion_text
	if is_instance_valid(hud):
		hud.text = hud_template.replace("{visited}", str(visited)).replace("{total}", str(exhibits.size()))


func _show_information(text: String) -> void:
	information.text = text
