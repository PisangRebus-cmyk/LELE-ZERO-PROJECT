extends Control

const SceneNewGame := "res://Scene/backup_Level_1.tscn"

var _Settings := false

@onready var New_Button : Button = $VBoxContainer/NewButton
@onready var Load_Button : Button = $VBoxContainer/LoadButton
@onready var Settings_Button : Button = $VBoxContainer/SettingButton
@onready var Quit_Button : Button = $VBoxContainer/QuitButton
@onready var VolumeMusik_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeMusikSlider
@onready var Window_Check : CheckBox = $VBoxContainer/SettingButton/VBoxContainer/FullWindowButton
@onready var VolumeSFX_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeSFXSlider
@onready var BGM_Player : AudioStreamPlayer2D = $BGM
@onready var SFXClick_Player : AudioStreamPlayer2D = $ClickedSound
@onready var SFXHover_Player : AudioStreamPlayer2D = $HoverSound


func _ready() -> void:
	SaveManager.stop_autosave()

	BGM_Player.bus = "Musik"
	SFXClick_Player.bus = "SFX"
	SFXHover_Player.bus = "SFX"

	New_Button.pressed.connect(_New_pressed)
	Load_Button.pressed.connect(_Load_pressed)
	Settings_Button.pressed.connect(_Setting_pressed)
	Quit_Button.pressed.connect(_Quit_pressed)

	for btn in [New_Button, Load_Button, Settings_Button, Quit_Button]:
		btn.pressed.connect(_PlayClick)
		btn.mouse_entered.connect(_PlayHover)

	if BGM_Player.stream != null and not BGM_Player.playing:
		BGM_Player.play()

	Load_Button.disabled = not SaveManager.has_save()

	_Setting_visibility(false)

	var BusMusik := AudioServer.get_bus_index("Musik")
	VolumeMusik_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusMusik)) * 100.0
	VolumeMusik_Slide.value_changed.connect(_VolumeMusik_changed)

	var BusSFX := AudioServer.get_bus_index("SFX")
	VolumeSFX_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusSFX)) * 100.0
	VolumeSFX_Slide.value_changed.connect(_VolumeSFX_changed)

	Window_Check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	Window_Check.toggled.connect(_Fullscreen_toggled)


func _New_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	SaveManager.start_autosave()
	get_tree().change_scene_to_file(SceneNewGame)


func _Load_pressed() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		return
	await get_tree().create_timer(0.2).timeout
	SaveManager.start_autosave()
	get_tree().change_scene_to_file(data["scene"])


func _Quit_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()


func _PlayClick() -> void:
	if SFXClick_Player.stream != null:
		SFXClick_Player.play()


func _PlayHover() -> void:
	if SFXHover_Player.stream != null:
		SFXHover_Player.play()


func _Setting_pressed() -> void:
	_Setting_visibility(not _Settings)


func _Setting_visibility(show_it: bool) -> void:
	_Settings = show_it
	for child in Settings_Button.get_children():
		var item := child as CanvasItem
		if item:
			item.visible = show_it


func _VolumeMusik_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Musik")
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value / 100.0, 0.0001)))


func _VolumeSFX_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value / 100.0, 0.0001)))


func _Fullscreen_toggled(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
