extends CanvasLayer

signal buff_chosen(stat: String, amount: int)

const STAT_PROPS := {
	"speed": "speed",
	"attack": "attack_damage",
	"defense": "defense",
}

@export var pause_game := true

@onready var root: Control = $Root
@onready var card_health: Button = $Root/Cards/CardHealth
@onready var card_attack: Button = $Root/Cards/CardAttack
@onready var card_speed: Button = $Root/Cards/CardSpeed

@export var Up_Health := 35.0
@export var Up_Atk := 1.2
@export var Up_Spd := 25.0

var player: Node = null
var is_open := false
var Buff_Value: Array[float]


func _ready() -> void:
	
	# Wajib agar BuffUI tetap bisa diklik saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	Buff_Value.append(Up_Health)
	Buff_Value.append(Up_Atk)
	Buff_Value.append(Up_Spd)
	
	add_to_group("buff_ui")
	visible = false
	
	card_health.pressed.connect(_on_card_pressed.bind(0))
	card_attack.pressed.connect(_on_card_pressed.bind(1))
	card_speed.pressed.connect(_on_card_pressed.bind(2))


func open(target_player: Node) -> void:
	if is_open:
		return
	player = target_player
	is_open = true
	visible = true
	if pause_game:
		get_tree().paused = true
	card_speed.grab_focus()


func close() -> void:
	is_open = false
	visible = false
	if pause_game:
		get_tree().paused = false


func _on_card_pressed(type: int) -> void:
	_apply_buff(type)
	close()


func _apply_buff(type: int) -> void:
	if player == null:
		return
	if player.has_method("ascend"):
		player.ascend(type, Buff_Value[type])
		return
