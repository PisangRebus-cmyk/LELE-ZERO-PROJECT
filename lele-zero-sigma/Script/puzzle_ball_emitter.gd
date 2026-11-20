class_name BallEmitter
extends Node2D

@export var ball_scene: PackedScene
@export var direction := Vector2.RIGHT
@onready var timer: Timer = $Timer

@export var required := 1
var is_active := false
var power := 0

func _process(delta: float) -> void:
	timer.timeout.connect(_shoot)
	print(timer.wait_time)


func _shoot() -> void:
	if not is_active:
		return
	print("shh")
	var ball := ball_scene.instantiate() as PuzzleBall
	ball.direction = direction.normalized()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + direction.normalized() * 16.0
	
func set_powered(on: bool) -> void:
	power = maxi(power + (1 if on else -1), 0)
	_energy_required(power >= required)

func _energy_required(on: bool) -> void:
	is_active = on
