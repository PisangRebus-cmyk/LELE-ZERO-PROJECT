extends CharacterBody2D

enum State { FREE, ATTACK, DODGE, GUARD, STUN }

const COMBO_RESET_TIME := 0.6
const ATTACKS := [
	{"damage": 10, "stun": 4, "knockback": 150, "lunge": 60,   "shape": "arc",   "windup": 0.08, "active": 0.10, "recover": 0.14},
	{"damage": 10, "stun": 4, "knockback": 150, "lunge": 60,   "shape": "arc",   "windup": 0.08, "active": 0.10, "recover": 0.14},
	{"damage": 12, "stun": 5, "knockback": 150, "lunge": 60,   "shape": "arc",   "windup": 0.08, "active": 0.10, "recover": 0.14},
	{"damage": 12, "stun": 5, "knockback": 150, "lunge": 60,   "shape": "arc",   "windup": 0.08, "active": 0.10, "recover": 0.14},
	{"damage": 25, "stun": 8, "knockback": 200, "lunge": -100, "shape": "slash", "windup": 0.18, "active": 0.12, "recover": 0.30},
]
const DODGE_SPEED := 200.0
const DODGE_DURATION := 0.25
const DODGE_COOLDOWN := 0.7

const PARRY_WINDOW := 0.3
const BLOCK_DAMAGE_FACTOR := 0.2
const GUARD_MOVE_FACTOR := 0.3
const GUARD_LOCKOUT := 0.4

const PARRY_STUN := 12.0
const BLOCK_STUN_FACTOR := 0.3
const STUN_DURATION := 1.0

@export var SPEED := 100
@export var acceleration := 2000
@export var health := 200

@onready var animated_sprite_2d : AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox : Area2D = $Hitbox
@onready var arc_shape: CollisionPolygon2D = $Hitbox/ArcShape
@onready var slash_shape: CollisionPolygon2D = $Hitbox/SlashShape

@onready var combo_timer: Timer = $ComboTimer
@onready var dodge_cooldown: Timer = $DodgeCooldown
@onready var guard_cooldown: Timer = $GuardCooldown

@onready var stun_gauge: StunGauge = $StunGauge

var state := State.FREE
var state_time := 0.0
var combo_index := 0
var attack_buffered := false
var aim_direction := Vector2.DOWN
var is_dead = false
var animation_direction: String = "down"
var animation_state : String = ""
var dodge_direction := Vector2.DOWN


func _ready():
	add_to_group("Player")
	attack_hitbox.monitoring = false
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	stun_gauge.stunned.connect(_on_stunned)
	guard_cooldown.one_shot = true
	Engine.time_scale = 1.0
	#health = Savemanager.player_health
	
#Sprite Animation
func update_sprite_direction(input:Vector2) -> void:
	match input:
		Vector2.DOWN:
			animation_direction = "down"	
		Vector2.UP:
			animation_direction = "up"
		Vector2.LEFT:
			animation_direction = "left"
		Vector2.RIGHT:
			animation_direction = "right"
func update_sprite() -> void:
	if velocity.length() > 0:
		animation_state = "walk_"
	else:	
		animation_state = "idle_"
func _play_attack_animation() -> void:
	if abs(aim_direction.x) > abs(aim_direction.y):
		animation_direction = "right" if aim_direction.x > 0 else "left"
		animated_sprite_2d.flip_h = aim_direction.x < 0
		animated_sprite_2d.play("attack_side")
	elif aim_direction.y < 0:
		animation_direction = "up"
		animated_sprite_2d.play("attack_up")
	else:
		animation_direction = "down"
		animated_sprite_2d.play("attack_down")

func _physics_process(delta: float) -> void:
	state_time += delta
	match state:
		State.FREE:
			_state_free(delta)
		State.ATTACK:
			_state_attack(delta)
		State.DODGE:
			_state_dodge(delta)
		State.GUARD:
			_state_guard(delta)
		State.STUN:
			_state_stun(delta)
	move_and_slide()

#States
func change_state(new_state: State) -> void:
	if state == State.GUARD and new_state != State.GUARD:
		guard_cooldown.start(GUARD_LOCKOUT)
	state = new_state
	state_time = 0.0
	if new_state != State.ATTACK:
		attack_hitbox.set_deferred("monitoring", false)
	if new_state != State.DODGE and new_state != State.GUARD and new_state != State.STUN:
		animated_sprite_2d.self_modulate = Color.WHITE
	
#State Free
func _state_free(delta: float) -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown.is_stopped():
		start_dodge()
		return
	if Input.is_action_just_pressed("guard") and guard_cooldown.is_stopped():
		start_guard()
		return
	if Input.is_action_just_pressed("attack"):
		start_attack()
		return

	var direction := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	update_sprite_direction(direction)
	update_sprite()
	animated_sprite_2d.play(animation_state + animation_direction)
	velocity.x = move_toward(velocity.x, direction.x * SPEED, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * SPEED, acceleration * delta)

#State Attack
func start_attack() -> void:
	combo_timer.stop()
	attack_buffered = false

	aim_direction = (get_global_mouse_position() - global_position).normalized()
	attack_hitbox.rotation = aim_direction.angle()

	var data: Dictionary = ATTACKS[combo_index]
	arc_shape.disabled = data.shape != "arc"
	slash_shape.disabled = data.shape != "slash"

	_play_attack_animation()
	$SwingSound.play()
	change_state(State.ATTACK)
	
