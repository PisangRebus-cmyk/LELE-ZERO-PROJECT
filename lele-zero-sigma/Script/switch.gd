extends Node

@export var player1: CharacterBody2D
@export var ghost: CharacterBody2D

var current: CharacterBody2D


func _ready() -> void:
	await get_tree().process_frame
	if player1 == null:
		player1 = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if ghost == null:
		ghost = get_tree().get_first_node_in_group("Ghost") as CharacterBody2D

	if player1 == null or ghost == null:
		set_process_unhandled_input(false)  # mode solo, switcher tidak aktif
		return

	_set_current(player1)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("switch_character"):
		return
	if not is_instance_valid(player1) or not is_instance_valid(ghost):
		return
	if current == player1:
		_set_current(ghost)
	elif not player1.is_kidnapped:
		_set_current(player1)

func _set_current(target: CharacterBody2D) -> void:
	current = target
	if is_instance_valid(player1):
		player1.set_active(target == player1)
	if is_instance_valid(ghost):
		ghost.set_active(target == ghost)
	var cam := target.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.make_current()
