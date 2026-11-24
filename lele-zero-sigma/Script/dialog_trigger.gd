class_name DialogTrigger
extends Area2D

signal finished

@export var dialog_id := ""
@export var player_group := "player"
@export var one_shot := true
@export var dialog_ui: CanvasLayer

var lines: Array = []
var is_tutorial := false
var auto_start := false
var _done := false


func _ready() -> void:
	if dialog_ui == null:
		dialog_ui = get_node_or_null("/root/DialogUI")
	if dialog_ui == null:
		dialog_ui = get_tree().get_first_node_in_group("dialog_ui")
	body_entered.connect(_on_body_entered)
	if auto_start:
		await get_tree().process_frame
		play()


func _on_body_entered(body: Node) -> void:
	if player_group == "" or body.is_in_group(player_group):
		play()


func play() -> void:
	if dialog_ui == null:
		push_warning("DialogTrigger: DialogUI tidak ditemukan")
		return
	if lines.is_empty():
		return
	if one_shot and _done:
		return
	if dialog_ui.is_active():
		return
	_done = true
	var id := dialog_id
	if id == "":
		id = get_script().resource_path.get_file().get_basename()
	dialog_ui.dialog_finished.connect(_on_finished, CONNECT_ONE_SHOT)
	dialog_ui.start(lines, id, is_tutorial)


func _on_finished() -> void:
	finished.emit()
