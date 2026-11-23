class_name Attack2WaveArea
extends BossAttack

const WINDUP := 3.0          
const WAVE_ACTIVE := 0.5
const LOCK_BEFORE := 1.05    
const TURN_SPEED := 0.65
const DRIFT_FACTOR := 0.07   

@export var waves := 4

@onready var wavearea: CollisionPolygon2D = $CollisionShape2D

var age := 0.0


func _ready() -> void:
	super()
	wavearea.disabled = true


func _physics_process(delta: float) -> void:
	age += delta

	var active := false
	var tracking := false
	for i in waves:
		var pulse: float = WINDUP + i * WINDUP
		if age >= pulse and age < pulse + WAVE_ACTIVE:
			active = true
		var track_from: float = 0.0 if i == 0 else pulse - WINDUP + WAVE_ACTIVE
		if age >= track_from and age < pulse - LOCK_BEFORE:
			tracking = true
	wavearea.set_deferred("disabled", not active)

	var target := get_target()
	if target != null:
		var want := (target.global_position - global_position).angle()
		if tracking:
			rotation = want
		else:
			rotation = rotate_toward(rotation, want, TURN_SPEED * DRIFT_FACTOR * delta)

	var end_time: float = WINDUP + (waves - 1) * WINDUP + WAVE_ACTIVE
	if age >= end_time:
		finish()
