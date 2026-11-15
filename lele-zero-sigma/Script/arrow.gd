extends Area2D

@export var speed := 600.0
@export var damage := 12
@export var stun_power := 10.0
@export var knockback_strength := 200.0
@export var lifetime := 3.0
@export var length := 23.0
@export var width := 6

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2.ZERO
var target_player : Node2D = null
var delta_time := 0.0
func _ready() -> void:
	if target_player == null:
		queue_free()
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(23.0, 6.0)
	shape.shape = rect
	
	add_child(shape)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	#direction = (target_player.global_position - global_position).normalized()
	
	delta_time += delta
	global_position += direction * speed * delta
	if target_player != null:
		var wanted := (target_player.global_position - global_position).normalized()
		direction = direction.slerp(wanted, 0.15 * delta).normalized()
		rotation = direction.angle() 
	if delta_time >= lifetime:
		queue_free()
	
		
	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		return  # abaikan musuh itu sendiri
	if body.is_in_group("Player"):
		body.take_hit(damage, stun_power, direction * knockback_strength, self)
		
		
	queue_free()  # hancur saat kena player atau tembok


#func _draw() -> void:
#	draw_circle(Vector2.ZERO, 6, Color.MEDIUM_PURPLE)  # visual sementara
