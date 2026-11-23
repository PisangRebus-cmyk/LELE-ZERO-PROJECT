class_name LeleZero
extends CharacterBody2D

signal health_changed(current: int, max_value: int)
signal Victory

enum State { IDLE, GAP, ATTACK, COOLDOWN, RECOVER, STUN, PHASE_CHANGE }


const ATTACK_SCENES := {
	"shockwave":  preload("res://Scene/Attack1ShockWave.tscn"),
	"watersonic": preload("res://Scene/Attack2WaveArea.tscn"),
	"waterlaser": preload("res://Scene/Attack3WaterLaser.tscn"),
	"warzone":    preload("res://Scene/Attack4WarZone.tscn"),
}


const ATTACKS := {
	"shockwave":  {"damage": 20, "stun": 40, "knockback": 615},
	"watersonic": {"damage": 15, "stun": 20, "knockback": 300},
	"waterlaser": {"damage": 10, "stun": 5,  "knockback": 80},    
	"warzone":    {"damage": 25, "stun": 20, "knockback": 150},  
	"dash":       {"damage": 20, "stun": 25, "knockback": 450, "lunge": 840, "windup": 0.6, "active": 0.25, "recovery": 0.25},
}

const SEQUENCES := {
	1: ["shockwave", "watersonic", "waterlaser"],
	2: ["shockwave", "watersonic", "waterlaser"],
	3: ["shockwave", "watersonic", "warzone"],
}
const DAMAGE_TAKEN := {1: 1.0, 2: 0.85, 3: 0.85}
const DAMAGE_DEALT := {1: 1.0, 2: 1.15, 3: 1.15}

const PHASE2_HP := 0.45
const PHASE3_HP := 0.25
const PHASE_INTRO := 0.8
const PHASE_CHANGE_DASHES := 8

const GAP_TIME := 0.8          
const COOLDOWN_TIME := 10.0    
const RECOVER_TIME := 1.0
const STUN_TIME := 10.0
const STUN_DAMAGE_BONUS := 1.5
const PARRY_KNOCKBACK := 250

@export var max_health := 300
@export var trigger_range := 220.0
@export var knockback_taken := 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stun_gauge: StunGauge = $StunGauge
@onready var telegraph: AttackTelegraph = $Telegraph
@onready var dash_hitbox: Area2D = $DashHitbox

var health := 0
var state := State.IDLE
var state_time := 0.0
var player: Node2D = null
var drive := Vector2.ZERO
var knockback := Vector2.ZERO

var phase := 1
var seq_index := 0
var cooldown_left := 0.0
var current_attack := ""
var aim_direction := Vector2.RIGHT
var active_attack: BossAttack = null
var dashes_left := 0

