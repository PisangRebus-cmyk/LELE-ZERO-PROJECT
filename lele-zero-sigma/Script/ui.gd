#NOTES
#health bar nanti difungsikan ke player1nya
extends CanvasLayer

const TITLE_SCENE := "res://Scene/StartMenu.tscn"

@onready var game_over: Control = $GameOver
@onready var health_bar: ProgressBar = $"Bar Atas/HealthBar"
@onready var pause_menu: Control = $"Pause Menu"
@onready var continue_button: Button = $"Pause Menu/VBoxContainer/ContinueButton"
@onready var return_button: Button = $"Pause Menu/VBoxContainer/ReturnTitleButton"
@onready var quit_button: Button = $"Pause Menu/VBoxContainer/QuitButton"
@onready var retry_button: Button = $GameOver/VBoxContainer/RetryButton
@onready var go_title_button: Button = $GameOver/VBoxContainer/ReturnTitleButton

var player: Node = null
var max_hp: float = 1.0
var is_game_over := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()
	game_over.hide()
	continue_button.pressed.connect(_resume)
	return_button.pressed.connect(_return_to_title)
	quit_button.pressed.connect(get_tree().quit)

	retry_button.pressed.connect(_on_retry)
	go_title_button.pressed.connect(_return_to_title)

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if player:
		max_hp = player.health
		set_health(player.health, max_hp)

func _process(_delta: float) -> void:
	if is_game_over:
		return
	if is_instance_valid(player):
		set_health(player.health, max_hp)
		if player.health <= 0:
			_show_game_over()
	elif player != null:
		# player sudah di-free (mati)
		set_health(0, max_hp)
		_show_game_over()


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
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


func _show_game_over() -> void:
	is_game_over = true
	pause_menu.hide()
	game_over.show()
	get_tree().paused = true
	retry_button.grab_focus()


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


# HPBar player1
func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
