extends Control

@onready var game = get_parent()
@onready var world = game.get_node("World")
@onready var stats = game.get_node("Stats")
@onready var start_button = $StartButton
@onready var camera = game.get_node("World/Player/Camera2D")
@onready var title_camera = $TitleScreenCamera

func _ready():
	world.visible = false
	stats.visible = false
	title_camera.make_current()
	print("StartButton is: ", start_button)
	start_button.emit_signal("pressed")

func _on_start_button_pressed() -> void:
	print("Start button pressed!")
	visible = false
	camera.make_current()
	print("Is current: ", camera.is_current())

	world.visible = true
	stats.visible = true
	camera.zoom = Vector2(3, 3)
	print("Current zoom: ", camera.zoom)
