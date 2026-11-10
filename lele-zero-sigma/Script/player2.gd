extends CharacterBody2D

@export var SPEED := 100
@export var acceleration := 2000

var facing_direction := Vector2.DOWN


func _ready():
	add_to_group("Player")

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if direction != Vector2.ZERO:
		facing_direction = direction

	velocity.x = move_toward(velocity.x, direction.x * SPEED, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * SPEED, acceleration * delta)
	_update_animation(direction)
	move_and_slide()

# Health Bar
func take_hit(_damage = 0, _stun_power = 0.0, _knockback = Vector2.ZERO, _attacker = null) -> void:
	pass

func take_damage(_amount = 0, _push = Vector2.ZERO) -> void:
	pass


# ===================== ANIMASI (masih kosong euy) =====================
func _update_animation(_direction: Vector2) -> void:
	pass  # idle / walk
