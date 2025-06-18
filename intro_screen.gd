extends Control

@onready var game = get_parent()
@onready var world = game.get_node("World")
@onready var stats = game.get_node("Stats")
@onready var start_button = $StartButton
@onready var camera = game.get_node("World/Player/Camera2D")

func _ready():
	world.visible = false
	stats.visible = false
	camera.zoom = Vector2(0.75,0.75)
	print(camera.zoom)

func _on_start_button_pressed(): 
	visible = false

	world.visible = true
	stats.visible = true
	camera.zoom = Vector2(2,2)
	print(camera.zoom)
