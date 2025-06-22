extends Control

@onready var start_button = $Button
@onready var title_camera = $TitleScreenCamera

func _ready():
	title_camera.make_current()
	# _on_start_button_pressed()


func _on_button_pressed() -> void:
	print("Start button pressed!")
	get_tree().change_scene_to_file("res://control.tscn")
