class_name BallEmitter
extends Node2D

@export var ball_scene: PackedScene
@export var direction := Vector2.RIGHT
@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.timeout.connect(_shoot)
	print(timer.wait_time)
	


func _shoot() -> void:
	var ball := ball_scene.instantiate() as PuzzleBall
	ball.direction = direction.normalized()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + direction.normalized() * 16.0
