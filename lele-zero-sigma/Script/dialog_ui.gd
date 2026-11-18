extends CanvasLayer

signal dialog_started
signal dialog_finished

@export_group("Karakter")
@export var name_a := "Lele"
@export var portrait_a: Texture2D
@export var name_b := "Zero"
@export var portrait_b: Texture2D

@export_group("Perilaku")
@export var text_speed := 45.0        
@export var allow_skip_with_esc := true 
@export var skip_if_seen := true        
@export_group("Tampilan")
@export var box_color := Color(0.05, 0.05, 0.08, 0.92)
@export var accent_color := Color(0.9, 0.1, 0.2)
@export var dim_color := Color(0.35, 0.35, 0.4, 1.0)
@export var portrait_size := Vector2(200, 260)
@export var font_size := 20
@export var name_font_size := 22

var _root: Control
var _box: PanelContainer
var _name_label: Label
var _text_label: RichTextLabel
var _next_icon: Label
var _portrait_a: TextureRect
var _portrait_b: TextureRect

var _lines: Array = []
var _index := -1
var _active := false
var _typing := false
var _was_paused := false
var _tween: Tween
var _seen: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()


# ---------------------------------------------------------------- API publik

func start(lines: Array, id: String = "") -> void:
	if _active:
		return
	if id != "":
		if skip_if_seen and _seen.has(id):
			dialog_finished.emit()
			return
		_seen[id] = true
	if lines.is_empty():
		dialog_finished.emit()
		return

	_lines = lines
	_index = -1
	_active = true
	_refresh_portraits()

	_was_paused = get_tree().paused
	get_tree().paused = true
	_root.show()
	dialog_started.emit()
	_next_line()


func skip_all() -> void:
	if not _active:
		return
	if _tween:
		_tween.kill()
	_finish()


func is_active() -> bool:
	return _active


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		# selalu diambil supaya pause menu tidak terbuka saat dialog
		get_viewport().set_input_as_handled()
		if allow_skip_with_esc:
			skip_all()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if _typing:
		if _tween:
			_tween.kill()
		_finish_typing()
	else:
		_next_line()


# ---------------------------------------------------------------- alur dialog

func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[_index]
	var speaker: String = str(line.get("name", ""))

	_name_label.text = speaker
	_name_label.visible = speaker != ""
	_text_label.text = str(line.get("text", ""))
	_text_label.visible_ratio = 0.0
	_next_icon.hide()
	_set_speaker(speaker)

	var total := _text_label.get_total_character_count()
	if _tween:
		_tween.kill()
	if text_speed <= 0.0 or total <= 0:
		_finish_typing()
		return

	_typing = true
	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_ratio", 1.0, total / text_speed)
	_tween.finished.connect(_finish_typing)


func _finish_typing() -> void:
	_typing = false
	_text_label.visible_ratio = 1.0
	_next_icon.show()


func _finish() -> void:
	_active = false
	_typing = false
	_root.hide()
	# jeda singkat supaya klik terakhir tidak ikut jadi serangan player
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().paused = _was_paused
	dialog_finished.emit()


# ---------------------------------------------------------------- potret

func _refresh_portraits() -> void:
	_portrait_a.texture = portrait_a
	_portrait_b.texture = portrait_b
	_portrait_a.visible = portrait_a != null
	_portrait_b.visible = portrait_b != null


func _set_speaker(speaker: String) -> void:
	_focus_portrait(_portrait_a, speaker == name_a)
	_focus_portrait(_portrait_b, speaker == name_b)


func _focus_portrait(p: TextureRect, focused: bool) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(p, "modulate", Color.WHITE if focused else dim_color, 0.15)
	t.tween_property(p, "scale", Vector2.ONE if focused else Vector2(0.9, 0.9), 0.15)


func _make_portrait() -> TextureRect:
	var r := TextureRect.new()
	r.custom_minimum_size = portrait_size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.pivot_offset = Vector2(portrait_size.x * 0.5, portrait_size.y)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ---------------------------------------------------------------- bangun UI

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	_root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)

	# ruang kosong di atas (mendorong potret dan kotak teks ke bawah)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# baris potret: kiri bawah, tepat di atas kotak teks
	var portrait_row := HBoxContainer.new()
	portrait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_row.add_theme_constant_override("separation", 8)
	vbox.add_child(portrait_row)
	_portrait_a = _make_portrait()
	_portrait_b = _make_portrait()
	portrait_row.add_child(_portrait_a)
	portrait_row.add_child(_portrait_b)

	# kotak teks
	_box = PanelContainer.new()
	_box.custom_minimum_size = Vector2(0, 130)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = box_color
	style.border_color = accent_color
	style.border_width_top = 4
	style.set_content_margin_all(16)
	_box.add_theme_stylebox_override("panel", style)
	vbox.add_child(_box)

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 6)
	_box.add_child(inner)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	_name_label.add_theme_color_override("font_color", accent_color)
	inner.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.custom_minimum_size = Vector2(0, 72)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", font_size)
	_text_label.add_theme_color_override("default_color", Color.WHITE)
	inner.add_child(_text_label)

	_next_icon = Label.new()
	_next_icon.text = "▼"
	_next_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next_icon.add_theme_color_override("font_color", accent_color)
	inner.add_child(_next_icon)

	var blink := create_tween().set_loops()
	blink.tween_property(_next_icon, "modulate:a", 0.2, 0.5)
	blink.tween_property(_next_icon, "modulate:a", 1.0, 0.5)
