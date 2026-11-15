class_name Archer

extends CharacterBody2D

signal died

enum State { IDLE, COMBAT, SHOOT, RECOVER, STUN }


const RECOVER_TIME := 0.6

const SHOOT_TIME := 0.35
const STUN_TIME := 3.0
const STUN_DAMAGE_BONUS := 1.5

var state := State.IDLE
var state_time := 0.0
var move_dir := Vector2.ZERO
var pending_fire := false

@onready var stun_gauge: StunGauge = $StunGauge
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


@export_group("Stat")
@export var health := 300
@export var move_speed := 60.0

@export_group("Jarak")
@export var trigger_range := 200
@export var min_distance := 35
@export var melee_distance := 50    
@export var max_distance := 100 


@export_group("Ranged Attack")
@export var arrow_scene: PackedScene
@export var attack_cooldown := 8   
@export var arrow_shoot := 3


@export_group("Punch")
@export var punch_damage := 18
@export var punch_stun := 30.0
@export var punch_knockback := 500.0
@export var punch_cooldown := 1.5
var is_punching := false
var indicator_color := Color.YELLOW

@export_group("Teleport")
@export var hits_to_teleport := 3
@export var teleport_min_distance := 100
@export var teleport_max_distance := 150

var player: Node2D = null
var knockback := Vector2.ZERO
var attack_timer := 1.0
var shooting_timer := 0.7
var hit_count := 0
var arrow_shooted := 0

var arena_rect := Rect2()
var has_arena := false


func _ready() -> void:
	add_to_group("Enemy")           
	add_to_group("NoContactDamage")   
	player = get_tree().get_first_node_in_group("Player")
	
	var bounds := get_tree().get_first_node_in_group("ArenaBounds")
	if bounds != null:
		var tl: Vector2 = bounds.get_node("TopLeft").global_position
		var br: Vector2 = bounds.get_node("BottomRight").global_position
		arena_rect = Rect2(tl, br - tl)
		has_arena = true
	
	stun_gauge.stunned.connect(_on_stunned)
	
	if has_node("HealthBar"):
		$HealthBar.max_value = health
		$HealthBar.value = health


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	state_time += delta
	knockback = knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	move_dir = Vector2.ZERO

	match state:
		State.IDLE:
			_state_idle()
		State.COMBAT:
			_state_combat(delta)
		State.SHOOT:
			_state_shoot()
		State.STUN:
			_state_stun()
		State.RECOVER:
			_state_recover()
	
	velocity = move_dir * move_speed + knockback
	move_and_slide()


func _state_idle() -> void:
	if global_position.distance_to(player.global_position) <= trigger_range:
		change_state(State.COMBAT)

func _state_combat(delta: float) -> void:
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist > trigger_range:
		change_state(State.IDLE)
		return

	if dist < min_distance:
		move_dir = -to_player.normalized()
	elif dist > max_distance:
		move_dir = to_player.normalized()
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		_start_shoot()

func _start_shoot() -> void:
	#is_punching = false
	queue_redraw()
	#pending_fire = fire_scene != null and randf() < fire_chance
	attack_timer = attack_cooldown
	change_state(State.SHOOT)

func _state_shoot() -> void:
	if state_time < SHOOT_TIME:
		return
	_shoot_arrow()
	change_state(State.COMBAT)

func _state_stun() -> void:
	if state_time >= STUN_TIME:
		stun_gauge.release()
		attack_timer = maxf(attack_timer, 1.0)
		change_state(State.COMBAT)

func _draw() -> void:
	if is_punching:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		var target_local_pos: Vector2 = to_local(global_position + (direction * 24))
		draw_circle(target_local_pos, 10.0, indicator_color)

func _state_recover() -> void:
	queue_redraw()
	if state_time >= RECOVER_TIME:
		change_state(State.COMBAT)


func on_parried(parrier: Node2D, stun_power: float) -> void:
	knockback = (global_position - parrier.global_position).normalized() * 250.0
	change_state(State.RECOVER)    
	stun_gauge.add(stun_power)  



func change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
	match new_state:
		State.SHOOT:
			sprite.self_modulate = Color(0.8, 0.5, 1.0)
		State.STUN:
			hit_count = 0
			sprite.self_modulate = Color(0.5, 0.8, 1.0)
		_:
			sprite.self_modulate = Color.WHITE


func _on_stunned() -> void:
	change_state(State.STUN)
	is_punching = false
	queue_redraw()

func _shoot_arrow() -> void:
	if arrow_scene == null:
		return
	arrow_shooted = 0
	while arrow_shooted < arrow_shoot:	
		var arrow = arrow_scene.instantiate()
		
		
		arrow.target_player = player
		arrow.global_position = global_position
		arrow.direction = (player.global_position-global_position).normalized()
		arrow.rotation = (player.global_position-global_position).normalized().angle()
		
		get_tree().current_scene.add_child(arrow)
		
		await get_tree().create_timer(shooting_timer).timeout		
		arrow_shooted += 1
	
	

func _teleport() -> void:
	is_punching = false
	queue_redraw()
	if state == State.STUN:
		return
	
	if not is_instance_valid(player):
		return

	for i in 20:
		var angle := randf() * TAU
		var dist := randf_range(teleport_min_distance, teleport_max_distance)
		var target := player.global_position + Vector2.RIGHT.rotated(angle) * dist

		if has_arena and not arena_rect.has_point(target):
			continue
		
		if test_move(Transform2D(0.0, target), Vector2.ZERO):
			continue

		global_position = target
		break

	attack_timer = maxf(attack_timer, 1.0)
	change_state(State.COMBAT)  



func take_hit(damage: int, stun_power: float, knockback_force: Vector2, _attacker: Node2D) -> void:
	if state == State.STUN:
		damage = int(damage * STUN_DAMAGE_BONUS)
	health -= damage
	knockback = knockback_force

	if has_node("HealthBar"):
		$HealthBar.value = health

	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)

	if health <= 0:
		died.emit()
		queue_free()
		return

	stun_gauge.add(stun_power)   
	if state == State.STUN:
		return                    

	hit_count += 1
	if hit_count >= hits_to_teleport:
		hit_count = 0
		_teleport.call_deferred()
