extends CanvasLayer

signal finished

const HIDDEN_Y := 2000.0

@export var pause_game := true

@onready var root: Control = $Root
@onready var picture: TextureRect = $Root/Frame/Picture

var textures: Array[Texture2D] = []
var index := 0
var is_open := false


func _ready() -> void:
	add_to_group("illustration_ui")
	root.position.y = HIDDEN_Y


func open(list: Array[Texture2D]) -> void:
	if is_open or list.is_empty():
		return
	textures = list
	index = 0
	is_open = true
	picture.texture = textures[0]
	root.position.y = 0.0
	if pause_game:
		get_tree().paused = true


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		get_viewport().set_input_as_handled()
		_next()


func _next() -> void:
	index += 1
	if index >= textures.size():
		_close()
	else:
		picture.texture = textures[index]


func _close() -> void:
	is_open = false
	root.position.y = HIDDEN_Y
	# Tunggu satu frame supaya klik penutup tidak ikut terbaca sebagai serangan player1
	await get_tree().process_frame
	if pause_game:
		get_tree().paused = false
	finished.emit()
