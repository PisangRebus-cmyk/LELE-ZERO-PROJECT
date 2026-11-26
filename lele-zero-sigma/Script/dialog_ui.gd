extends CanvasLayer

signal dialog_started
signal dialog_finished

@export_group("Karakter")
@export var name_a := "Zeke"
@export var portrait_a: Texture2D = preload("res://Assets/Sprites/UI_UX/concept 1-1.png.png")
@export var name_b := "Ghost"
@export var portrait_b: Texture2D = preload("res://Assets/Sprites/UI_UX/ghost potrait.png")

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
@export var tutorial_width := 720.0
@export var tutorial_height := 110.0
@export var talk_interval := 2
@export var talk_pitch_variation := 0.1
@export var hidden_offset_y := 2000.0
@export var slide_time := 0.25

var _root: Control
var _box: PanelContainer
var _box_style: StyleBoxFlat
var _portrait_row: HBoxContainer
var _name_label: Label
var _text_label: RichTextLabel
var _next_icon: Label
var _portrait_a: TextureRect
var _portrait_b: TextureRect

var _lines: Array = []
var _index := -1
var _active := false
var _typing := false
var _tutorial := false
var _was_paused := false
var _tween: Tween
var _slide_tween: Tween
var _talk_sound: AudioStreamPlayer2D
var _last_count := 0
var _seen: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialog_ui")
	_talk_sound = get_node_or_null("TalkSound")
	for child in get_children():
		if child != _talk_sound:
			child.queue_free()
	if _talk_sound:
		_talk_sound.attenuation = 0.0
		_talk_sound.max_distance = 1000000.0
	_build_ui()
	offset = Vector2(0, hidden_offset_y)


func start(lines: Array, id: String = "", tutorial: bool = false) -> void:
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
	_tutorial = tutorial
	_apply_mode()
	_refresh_portraits()

	_was_paused = get_tree().paused
	get_tree().paused = true
	_slide_to(Vector2.ZERO)
	dialog_started.emit()
	_next_line()


func start_tutorial(lines: Array, id: String = "") -> void:
	start(lines, id, true)


func skip_all() -> void:
	if not _active:
		return
	if _tween:
		_tween.kill()
	_finish()


func is_active() -> bool:
	return _active


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if allow_skip_with_esc:
			skip_all()
	elif _is_advance_event(event):
		get_viewport().set_input_as_handled()
		_advance()


func _is_advance_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if InputMap.has_action("attack") and event.is_action_pressed("attack"):
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


func _advance() -> void:
	if _typing:
		if _tween:
			_tween.kill()
		_finish_typing()
	else:
		_next_line()


func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[_index]
	var speaker: String = "" if _tutorial else str(line.get("name", ""))

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

	_last_count = 0
	_text_label.visible_characters = 0
	_typing = true
	_tween = create_tween()
	_tween.tween_method(_on_typing, 0, total, total / text_speed)
	_tween.finished.connect(_finish_typing)


func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_text_label.visible_ratio = 1.0
	_next_icon.show()
	if _talk_sound:
		_talk_sound.stop()


func _on_typing(count: int) -> void:
	_text_label.visible_characters = count
	if count == _last_count:
		return
	_last_count = count
	if count % maxi(talk_interval, 1) != 0:
		return
	var parsed := _text_label.get_parsed_text()
	if count <= parsed.length() and parsed[count - 1] == " ":
		return
	_play_talk()


func _play_talk() -> void:
	if _talk_sound == null or _talk_sound.stream == null:
		return
	_talk_sound.pitch_scale = 1.0 + randf_range(-talk_pitch_variation, talk_pitch_variation)
	_talk_sound.play()


func _slide_to(target: Vector2) -> void:
	if _slide_tween:
		_slide_tween.kill()
	if slide_time <= 0.0:
		offset = target
		return
	_slide_tween = create_tween()
	_slide_tween.tween_property(self, "offset", target, slide_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _finish() -> void:
	_active = false
	_typing = false
	if _talk_sound:
		_talk_sound.stop()
	_slide_to(Vector2(0, hidden_offset_y))
	await get_tree().create_timer(slide_time, true, false, true).timeout
	get_tree().paused = _was_paused
	dialog_finished.emit()


func _apply_mode() -> void:
	_portrait_row.visible = not _tutorial
	if _tutorial:
		_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_box.custom_minimum_size = Vector2(tutorial_width, tutorial_height)
		_box_style.set_border_width_all(3)
		_box_style.set_corner_radius_all(18)
	else:
		_box.size_flags_horizontal = Control.SIZE_FILL
		_box.custom_minimum_size = Vector2(0, 130)
		_box_style.set_border_width_all(0)
		_box_style.border_width_top = 4
		_box_style.set_corner_radius_all(0)


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

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	_portrait_row = HBoxContainer.new()
	_portrait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_portrait_row)
	_portrait_a = _make_portrait()
	_portrait_b = _make_portrait()
	_portrait_row.add_child(_portrait_a)
	_portrait_row.add_child(_portrait_b)

	_box = PanelContainer.new()
	_box.custom_minimum_size = Vector2(0, 130)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box_style = StyleBoxFlat.new()
	_box_style.bg_color = box_color
	_box_style.border_color = accent_color
	_box_style.border_width_top = 4
	_box_style.set_content_margin_all(16)
	_box.add_theme_stylebox_override("panel", _box_style)
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
