class_name Attack4WarZone
extends BossAttack

const WINDUP := 5.0           
const SLOWDOWN_TIME := 0.5    
const ACTIVE_TIME := 3.0      
const TICK_INTERVAL := 0.5
const TURN_SPEED := 0.3        
const SLOW_FACTOR := 0.25

var age := 0.0
var tick := 0.0
var spin := 1.0


func _init() -> void:
	hit_on_enter = false
	data = {"damage": 25, "stun": 20, "knockback": 150}


func _ready() -> void:
	super()
	spin = 1.0 if randi() % 2 == 0 else -1.0   


func _physics_process(delta: float) -> void:
	age += delta

	var slow := age >= WINDUP - SLOWDOWN_TIME
	rotation += spin * TURN_SPEED * (SLOW_FACTOR if slow else 1.0) * delta

	if age >= WINDUP:
		tick -= delta
		if tick <= 0.0:
			tick = TICK_INTERVAL
			var target := get_target()
			if target != null and target not in overlapping_players():
				hit(target)   

	if age >= WINDUP + ACTIVE_TIME:
		finish()
