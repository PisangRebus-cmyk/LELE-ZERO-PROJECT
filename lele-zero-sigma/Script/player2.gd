extends CharacterBody2D

@export var SPEED := 100
@export var acceleration := 2000
@export var light_radius := 120.0

@onready var light: PointLight2D = $PointLight2D
@onready var light_area: Area2D = $LightArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_active := true
var facing_direction := Vector2.DOWN


func _ready():
	add_to_group("Ghost")
	_apply_light_radius()
	light_area.body_entered.connect(_on_light_entered)
	light_area.body_exited.connect(_on_light_exited)
	light_area.area_entered.connect(_on_light_entered)
	light_area.area_exited.connect(_on_light_exited)
	_update_animation(Vector2.ZERO)

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


# ================= ANIMASI =================
# Nama animasi di SpriteFrames. Kalau nama di editor berubah, ubah di sini saja.
const ANIM_WALK := {
	"up": "player_up",
	"down": "player_walkdown",
	"left": "player_walkleft",
	"right": "player_walkright",
}

# Jalan kalau ada input, berhenti di frame pertama kalau diam
func _update_animation(direction: Vector2) -> void:
	var anim: String = ANIM_WALK[_direction_name(facing_direction)]
	if direction != Vector2.ZERO:
		sprite.play(anim)
	else:
		sprite.animation = anim
		sprite.frame = 0
		sprite.stop()

func _direction_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "up" if dir.y < 0 else "down"
