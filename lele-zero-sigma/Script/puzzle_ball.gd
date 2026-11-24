class_name PuzzleBall
extends Area2D

@export var speed := 140.0
@export var lifetime := 99.0

var direction := Vector2.RIGHT
var age := 0.0
var velocity := Vector2.ZERO
var grav := Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	velocity += grav * delta
	global_position += direction * speed * delta + velocity * delta
	
	age += delta
	if age >= lifetime:
		queue_free()


func redirect(pos: Vector2, dir: Vector2) -> void:
	global_position = pos
	direction = dir


func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer or body is StaticBody2D:
		queue_free()   # hit a wall
	if body.is_in_group("Player") and body.has_method("take_hit"):
		body.take_hit(10, 10, Vector2.ZERO, self)
		
func change_gravity(accel: Vector2) -> void:

	grav = accel
