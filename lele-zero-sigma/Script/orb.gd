extends Area2D

@export var speed := 200.0
@export var damage := 12
@export var stun_power := 10.0
@export var knockback_strength := 200.0
@export var lifetime := 4.0
@export var radius := 8.0

var direction := Vector2.RIGHT


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		return  # abaikan musuh itu sendiri
	if body.is_in_group("Player"):
		body.take_hit(damage, stun_power, direction * knockback_strength, self)
		if body.has_method("dizzy"):
			body.dizzy()
	queue_free()  # hancur saat kena player atau tembok


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.MEDIUM_PURPLE)  # visual sementar
