class_name BossAttack
extends Area2D

signal finished


var data: Dictionary = {}
var boss: Node2D = null
var player: Node2D = null


var hit_on_enter := true

var _warned := false


func _ready() -> void:
	if hit_on_enter and not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func setup(attack_data: Dictionary, owner_boss: Node2D, aim: Vector2, target: Node2D = null) -> void:
	data = attack_data
	boss = owner_boss
	player = target
	rotation = aim.angle()


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



func overlapping_players() -> Array:
	var found: Array = []
	for area in get_overlapping_areas():
		if area.name != "Hurtbox":
			continue
		var who := area.get_parent()
		if _is_victim(who) and who not in found:
			found.append(who)
	return found


func hit(target: Node2D) -> void:
	if not is_instance_valid(target) or not target.has_method("take_hit"):
		return
	var push := (target.global_position - global_position).normalized() * float(data.get("knockback", 0.0))
	target.take_hit(int(data.get("damage", 10)), float(data.get("stun", 0.0)), push, boss)   # attacker = the BOSS


func finish() -> void:
	finished.emit()
	queue_free()


func cancel() -> void:
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var who := area.get_parent() as Node2D
	if who != null and _is_victim(who):
		hit(who)
