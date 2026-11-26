#NOTES
#health bar nanti difungsikan ke player1nya
extends CanvasLayer

const TITLE_SCENE := "res://Scene/StartMenu.tscn"

@onready var game_over: Control = $GameOver
@onready var health_bar: ProgressBar = $"Bar Atas/HBoxContainer/VBox/HealthBar"
@onready var enemy_label: Label = $"Bar Atas/HBoxContainer/VBox/EnemyLabel"
@onready var phase_label: Label = $"Bar Atas/HBoxContainer/VBox/PhaseLabel"
@onready var pause_menu: Control = $"Pause Menu"
@onready var continue_button: Button = $"Pause Menu/VBoxContainer/ContinueButton"
@onready var return_button: Button = $"Pause Menu/VBoxContainer/ReturnTitleButton"
@onready var quit_button: Button = $"Pause Menu/VBoxContainer/QuitButton"
@onready var retry_button: Button = $GameOver/VBoxContainer/RetryButton
@onready var go_title_button: Button = $GameOver/VBoxContainer/ReturnTitleButton
@export var portrait_player1: Texture2D
@export var portrait_player2: Texture2D
@onready var portrait: TextureRect = $"Bar Atas/HBoxContainer/Potrait frame/gambar/potrait"
@onready var clicked_sound: AudioStreamPlayer2D = $ClickedSound
@onready var hover_sound: AudioStreamPlayer2D = $HoverSound
@onready var gameover_sound: AudioStreamPlayer2D = $GameOver2

func set_portrait(character_id: int) -> void:
	portrait.texture = portrait_player1 if character_id == 1 else portrait_player2

var player: Node = null
var max_hp: float = 1.0
var is_game_over := false
var phase := 1
var _last_enemy_count := -1


func _ready() -> void:
	add_to_group("UI") 
	set_portrait(1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()
	game_over.hide()
	set_phase(phase)
	_update_enemy_count()
	_find_player()

	_setup_button_sounds([
		continue_button,
		return_button,
		quit_button,
		retry_button,
		go_title_button,
	])

	continue_button.pressed.connect(_resume)
	return_button.pressed.connect(_return_to_title)
	quit_button.pressed.connect(get_tree().quit)

	retry_button.pressed.connect(_on_retry)
	go_title_button.pressed.connect(_return_to_title)

	set_phase(phase)
	_update_enemy_count()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	if player:
		max_hp = player.health
		set_health(player.health, max_hp)


func _setup_button_sounds(buttons: Array[Button]) -> void:
	for btn: Button in buttons:
		if not btn:
			continue
		btn.mouse_entered.connect(_play_hover_sound)
		btn.focus_entered.connect(_play_hover_sound)
		btn.pressed.connect(_play_clicked_sound)


func _play_hover_sound() -> void:
	if hover_sound and hover_sound.stream:
		hover_sound.play()


func _play_clicked_sound() -> void:
	if clicked_sound and clicked_sound.stream:
		clicked_sound.play()


func _process(_delta: float) -> void:
	if is_game_over:
		return
	_update_enemy_count()
	if not is_instance_valid(player):
		_find_player()  
		return
	set_health(player.health, player.max_health)
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
	Engine.time_scale = 1.0
	is_game_over = true
	pause_menu.hide()
	game_over.show()
	if gameover_sound and gameover_sound.stream:
		gameover_sound.play()
	get_tree().paused = true
	
func _on_retry() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	SaveManager.restart_game()
	
func _return_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
# HPBar player1
func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
func _update_enemy_count() -> void:
	var count := get_tree().get_nodes_in_group("Enemy").size()
	if count != _last_enemy_count:
		_last_enemy_count = count
		enemy_label.text = "Enemy left: %d" % count
func set_phase(value: int) -> void:
	phase = value
	phase_label.text = "Phase %d" % phase
func _find_player() -> void:
	for n in get_tree().get_nodes_in_group("Player"):
		if n.has_signal("died") and "health" in n and "max_health" in n:
			player = n
			if not player.died.is_connected(_on_player_died):
				player.died.connect(_on_player_died)
			if not player.kidnapped.is_connected(_on_player_kidnapped):
				player.kidnapped.connect(_on_player_kidnapped)
			set_health(player.health, player.max_health)
			return
			
func _on_player_kidnapped() -> void:
	_show_game_over()
	
func _on_player_died() -> void:
	set_health(0, player.max_health)
	_show_game_over()
