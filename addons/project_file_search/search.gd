@tool
extends EditorPlugin

const _SEARCH_SCENE := preload("./search_panel.tscn")

var _current_panel: HauntedBeesProjectSearchPanel = null

func _enter_tree() -> void:
	_bind_setting(4, {
		"name": HauntedBeesProjectSearchPanel.SETTING_CHAR_LIMIT,
		"type": TYPE_INT
	})
	_bind_setting([".tscn", ".gd", ".cs", ".tres", ".res", ".gdshader"], {
		"name": HauntedBeesProjectSearchPanel.SETTING_INCLUDED_FILE_FORMATS,
		"type": TYPE_PACKED_STRING_ARRAY
	})
	_bind_setting("Ctrl+,", {
		"name": HauntedBeesProjectSearchPanel.SETTING_KEYBOARD_SHORTCUT,
		"type": TYPE_STRING
	})

func _exit_tree() -> void:
	_clear_setting(HauntedBeesProjectSearchPanel.SETTING_CHAR_LIMIT)
	_clear_setting(HauntedBeesProjectSearchPanel.SETTING_INCLUDED_FILE_FORMATS)
	_clear_setting(HauntedBeesProjectSearchPanel.SETTING_KEYBOARD_SHORTCUT)
	if _current_panel:
		_current_panel.queue_free()
		_current_panel = null

func _input(event: InputEvent) -> void:
	if !_is_keyboard_shortcut(event as InputEventKey):
		return
	get_viewport().set_input_as_handled()
	var should_create := true
	if _current_panel:
		should_create = is_instance_valid(_current_panel) && _current_panel.is_inside_tree()
		_current_panel.queue_free()
		_current_panel = null
	if should_create:
		_current_panel = _SEARCH_SCENE.instantiate()
		_current_panel.open_file.connect(_open_file)
		add_child(_current_panel)
		_current_panel.popup_centered()

func _open_file(path: String) -> void:
	var ei := get_editor_interface()
	if path.ends_with(".tscn"):
		ei.open_scene_from_path(path)
	else:
		ei.edit_resource(load(path))
	if _current_panel:
		_current_panel.queue_free()
		_current_panel = null

func _bind_setting(default_value: Variant, info: Dictionary) -> void:
	ProjectSettings.set(info["name"], default_value)
	ProjectSettings.add_property_info(info)

func _clear_setting(name: String) -> void:
	ProjectSettings.clear(name)

func _is_keyboard_shortcut(i: InputEventKey) -> bool:
	if i == null || !i.pressed:
		return false
	var shortcut: String = ProjectSettings.get_setting(HauntedBeesProjectSearchPanel.SETTING_KEYBOARD_SHORTCUT, "Ctrl+,")
	var parts := shortcut.to_lower().split("+")
	for p in parts:
		match p:
			"ctrl":
				if !i.ctrl_pressed:
					return false
			"shift":
				if !i.shift_pressed:
					return false
			"alt":
				if !i.alt_pressed:
					return false
			"space":
				if i.keycode != KEY_SPACE:
					return false
			"enter":
				if i.keycode != KEY_ENTER:
					return false
			_:
				if p.length() > 1:
					printerr("Your keyboard shortcut %s is invalid." % shortcut)
					return false
				elif i.keycode > 1081 || String.chr(i.keycode) != p:
					return false
	return true
