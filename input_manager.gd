extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Mouse clicked at: ", event.position)
		

func _on_game_title_meta_clicked(meta: Variant) -> void:
	print("Game title clicked")


func _on_title_screen_2_gui_input(event: InputEvent) -> void:
	print("Titlescreen node clicked")
