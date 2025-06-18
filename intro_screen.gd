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
	start_button.pressed.connect(_on_startButton_pressed)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Mouse button pressed at: ", event.position)

func _on_startButton_pressed() -> void:
	print("Start button pressed!")
	visible = false
	camera.make_current()
	print("current is now camera")

	world.visible = true
	stats.visible = true
	camera.zoom = Vector2(2,2)
	print(camera.zoom)
