extends Node
## Autoload "SaveManager". Menyimpan scene, posisi player1 dan ghost, serta health (kalau ada).
## Daftarkan di Project Settings -> Globals -> Autoload dengan nama: SaveManager

const SAVE_PATH := "user://save.json"

var pending_data := {}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	# Musuh dan fase pertarungan tidak disimpan, jadi tolak save saat combat berlangsung
	for node in get_tree().get_nodes_in_group("NoContactDamage"):
		if node is Combat and node.is_combat:
			return false

	var data := {"scene": get_tree().current_scene.scene_file_path}
	var player1 := get_tree().get_first_node_in_group("Player") as Node2D
	var ghost := get_tree().get_first_node_in_group("Ghost") as Node2D
	if player1:
		data["player1"] = _snapshot(player1)
	if ghost:
		data["ghost"] = _snapshot(ghost)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: gagal menulis save (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("scene"):
		push_error("SaveManager: file save rusak")
		return false

	pending_data = parsed
	get_tree().change_scene_to_file(pending_data["scene"])
	# Tunggu scene baru siap (perpindahan scene terjadi setelah frame ini)
	await get_tree().process_frame
	await get_tree().process_frame
	_apply(pending_data)
	pending_data = {}
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _snapshot(node: Node2D) -> Dictionary:
	var d := {"x": node.global_position.x, "y": node.global_position.y}
	if "health" in node:
		d["health"] = node.health
	return d


func _apply(data: Dictionary) -> void:
	_restore(get_tree().get_first_node_in_group("Player"), data.get("player1", {}))
	_restore(get_tree().get_first_node_in_group("Ghost"), data.get("ghost", {}))


func _restore(node: Node, d: Dictionary) -> void:
	if node == null or d.is_empty():
		return
	(node as Node2D).global_position = Vector2(d["x"], d["y"])
	if d.has("health") and "health" in node:
		node.health = d["health"]
