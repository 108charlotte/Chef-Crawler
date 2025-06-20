extends Control

@onready var start_button = $StartButton
@onready var title_camera = $TitleScreenCamera

func _ready():
	title_camera.make_current()
	print("StartButton is: ", start_button)
	_on_start_button_pressed()

func _on_start_button_pressed() -> void:
	print("Start button pressed!")
	get_tree().change_scene_to_file("res://credits.tscn")
