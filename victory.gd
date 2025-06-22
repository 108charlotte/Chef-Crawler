extends Control

@onready var start_button = $Button
@onready var title_camera = $VictoryScreenCamera

func _ready():
	title_camera.make_current()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://control.tscn")
