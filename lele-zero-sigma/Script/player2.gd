extends CharacterBody2D

@export var SPEED := 100
@export var acceleration := 2000
@export var light_radius := 120.0

@onready var light: PointLight2D = $PointLight2D
@onready var light_area: Area2D = $LightArea

var is_active := true
var facing_direction := Vector2.DOWN


func _ready():
	add_to_group("Ghost")
	_apply_light_radius()
	light_area.body_entered.connect(_on_light_entered)
	light_area.body_exited.connect(_on_light_exited)
	light_area.area_entered.connect(_on_light_entered)
	light_area.area_exited.connect(_on_light_exited)

#Jalan
func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if is_active:
		direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
		if direction != Vector2.ZERO:
			facing_direction = direction

	velocity.x = move_toward(velocity.x, direction.x * SPEED, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * SPEED, acceleration * delta)
	_update_animation(direction)
	move_and_slide()

#Cahaya Ghost
func _apply_light_radius() -> void:
	var shape := $LightArea/CollisionShape2D.shape as CircleShape2D
	if shape:
		shape.radius = light_radius
	if light.texture:
		light.texture_scale = light_radius / (light.texture.get_width() * 0.5)
		
func _on_light_entered(node: Node) -> void:
	if node.has_method("enter_light"):
		node.enter_light()

func _on_light_exited(node: Node) -> void:
	if node.has_method("exit_light"):
		node.exit_light()

func set_active(value: bool) -> void:
	is_active = value




#health (iya ga bisa metong)
func take_hit(_damage = 0, _stun_power = 0.0, _knockback = Vector2.ZERO, _attacker = null) -> void:
	pass

func take_damage(_amount = 0, _push = Vector2.ZERO) -> void:
	pass


# Animasi
func _update_animation(_direction: Vector2) -> void:
	pass
