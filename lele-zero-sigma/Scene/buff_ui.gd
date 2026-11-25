extends CanvasLayer

signal buff_chosen(stat: String, amount: int)

const HIDDEN_Y := 2000.0
const BUFF_VALUE := 10

# Sesuaikan nilai kanan dengan nama variabel di script player1 kamu
const STAT_PROPS := {
	"speed": "speed",
	"attack": "attack_damage",
	"defense": "defense",
}

@export var pause_game := true

@onready var root: Control = $Root
@onready var card_speed: Button = $Root/Cards/CardSpeed
@onready var card_attack: Button = $Root/Cards/CardAttack
@onready var card_defense: Button = $Root/Cards/CardDefense

var player: Node = null
var is_open := false


func _ready() -> void:
	add_to_group("buff_ui")
	root.position.y = HIDDEN_Y
	card_speed.pressed.connect(_on_card_pressed.bind("speed"))
	card_attack.pressed.connect(_on_card_pressed.bind("attack"))
	card_defense.pressed.connect(_on_card_pressed.bind("defense"))


func open(target_player: Node) -> void:
	if is_open:
		return
	player = target_player
	is_open = true
	root.position.y = 0.0
	if pause_game:
		get_tree().paused = true
	card_speed.grab_focus()


func close() -> void:
	is_open = false
	root.position.y = HIDDEN_Y
	if pause_game:
		get_tree().paused = false


func _on_card_pressed(stat: String) -> void:
	_apply_buff(stat)
	buff_chosen.emit(stat, BUFF_VALUE)
	close()


func _apply_buff(stat: String) -> void:
	if player == null:
		return
	# Kalau player1 punya fungsi apply_buff sendiri, pakai itu
	if player.has_method("apply_buff"):
		player.apply_buff(stat, BUFF_VALUE)
		return
	var prop: String = STAT_PROPS[stat]
	if prop in player:
		player.set(prop, player.get(prop) + BUFF_VALUE)
	else:
		push_warning("Player tidak punya variabel '%s'. Cek STAT_PROPS di buff_ui.gd" % prop)
