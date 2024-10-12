@tool class_name HauntedBeesProjectSearchResult extends MarginContainer

signal hovered()
signal clicked()

var file_path: String = "":
	set(value):
		file_path = value.replace("res://", "")
		var split := file_path.split("/")
		_name.text = split[-1]
		split.remove_at(split.size() - 1)
		_path.text = "/".join(split)

@onready var _name: Label = %Name
@onready var _path: Label = %Path
@onready var _background: ColorRect = %Background

func _ready() -> void:
	var name_size := _name.get_theme_font_size("font_size")
	_path.add_theme_font_size_override("font_size", roundi(name_size * 0.9))
	var name_color := _name.get_theme_color("font_color")
	name_color.a *= 0.8
	_path.add_theme_color_override("font_color", name_color)

func select() -> void:
	_background.color.a = 0.4

func unselect() -> void:
	_background.color.a = 0.0

func _on_gui_input(event: InputEvent) -> void:
	var iemb := event as InputEventMouseButton
	if !iemb:
		return
	if iemb.pressed && iemb.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _on_mouse_entered() -> void:
	select()
	hovered.emit()

func _on_mouse_exited() -> void:
	unselect()
