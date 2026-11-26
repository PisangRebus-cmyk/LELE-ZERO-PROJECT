extends Area2D

@export var radius := 40.0
@export var warn_time := 3.0      # jeda peringatan sebelum api menyala
@export var active_time := 1.5    # lama api menyala
@export var damage := 15
@export var stun_power := 10.0
@export var tick_interval := 0.25  # jeda antar damage jika player tetap di dalam
@export var knockback_strength := 120.0

@onready var sprites: Node2D = $Sprites
@onready var warning: ProgressBar = $Warning

var _warned := false
var _time := 0.0
var _tick := 0.0
var _burning := false
var player : CharacterBody2D = null

func get_target() -> Node2D:
	if is_instance_valid(player):
		return player
	
	player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null and get_parent() != null:
		# Fallback for test scenes: any sibling that can be hit and is not an enemy
		for n in get_parent().get_children():
			if n != self and n is Node2D and _is_victim(n):
				player = n
				if not _warned:
					_warned = true
					
					push_warning("BossAttack: nobody in group 'Player'; using sibling '%s'" % n.name)
				break
	return player

func _is_victim(n: Node) -> bool:
	return n.has_method("take_hit") and not n.is_in_group("Enemy")
	
func _physics_process(delta: float) -> void:
	player = get_target()
	_time += delta
	
	if not _burning:
		sprites.visible = false
		warning.value = (_time/warn_time)*100
		if _time >= warn_time:
			warning.visible = false
			_burning = true
			
		return
	if _time - warn_time <= active_time:
		var want := (player.global_position - global_position).angle()
		rotation = rotate_toward(rotation, want, 0.4 * delta)
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
