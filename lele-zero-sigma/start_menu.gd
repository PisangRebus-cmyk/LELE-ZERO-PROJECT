#NOTES
# butuh scene utama untuk new game
# butuh path untuk load game
# sprite untuk masing masing button dan bg
# full window baru bekerja kalau game udh diexport
# sinkronisasi setting akan disesuaikan variabel sound dan art
extends Control

const SceneNewGame := ""
const SavePath := ""

var _Settings := false

#Ini Variabel Button
@onready var New_Button : Button = $VBoxContainer/NewButton
@onready var Load_Button : Button = $VBoxContainer/LoadButton
@onready var Settings_Button : Button = $VBoxContainer/SettingButton
@onready var Quit_Button : Button = $VBoxContainer/QuitButton
@onready var VolumeMusik_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeMusikSlider
@onready var Window_Check : CheckBox = $VBoxContainer/SettingButton/VBoxContainer/FullWindowButton
@onready var VolumeSFX_Slide : HSlider = $VBoxContainer/SettingButton/VBoxContainer/VolumeSFXSlider

func _ready() -> void:
	New_Button.pressed.connect(_New_pressed)
	Load_Button.pressed.connect(_Load_pressed)
	Settings_Button.pressed.connect(_Setting_pressed)
	Quit_Button.pressed.connect(_Quit_pressed)
	
	Load_Button.disabled = not FileAccess.file_exists(SavePath)

	# Sinkronisasi settings
	_Setting_visibility(false)
	New_Button.grab_focus()
	
	var BusMusik := AudioServer.get_bus_index("Musik")
	VolumeMusik_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusMusik)) * 100.0
	VolumeMusik_Slide.value_changed.connect(_VolumeMusik_changed)

	var BusSFX := AudioServer.get_bus_index("SFX")
	VolumeMusik_Slide.value = db_to_linear(AudioServer.get_bus_volume_db(BusSFX)) * 100.0
	VolumeMusik_Slide.value_changed.connect(_VolumeSFX_changed)

	Window_Check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	Window_Check.toggled.connect(_Fullscreen_toggled)


	


func _New_pressed() -> void:
	if SceneNewGame == "":
		push_warning("SceneNewGame belum diisi.")
		return
	get_tree().change_scene_to_file(SceneNewGame)


func _Load_pressed() -> void:
	var fileLoad := FileAccess.open(SavePath, FileAccess.READ)
	if fileLoad == null:
		return
	var data = JSON.parse_string(fileLoad.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("scene"):
		push_warning("Save file rusak atau tidak valid.")
		return
	get_tree().change_scene_to_file(data["scene"])


func _Quit_pressed() -> void:
	get_tree().quit()


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
