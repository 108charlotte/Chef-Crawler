extends RichTextLabel

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("GameTitle clicked at: ", event.position)
