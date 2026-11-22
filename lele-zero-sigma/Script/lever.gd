class_name Lever
extends PuzzleTrigger

@export var one_shot := false   # true = cannot be flipped back

@onready var sprite: Sprite2D = $Sprite2D

func interact(_user: Node2D) -> void:
	if one_shot and is_on:
		return
	_set_on(not is_on)
	_refresh()


func _refresh() -> void:
	sprite.frame = 1 if is_on else 0
