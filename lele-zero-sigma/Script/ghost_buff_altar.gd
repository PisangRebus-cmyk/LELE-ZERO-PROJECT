class_name GhostBuffAltar
extends Area2D

@export var required := 1
@export_range(0, 1) var up_type := 0
@export var upgrade_RNG := 1.15
@export var upgrade_SPD := 20
var power := 0
var inside: Array = []
var ascend: Array = []
var value := 0.0
#======================================================================
func _ready() -> void:
	if up_type == 0:
		value = upgrade_RNG
	elif up_type == 1:
		value = upgrade_SPD
	body_entered.connect(_on_entered)
	_sync(false)

func set_powered(on: bool) -> void:
	power = maxi(power + (1 if on else -1), 0)
	_sync(power >= required)


func _on_entered(body: Node2D) -> void:
	if body.has_method("ascend") and body.is_in_group("Ghost"):
		inside.append(body)
		_sync(power >= required)

func _sync(on: bool) -> void:
	if on:
		for b in inside:
			if b not in ascend:
				ascend.append(b)
				b.ascend(up_type, value)
				queue_free()
	
