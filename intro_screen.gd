extends Control

@onready var game = get_parent()
@onready var world = game.get_node("World")
@onready var stats = game.get_node("Stats")

func _ready():
	world.visible = false
	stats.visible = false

	await get_tree().create_timer(5.0).timeout

	visible = false

	world.visible = true
	stats.visible = true
