class_name EnergyCharger
extends Area2D

@export var required := 1

var power := 0
var inside: Array = []
var lit: Array = []

@onready var energy: PointLight2D = get_node_or_null("PointLight2D")


func _ready() -> void:
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	_sync(false)


func set_powered(on: bool) -> void:
	power = maxi(power + (1 if on else -1), 0)
	_sync(power >= required)


func _on_entered(body: Node2D) -> void:
	print("enter")
	if body.has_method("fill_energy"):
		inside.append(body)
		_sync(power >= required)


func _on_exited(body: Node2D) -> void:
	print("exit")
	inside.erase(body)
	_sync(power >= required)


func _sync(on: bool) -> void:
	if energy:
		energy.enabled = on
	if on:
		for b in inside:
			if b not in lit:
				lit.append(b)
				b.fill_energy(1.5)
	for b in lit.duplicate():
		if not on or b not in inside:
			lit.erase(b)
			if is_instance_valid(b):
				b.decay_energy()