#===============================================================================================================================
func _ready() -> void:
	add_to_group("BossEnemy")
	add_to_group("Enemy")
	add_to_group("NoContactDamage")
	health = max_health
	health_changed.emit(health, max_health)
	stun_gauge.stunned.connect(_on_stunned)
	dash_hitbox.monitoring = false
	if not dash_hitbox.area_entered.is_connected(_on_dash_hitbox_area_entered):
		dash_hitbox.area_entered.connect(_on_dash_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player") as Node2D
		if player == null:
			return
	state_time += delta
	knockback = knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	drive = Vector2.ZERO

	match state:
		State.IDLE:
			_state_idle()
		State.GAP:
			_state_gap()
		State.ATTACK:
			_state_attack()
		State.COOLDOWN:
			_state_cooldown(delta)
		State.RECOVER:
			_state_recover()
		State.STUN:
			_state_stun()
		State.PHASE_CHANGE:
			_state_phase_change()

	velocity = drive + knockback * 0.2
	move_and_slide()


func change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
	dash_hitbox.set_deferred("monitoring", false)
	if new_state != State.ATTACK:
		telegraph.hide_telegraph()
		if is_instance_valid(active_attack):
			active_attack.cancel()    
		active_attack = null
	match new_state:
		State.STUN:
			sprite.self_modulate = Color(0.5, 0.8, 1.0)     
		State.PHASE_CHANGE:
			sprite.self_modulate = Color(1.0, 0.6, 0.2)     
		State.COOLDOWN:
			sprite.self_modulate = Color(0.8, 1.0, 0.8)     
		_:
			sprite.self_modulate = Color(1.0, 0.7, 0.7) if phase >= 2 else Color.WHITE
			
#===============================================================================================================================
func _state_idle() -> void:
	if global_position.distance_to(player.global_position) <= trigger_range:
		seq_index = 0
		change_state(State.GAP)

func _state_gap() -> void:
	if state_time >= GAP_TIME:
		var key: String = SEQUENCES[phase][seq_index]
		start_attack(key)

func _state_cooldown(delta: float) -> void:
	cooldown_left -= delta           
	if cooldown_left <= 0.0:
		seq_index = 0
		change_state(State.GAP)

func _continue_fight() -> void:
	if seq_index >= SEQUENCES[phase].size():
		change_state(State.COOLDOWN)    
	else:
		change_state(State.GAP)

func _attack_data(key: String) -> Dictionary:
	var d: Dictionary = ATTACKS[key].duplicate()
	d.damage = int(round(d.damage * DAMAGE_DEALT[phase]))
	return d

func start_attack(key: String) -> void:
	current_attack = key
	aim_direction = (player.global_position - global_position).normalized()
	if key == "dash":
		dash_hitbox.rotation = aim_direction.angle()
		telegraph.show_for(dash_hitbox)
	else:
		var atk := ATTACK_SCENES[key].instantiate() as BossAttack
		atk.setup(_attack_data(key), self, aim_direction, player)   
		add_child(atk)
		active_attack = atk
		atk.finished.connect(_on_attack_finished)
	change_state(State.ATTACK)

func _state_attack() -> void:
	if current_attack != "dash":
		return    
	var d: Dictionary = ATTACKS["dash"]
	var active_end: float = d.windup + d.active
	var total: float = active_end + d.recovery

	if state_time < d.windup:
		telegraph.set_progress(state_time / d.windup)
	elif state_time < active_end:
		telegraph.set_progress(1.0)
	else:
		telegraph.hide_telegraph()

	var active: bool = state_time >= d.windup and state_time < active_end
	dash_hitbox.monitoring = active
	if active:
		drive = aim_direction * d.lunge

	if state_time >= total:
		_on_attack_finished()

func _on_attack_finished() -> void:
	active_attack = null
	if current_attack == "dash":
		dashes_left -= 1
		if dashes_left > 0:
			start_attack("dash")          
		else:
			change_state(State.GAP)       
		return

	seq_index += 1                         
	if seq_index >= SEQUENCES[phase].size():
		cooldown_left = COOLDOWN_TIME
		change_state(State.COOLDOWN)
	else:
		change_state(State.GAP)

func _on_dash_hitbox_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var target := area.get_parent() as Node2D
	if target == null or target.is_in_group("Enemy") or not target.has_method("take_hit"):
		return    # the Enemy check also skips the boss's own Hurtbox
	var d := _attack_data("dash")
	var push := (target.global_position - global_position).normalized() * float(d.knockback)
	target.take_hit(int(d.damage), float(d.stun), push, self)

func _state_recover() -> void:
	var t := RECOVER_TIME * (0.4 if phase >= 2 else 1.0)
	if state_time >= t:
		_continue_fight()

func _on_stunned() -> void:
	change_state(State.STUN)

func _state_stun() -> void:
	if state_time >= STUN_TIME:
		stun_gauge.release()
		_continue_fight()

func is_invulnerable() -> bool:
	return state == State.PHASE_CHANGE or dashes_left > 0

func _start_phase_change(new_phase: int) -> void:
	phase = new_phase
	seq_index = 0
	dashes_left = 0
	stun_gauge.release()               
	change_state(State.PHASE_CHANGE)

func _state_phase_change() -> void:
	if state_time >= PHASE_INTRO:
		dashes_left = PHASE_CHANGE_DASHES
		start_attack("dash")

func take_hit(damage: int, stun_power: float, knockback_force: Vector2, _attacker: Node2D) -> void:
	if is_invulnerable():
		_flash(Color(0.6, 0.6, 0.6))   
		return

	var factor: float = DAMAGE_TAKEN[phase]
	if state == State.STUN:
		factor *= STUN_DAMAGE_BONUS
	health -= int(round(damage * factor))
	health_changed.emit(health, max_health)
	print("boss hp: ", health)   # TEMP debug

	knockback = knockback_force * knockback_taken
	_flash(Color.RED)

	if health <= 0:
		remove_from_group("Phase_1_Enemy")
		remove_from_group("Phase_2_Enemy")
		queue_free()
		Victory.emit()
		return

	var wanted := 1
	var fraction := float(health) / max_health
	if fraction <= PHASE3_HP:
		wanted = 3
	elif fraction <= PHASE2_HP:
		wanted = 2
	if wanted > phase:
		_start_phase_change(wanted)
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