func _state_attack(delta: float) -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown.is_stopped():
		start_dodge()
		return
	if Input.is_action_just_pressed("guard") and guard_cooldown.is_stopped():
		start_guard()
		return
	var data: Dictionary = ATTACKS[combo_index]
	var active_start: float = data.windup
	var active_end: float = data.windup + data.active
	var total: float = active_end + data.recover

	if Input.is_action_just_pressed("attack"):
		attack_buffered = true

	attack_hitbox.monitoring = state_time >= active_start and state_time < active_end

	if state_time < active_end:
		velocity = aim_direction * data.lunge
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	if state_time >= total:
		_finish_attack()
	
func _finish_attack() -> void:
	combo_index = (combo_index + 1) % ATTACKS.size()
	if attack_buffered:
		start_attack()
	else:
		combo_timer.start(COMBO_RESET_TIME)
		change_state(State.FREE)

func _on_combo_timer_timeout() -> void:
	combo_index = 0

#State Dodge
func start_dodge() -> void:
	# Direction: where you're pushing, else a backstep away from the mouse
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input != Vector2.ZERO:
		dodge_direction = input.normalized()
	else:
		var to_mouse := (get_global_mouse_position() - global_position).normalized()
		dodge_direction = -to_mouse

	# A dodge cancels the combo and any buffered click
	combo_timer.stop()
	combo_index = 0
	attack_buffered = false

	dodge_cooldown.start(DODGE_COOLDOWN)

	# Placeholder visuals until you have a dodge sprite
	animation_direction = direction_to_name(dodge_direction)
	animated_sprite_2d.flip_h = false
	animated_sprite_2d.play("walk_" + animation_direction)
	animated_sprite_2d.self_modulate = Color(1, 1, 1, 0.5)

	change_state(State.DODGE)

func _state_dodge(_delta: float) -> void:
	velocity = dodge_direction * DODGE_SPEED
	if state_time >= DODGE_DURATION:
		change_state(State.FREE)

func is_invulnerable() -> bool:
	return state == State.DODGE

func direction_to_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "up" if dir.y < 0 else "down"

#State Guard
func start_guard() -> void:
	combo_timer.stop()
	combo_index = 0
	attack_buffered = false
	change_state(State.GUARD)

func _state_guard(delta: float) -> void:
	if Input.is_action_just_pressed("dodge") and dodge_cooldown.is_stopped():
		start_dodge()
		return
	if not Input.is_action_pressed("guard"):
		change_state(State.FREE)
		return

	# Face the mouse, walk slowly
	aim_direction = (get_global_mouse_position() - global_position).normalized()
	var direction := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = velocity.move_toward(direction * SPEED * GUARD_MOVE_FACTOR, acceleration * delta)

	# Placeholder visuals until you have guard sprites:
	# cyan = parry window, blue = plain block
	animated_sprite_2d.flip_h = false
	animated_sprite_2d.play("idle_" + direction_to_name(aim_direction))
	if state_time <= PARRY_WINDOW:
		animated_sprite_2d.self_modulate = Color(0.5, 1.0, 1.0)
	else:
		animated_sprite_2d.self_modulate = Color(0.6, 0.6, 1.0)

#State Stun
func _on_stunned() -> void:
	combo_timer.stop()
	combo_index = 0
	attack_buffered = false
	animated_sprite_2d.self_modulate = Color(1.0, 0.85, 0.2)  # placeholder: yellow
	change_state(State.STUN)

func _state_stun(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	animated_sprite_2d.flip_h = false
	animated_sprite_2d.play("idle_" + animation_direction)
	if state_time >= STUN_DURATION:
		stun_gauge.release()
		change_state(State.FREE)

#Take Hit and others
func take_hit(damage: int, stun_power: float, knockback_force: Vector2, attacker: Node2D) -> void:
	if is_dead or is_invulnerable():
		return

	if state == State.GUARD:
		if state_time <= PARRY_WINDOW:
			_parry(attacker)
		else:
			_block(damage, stun_power, knockback_force)
		return

	_apply_damage(damage)
	if is_dead:
		return
	velocity = knockback_force
	_flash(Color.RED)
	stun_gauge.add(stun_power)  # last: this may switch the state to STUN

func _parry(attacker: Node2D) -> void:
	print("PARRY")
	if is_instance_valid(attacker) and attacker.has_method("on_parried"):
		attacker.on_parried(self, PARRY_STUN)
	_flash(Color(2, 2, 2))
	hit_stop(0.06)
	change_state(State.FREE)

func _block(damage: int, stun_power: float, knockback_force: Vector2) -> void:
	print("BLOCK")
	_apply_damage(int(round(damage * BLOCK_DAMAGE_FACTOR)))
	if is_dead:
		return
	velocity = knockback_force * 0.5
	_flash(Color(0.6, 0.6, 1.0))
	stun_gauge.add(stun_power * BLOCK_STUN_FACTOR)

func _apply_damage(amount: int) -> void:
	health -= amount
	#Savemanager.player_health = health
	print("player hp: ", health)
	if health <= 0:
		is_dead = true
		queue_free()

func _flash(color: Color) -> void:
	animated_sprite_2d.modulate = color
	create_tween().tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.15)

func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
#Hitbox / Hurtbox
func _on_hurtbox_body_entered(body: Node2D) -> void:
	if is_invulnerable():
		return
	if body.is_in_group("NoContactDamage"):
		return   # musuh jarak jauh tidak melukai lewat sentuhan
	if body.is_in_group("Enemy"):
		health -= 10
		#Savemanager.player_health = health
		animated_sprite_2d.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		animated_sprite_2d.modulate = Color.WHITE
	
		if health <= 0:
			queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var target = area.get_parent()
	if target == self or not target.is_in_group("Enemy"):
		return

	var data: Dictionary = ATTACKS[combo_index]
	var push: Vector2 = aim_direction * data.knockback
	if target.has_method("take_hit"):
		target.take_hit(data.damage, data.stun, push, self)
	elif target.has_method("take_damage"):
		target.take_damage(data.damage, push)
