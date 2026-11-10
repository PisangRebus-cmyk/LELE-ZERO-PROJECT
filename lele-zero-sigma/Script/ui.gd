#NOTES
#health bar nanti difungsikan ke player1nya
extends CanvasLayer

const TITLE_SCENE := "res://StartMenu.tscn"

@onready var health_bar: ProgressBar = $"Bar Atas/HealthBar"
@onready var pause_menu: Control = $"Pause Menu"
@onready var continue_button: Button = $"Pause Menu/VBoxContainer/ContinueButton"
@onready var return_button: Button = $"Pause Menu/VBoxContainer/ReturnTitleButton"
@onready var quit_button: Button = $"Pause Menu/VBoxContainer/QuitButton"


var player: Node = null
var max_hp: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()

	continue_button.pressed.connect(_resume)
	return_button.pressed.connect(_return_to_title)
	quit_button.pressed.connect(get_tree().quit)

	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if player:
		max_hp = player.health 
		set_health(player.health, max_hp)


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		set_health(player.health, max_hp)
	elif player != null:
		set_health(0, max_hp)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	get_tree().paused = true
	pause_menu.show()
	continue_button.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	pause_menu.hide()


func _return_to_title() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://Scene/StartMenu.tscn")


# HPBar player1
func set_health(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
