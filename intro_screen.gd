extends Control

@onready var game = get_parent()
@onready var world = game.get_node("World")
@onready var stats = game.get_node("Stats")
@onready var start_button = $StartButton

func _ready():
	world.visible = false
	stats.visible = false
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed(): 
	visible = false

	world.visible = true
	stats.visible = true
