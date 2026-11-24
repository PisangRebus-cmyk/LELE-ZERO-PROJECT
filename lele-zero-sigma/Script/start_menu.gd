#NOTES
# butuh path untuk load game
# sprite untuk masing masing button dan bg
# full window baru bekerja kalau game udh diexport
# sinkronisasi setting akan disesuaikan variabel sound dan art
extends Control

const SceneNewGame := "res://Scene/Level_1.tscn"
const SavePath := "user://save.json"

var _Settings := false

#Ini Variabel Button
@onready var New_Button : Button = $VBoxContainer/NewButton
@onready var Load_Button : Button = $VBoxContainer/LoadButton
@onready var Settings_Button : Button = $VBoxContainer/SettingButton
@onready var Quit_Button : Button = $VBoxContainer/QuitButton
@onready var VolumeMusik_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeMusikSlider
@onready var Window_Check : CheckBox = $VBoxContainer/SettingButton/VBoxContainer/FullWindowButton
@onready var VolumeSFX_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeSFXSlider

#Ini Variabel Audio
@onready var BGM_Player : AudioStreamPlayer = $BGM
@onready var SFXClick_Player : AudioStreamPlayer = $SFXClick

func _ready() -> void:
	New_Button.pressed.connect(_New_pressed)
	Load_Button.pressed.connect(_Load_pressed)
	Settings_Button.pressed.connect(_Setting_pressed)
	Quit_Button.pressed.connect(_Quit_pressed)

	# Suara klik untuk semua tombol
	for btn in [New_Button, Load_Button, Settings_Button, Quit_Button]:
		btn.pressed.connect(_PlayClick)

	# BGM
	if BGM_Player.stream != null and not BGM_Player.playing:
		BGM_Player.play()

	Load_Button.disabled = not FileAccess.file_exists(SavePath)

	# Sinkronisasi settings
	_Setting_visibility(false)
	
	var BusMusik := AudioServer.get_bus_index("Musik")
	VolumeMusik_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusMusik)) * 100.0
	VolumeMusik_Slide.value_changed.connect(_VolumeMusik_changed)

	var BusSFX := AudioServer.get_bus_index("SFX")
	VolumeSFX_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusSFX)) * 100.0
	VolumeSFX_Slide.value_changed.connect(_VolumeSFX_changed)
	VolumeSFX_Slide.drag_ended.connect(func(_changed): _PlayClick()) # preview volume SFX

	Window_Check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	Window_Check.toggled.connect(_Fullscreen_toggled)


	


func _New_pressed() -> void:
	if SceneNewGame == "":
		push_warning("SceneNewGame belum diisi.")
		return
	await _WaitClick()
	get_tree().change_scene_to_file(SceneNewGame)


func _Load_pressed() -> void:
	var fileLoad := FileAccess.open(SavePath, FileAccess.READ)
	if fileLoad == null:
		return
	var data = JSON.parse_string(fileLoad.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("scene"):
		push_warning("Save file rusak atau tidak valid.")
		return
	await _WaitClick()
	get_tree().change_scene_to_file(data["scene"])


func _Quit_pressed() -> void:
	await _WaitClick()
	get_tree().quit()


#kode-kode untuk audio
func _PlayClick() -> void:
	if SFXClick_Player.stream != null:
		SFXClick_Player.play()


# Tunggu suara klik selesai (maks 0.5 detik) supaya tidak terpotong saat pindah scene
func _WaitClick() -> void:
	if SFXClick_Player.stream == null:
		return
	await get_tree().create_timer(minf(SFXClick_Player.stream.get_length(), 0.5)).timeout


#kode-kode untuk setting
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
