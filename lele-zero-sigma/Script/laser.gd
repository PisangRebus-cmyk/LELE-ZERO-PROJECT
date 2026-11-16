extends Area2D

@export var radius := 40.0
@export var warn_time := 3.0      # jeda peringatan sebelum api menyala
@export var active_time := 1.5    # lama api menyala
@export var damage := 15
@export var stun_power := 10.0
@export var tick_interval := 0.5  # jeda antar damage jika player tetap di dalam
@export var knockback_strength := 120.0

@onready var sprites: Node2D = $Sprites
@onready var warning: ProgressBar = $Warning


var _time := 0.0
var _tick := 0.0
var _burning := false

func _physics_process(delta: float) -> void:
	_time += delta
	

	if not _burning:
		sprites.visible = false
		warning.value = (_time/warn_time)*100
		if _time >= warn_time:
			_burning = true
			
		return

	if _time >= warn_time + active_time:
		queue_free()
		return
	if _burning == true:
		sprites.visible = true
		_tick -= delta
		if _tick <= 0.0:
			_tick = tick_interval
			for body in get_overlapping_bodies():
				if body.is_in_group("Player"):
					var push := (body.global_position - global_position).normalized()
					body.take_hit(damage, stun_power, push * knockback_strength, self)
