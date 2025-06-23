extends Control

@onready var icon = $Icon
@onready var count_label = $CountLabel

func set_item(texture: Texture2D, count: int):
	icon.texture = texture
	count_label.text = str(count)
	count_label.visible = count > 1

func _ready():
	print("Icon node is: ", icon)
	print("CountLabel node is: ", count_label)
