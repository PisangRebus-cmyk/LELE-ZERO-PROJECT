extends Node

const SavePath := "user://save.json"
const AutosaveInterval := 10.0

var _timer := Timer.new()


func _ready() -> void:
	_timer.wait_time = AutosaveInterval
	_timer.one_shot = false
	_timer.timeout.connect(save_game)
	add_child(_timer)


func start_autosave() -> void:
	_timer.start()


func stop_autosave() -> void:
	_timer.stop()


func has_save() -> bool:
	return FileAccess.file_exists(SavePath)


func save_game(extra: Dictionary = {}) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == "":
		return
	var data := extra.duplicate()
	data["scene"] = scene.scene_file_path
	var f := FileAccess.open(SavePath, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SavePath, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("scene"):
		return {}
	return data
