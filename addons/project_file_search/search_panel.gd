## The name is long because you might already have a "SearchPanel" in your project,
## but if you've already got a "HauntedBeesProjectSearchPanel" then that's really weird.
@tool class_name HauntedBeesProjectSearchPanel extends PopupPanel

const SETTING_CHAR_LIMIT := "addons/project_file_search/character_search_limit"
const SETTING_INCLUDED_FILE_FORMATS := "addons/project_file_search/included_file_formats"
const SETTING_KEYBOARD_SHORTCUT := "addons/project_file_search/keyboard_shortcut"

const _RESULT_SCENE := preload("./search_result.tscn")

signal open_file(path: String)

var _has_results := false
var _selected_idx := 0
var _search_chars := 4
var _valid_file_formats: PackedStringArray = []

@onready var _search_box: TextEdit = %SearchBox
@onready var _results_container: VBoxContainer = %SearchResultsContainer
@onready var _scroll_container: ScrollContainer = %ScrollContainer

func _ready() -> void:
	_search_box.grab_focus()
	_search_chars = ProjectSettings.get_setting(SETTING_CHAR_LIMIT, 5)
	_valid_file_formats = ProjectSettings.get_setting(SETTING_INCLUDED_FILE_FORMATS, [])

func _input(event: InputEvent) -> void:
	var iek := event as InputEventKey
	if !iek:
		return
	if iek.is_action_pressed("ui_down"):
		_update_selection(_selected_idx + 1)
	elif iek.is_action_pressed("ui_up"):
		_update_selection(_selected_idx - 1)
	if iek.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_open_selected_file()

func _open_selected_file() -> void:
	var res: HauntedBeesProjectSearchResult = _results_container.get_child(_selected_idx)
	if !res:
		return
	open_file.emit("res://%s" % res.file_path)

func _on_search_box_text_changed() -> void:
	for r in _results_container.get_children():
		_results_container.remove_child(r)
		r.queue_free()
	_has_results = false
	var search_query := _search_box.text
	if search_query.length() < _search_chars:
		var l := Label.new()
		l.text = "Please type at least %s characters to search." % _search_chars
		_results_container.add_child(l)
		return
	var results := _get_matching_paths(search_query.to_lower())
	for i in results.size():
		var res: HauntedBeesProjectSearchResult = _RESULT_SCENE.instantiate()
		res.hovered.connect(_update_selection.bind(i))
		res.clicked.connect(_open_selected_file)
		_results_container.add_child(res)
		res.file_path = results[i]
	if results.size() == 0:
		var l := Label.new()
		l.text = "No results found for \"%s.\"" % search_query
		_results_container.add_child(l)
		return
	_has_results = true
	_update_selection.call_deferred(0, true)

func _update_selection(new_value: int, first := false) -> void:
	if !_has_results:
		return
	var count := _results_container.get_child_count()
	if count <= 0:
		return
	if new_value < 0 || new_value >= count:
		new_value = posmod(new_value, count)
	if !first:
		var old_sel: HauntedBeesProjectSearchResult = _results_container.get_child(_selected_idx)
		old_sel.unselect()
	_selected_idx = new_value
	var new_sel: HauntedBeesProjectSearchResult = _results_container.get_child(_selected_idx)
	if new_sel:
		new_sel.select()
		_scroll_container.ensure_control_visible(new_sel)

func _get_matching_paths(query: String) -> Array[String]:
	var paths: Array[String] = []
	_recurse(paths, query)
	return paths

func _recurse(results: Array[String], query: String, directory: String = "res://") -> void:
	if !directory.ends_with("/"):
		directory += "/"
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while !item.is_empty():
		var full_name := "%s%s" % [directory, item]
		if dir.current_is_dir():
			if item != "." && item != ".." && item != "addons":
				_recurse(results, query, full_name)
		elif full_name.containsn(query) && _is_valid_file(item):
			results.append(full_name)
		item = dir.get_next()

func _is_valid_file(name: String) -> bool:
	for e in _valid_file_formats:
		if name.ends_with(e):
			return true
	return false
