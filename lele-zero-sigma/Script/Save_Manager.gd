extends Node

const SavePath := "user://save.json"
const AutosaveInterval := 10.0

# Scene pertama game (dipakai Retry). Sesuaikan dengan path level / start menu kamu
var first_scene := "res://Scene/Level_1.tscn"

# Progress player yang dibawa antar scene
var has_saved := false
var player_health := 200.0
var player_max_health := 200.0
var player_speed := 100
var attack_mult := 1.0

var _timer := Timer.new()
var _changing := false
var _fade: ColorRect


func _ready() -> void:
	_timer.wait_time = AutosaveInterval
	_timer.one_shot = false
	_timer.timeout.connect(save_game)
	add_child(_timer)

	# Layar hitam untuk fade saat pindah lantai
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


# ================= AUTOSAVE & FILE SAVE =================
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
	# Ambil kondisi player terbaru; jangan simpan kalau player sedang mati
	var p := get_tree().get_first_node_in_group("Player")
	if p:
		if p.get("is_dead"):
			return
		save_from(p)
	var data := extra.duplicate()
	data["scene"] = scene.scene_file_path
	if has_saved:
		data["player"] = {
			"health": player_health,
			"max_health": player_max_health,
			"speed": player_speed,
			"attack_mult": attack_mult,
		}
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
	_apply_saved_player(data)
	return data


func _apply_saved_player(data: Dictionary) -> void:
	var pl = data.get("player")
	if typeof(pl) != TYPE_DICTIONARY:
		# Save lama tanpa data player: pakai nilai bawaan
		reset()
		return
	player_max_health = float(pl.get("max_health", 200.0))
	player_health = float(pl.get("health", player_max_health))
	player_speed = int(pl.get("speed", 100))
	attack_mult = float(pl.get("attack_mult", 1.0))
	has_saved = true


# ================= PROGRESS PLAYER =================
# Ambil kondisi player1 sekarang
func save_from(p: Node) -> void:
	player_health = p.health
	player_max_health = p.max_health
	player_speed = p.SPEED
	attack_mult = p.attack_mult
	has_saved = true


# Pasang kondisi tersimpan ke player1 di scene baru
func apply_to(p: Node) -> void:
	if not has_saved:
		return
	p.max_health = player_max_health
	p.health = player_health
	p.SPEED = player_speed
	p.attack_mult = attack_mult
	for atk in p.ATTACKS:
		atk.damage *= attack_mult


# Panggil dari tombol NEW di start menu supaya game baru mulai dari nol
func reset() -> void:
	has_saved = false
	player_health = 200.0
	player_max_health = 200.0
	player_speed = 100
	attack_mult = 1.0


# ================= PINDAH LANTAI =================
func change_floor(scene_path: String) -> void:
	if _changing or scene_path.is_empty():
		return
	var p := get_tree().get_first_node_in_group("Player")
	if p:
		save_from(p)
	_go_to(scene_path, true)


# Dipanggil tombol Retry di layar game over: mulai dari paling awal
func restart_game() -> void:
	if _changing:
		return
	reset()
	_go_to(first_scene, false)


func _go_to(scene_path: String, write_save: bool) -> void:
	_changing = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "modulate:a", 1.0, 0.4)
	await t.finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Gagal memuat scene: %s (error %d)" % [scene_path, err])
		_fade.modulate.a = 0.0
		_changing = false
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if write_save:
		save_game()

	t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_fade, "modulate:a", 0.0, 0.4)
	await t.finished
	_fade.modulate.a = 0.0
	_changing = false
