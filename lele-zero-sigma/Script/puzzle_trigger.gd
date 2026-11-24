class_name PuzzleTrigger
extends Area2D

signal toggled(on: bool)

@export var targets: Array[Node] = []

var is_on := false

func _set_on(value: bool) -> void:
	if value == is_on:
		return
	is_on = value
	for t in targets:
		if is_instance_valid(t) and t.has_method("set_powered"):
			t.set_powered(value)
	toggled.emit(value)
	_refresh()
	print("3. trigger ", name, " -> ", value, "  targets: ", targets)

func _refresh() -> void:
	pass	

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_set_on(body.is_in_group("Player"))
