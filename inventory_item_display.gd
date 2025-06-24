extends Control

@onready var icon = $Icon
@onready var count_label = $CountLabel
@onready var popup = $PopupPanel
@onready var highlight_border = $HighlightBorder

var is_edible: bool = false
var parent_ref: Node = null
var is_highlighted: bool = false
var item_count: int = 1
var type_id = null

func set_item(texture: Texture2D, count: int, edible := false, parent = null, type_id_value = null):
	icon.texture_normal = texture
	item_count = count
	count_label.text = str(count)
	count_label.visible = count > 1
	is_edible = edible
	parent_ref = parent
	type_id = type_id_value
	is_highlighted = false

func _on_icon_pressed():
	if parent_ref:
		parent_ref.item_clicked(self)

func show_popup_message(text: String):
	popup.get_node("Label").text = text
	popup.popup_centered()

func highlight(show: bool): 
	highlight_border.visible = show
	is_highlighted = show
