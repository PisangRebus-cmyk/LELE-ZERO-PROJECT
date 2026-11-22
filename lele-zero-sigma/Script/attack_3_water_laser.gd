class_name Attack3WaterLaser
extends BossAttack

const WINDUP := 3.0           
const FIRE_TIME := 5.0        
const TICK_INTERVAL := 0.5    
const TURN_SPEED := 0.25      
const AIM_FACTOR := 3.0      

var age := 0.0
var tick := 0.0


func _init() -> void:
	hit_on_enter = false     
	data = {"damage": 10, "stun": 5, "knockback": 80}


func _ready() -> void:
	super()


func _physics_process(delta: float) -> void:
	age += delta
	var firing := age >= WINDUP

	var target := get_target()
	if target != null:
		var want := (target.global_position - global_position).angle()
		var speed := TURN_SPEED if firing else TURN_SPEED * AIM_FACTOR
		rotation = rotate_toward(rotation, want, speed * delta)

	if firing:
		tick -= delta
		if tick <= 0.0:
			tick = TICK_INTERVAL
			for p in overlapping_players():
				hit(p)

	if age >= WINDUP + FIRE_TIME:
		finish()
