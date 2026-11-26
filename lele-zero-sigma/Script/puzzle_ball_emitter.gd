class_name BallEmitter
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@export var ball_scene: PackedScene
@export var direction := Vector2.RIGHT
@onready var timer: Timer = $Timer
@export var gap := 0.5
@export var required := 1
@export var split := false
var is_active := false
var power := 0

func _ready() -> void:
	sprite.flip_h = split
	timer.wait_time = gap
	if required == 0:
		is_active = true
	
func _process(delta: float) -> void:
	timer.timeout.connect(_shoot)
	if is_active:
		sprite.frame = 1
	else:
		sprite.frame = 0
	
func _shoot() -> void:
	if not is_active:
		return

	var ball := ball_scene.instantiate() as PuzzleBall
	ball.direction = direction.normalized()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + direction.normalized() * 16.0
	
func set_powered(on: bool) -> void:
	power = maxi(power + (1 if on else -1), 0)
	_energy_required(power >= required)

func _energy_required(on: bool) -> void:
	is_active = on
