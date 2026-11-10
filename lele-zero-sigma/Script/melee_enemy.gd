extends CharacterBody2D

signal health_changed(current: int, max_value: int)
# DATABASE
enum State { IDLE, CHASE, ATTACK, RECOVER, STUN, ENRAGE }

const ATTACKS := {
	"slam" : {"damage": 30, "stun": 40, "knockback": 600, "lunge": 0, "windup": 1.0, "active": 0.15, "recovery": 0.8},
	"sweep" : {"damage": 15, "stun": 20, "knockback": 300, "lunge": 0, "windup": 0.8, "active": 0.15, "recovery": 0.6},
	"dash" : {"damage": 20, "stun": 25, "knockback": 450, "lunge": 420, "windup": 0.6, "active": 0.25, "recovery": 0.25}
}

const RECOVER_TIME := 1.0
const STUN_TIME := 2.0
const STUN_DAMAGE_BONUS := 1.5
const ENRAGE_HP_FRACTION := 0.35
const ENRAGE_INTRO := 0.8
const ENRAGE_DASHES := 3
const PHASE2_DAMAGE_FACTOR := 0.8
const PARRY_KNOCKBACK := 250

@export var max_health := 300
@export var move_speed := 45.0
@export var trigger_range := 220.0
@export var attack_range := 85.0
@export var slam_range := 50.0
@export var slam_chance := 0.6
@export var attack_cooldown := 1.2
@export var knockback_taken := 0.5   # heavy enemy: only half of the push from your sword

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stun_gauge: StunGauge = $StunGauge
@onready var telegraph: AttackTelegraph = $Telegraph
@onready var hitboxes: Dictionary = {
	"slam": $SlamHitbox,
	"sweep": $SweepHitbox,
	"dash": $DashHitbox,
}

var health := 0
var state := State.IDLE
var state_time := 0.0
var player: Node2D = null
var drive := Vector2.ZERO        # velocity the current state wants this frame
var knockback := Vector2.ZERO    # push from hits, decays over time
var attack_timer := 1.0
var current_attack := "sweep"
var aim_direction := Vector2.RIGHT
var phase2 := false
var enrage_dashes_left := 0

# INITATION

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("NoContactDamage")   # it hurts only through its hitboxes
	health = max_health
	stun_gauge.stunned.connect(_on_stunned)
	for hb: Area2D in hitboxes.values():
		hb.monitoring = false
		hb.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if player == null:
			return
	state_time += delta
	knockback = knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	drive = Vector2.ZERO
	
	match state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack()
		State.RECOVER:
			_state_recover()
		State.STUN:
			_state_stun()
		State.ENRAGE:
			_state_enrage()
	
	velocity = drive + knockback
	move_and_slide()

# STATE CHANGE 
func change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
	for hb: Area2D in hitboxes.values():
		hb.set_deferred("monitoring", false)
	if new_state != State.ATTACK:
		telegraph.hide_telegraph()
	match new_state:
		State.STUN:
			sprite.self_modulate = Color(0.5, 0.8, 1.0)       # light blue
		State.ENRAGE:
			sprite.self_modulate = Color(1.0, 0.6, 0.2)       # orange
		_:
			sprite.self_modulate = Color(1.0, 0.7, 0.7) if phase2 else Color.WHITE
	

# STATES
func _state_idle() -> void:
	if global_position.distance_to(player.global_position) <= trigger_range:
		change_state(State.CHASE)

func _state_chase(delta: float) -> void:
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist > trigger_range:
		change_state(State.IDLE)
		return
	if dist > attack_range:
		drive = to_player.normalized() * move_speed
	
	attack_timer -= delta
	if attack_timer <= 0.0:
		start_attack(_choose_attack(dist))

# ATTACKING
func _choose_attack(dist: float) -> String:
	if dist <= slam_range and randf() < slam_chance:
		return "slam"
	else:
		return "sweep"
	
func start_attack(key: String) -> void:
	current_attack = key
	aim_direction = (player.global_position - global_position).normalized()
	var hb: Area2D = hitboxes[key]
	hb.rotation = aim_direction.angle()
	telegraph.show_for(hb)
	change_state(State.ATTACK)

func _state_attack() -> void:
	var data: Dictionary = ATTACKS[current_attack]
	var hb : Area2D = hitboxes[current_attack]
	var active_end: float = data.windup + data.active
	var total: float = active_end + data.recovery
	
	if state_time < data.windup:
		telegraph.set_progress(state_time/data.windup)
	elif state_time < active_end:
		telegraph.set_progress(1.0)
	else:
		telegraph.hide_telegraph()
	
	var active: bool = state_time >= data.windup and state_time < active_end
	hb.monitoring = active
	if active:
		drive = aim_direction * data.lunge
	
	if state_time >= total:
		_finish_attack()

func _finish_attack() -> void:
	if current_attack == "dash" and enrage_dashes_left >0:
		enrage_dashes_left -= 1
		if enrage_dashes_left > 0:
			start_attack("dash")
			return
	attack_timer = attack_cooldown
	change_state(State.CHASE)

# CD
func _state_recover() -> void:
	var recover_time = RECOVER_TIME
	if phase2:
		recover_time *= 0.4
	if state_time >= recover_time:
		change_state(State.CHASE)

# STUNNED
func _on_stunned() -> void:
	change_state(State.STUN)

func _state_stun() -> void:
	if state_time >= STUN_TIME:
		stun_gauge.release()
		attack_timer = maxf(attack_timer, 1.0)
		change_state(State.CHASE)
	
func is_invulnerable() -> bool:
	return state == State.ENRAGE or enrage_dashes_left >0

# ENRAGE (triggered at the take_hit() func)
func _start_enrage() -> void:
	phase2 = true
	enrage_dashes_left = 0
	stun_gauge.release()
	change_state(State.ENRAGE)

func _state_enrage() -> void:
	if state_time >= ENRAGE_INTRO:
		enrage_dashes_left = ENRAGE_DASHES
		start_attack("dash")


# TAKING HIT
func take_hit(damage: int, stun_power: float, knockback_force: Vector2, _attacker: Node2D) -> void:
	if is_invulnerable():
		_flash(Color(0.6, 0.6, 0.6))  
		return
	
	var factor := 1.0
	if state == State.STUN:
		factor *= STUN_DAMAGE_BONUS
	if phase2:
		factor *= PHASE2_DAMAGE_FACTOR
	
	health -= int(round(damage * factor))
	health_changed.emit(health, max_health)
	print("melee_hp: ", health)
	
	knockback = knockback_force * knockback_taken
	_flash(Color.RED)
	
	if health <= 0:
		queue_free()
		return
	
	if not phase2 and health <= max_health * ENRAGE_HP_FRACTION:
		_start_enrage()
		return
	
	stun_gauge.add(stun_power)

func on_parried(parrier: Node2D, stun_power: float) -> void:
	if is_invulnerable():
		return
	knockback = (global_position - parrier.global_position).normalized() * PARRY_KNOCKBACK
	change_state(State.RECOVER)
	stun_gauge.add(stun_power)

func _flash(color: Color) -> void:
	sprite.modulate = color
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var target = area.get_parent()
	if not target.is_in_group("Player") or not target.has_method("take_hit"):
		return
	
	var data : Dictionary = ATTACKS[current_attack]
	var push : Vector2 = (target.global_position - global_position).normalized() * data.knockback
	target.take_hit(data.damage, data.stun, push, self)
	
