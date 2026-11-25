class_name ObtainKey
extends PuzzleTrigger

@export var one_shot := false   # true = tidak bisa dibalik lagi

@onready var sprite: Sprite2D = $Sprite2D

func interact(_user: CharacterBody2D) -> void:
	if one_shot and is_on:
		return
	if _user.is_in_group("Player"):
		_user.key += 1
		print(_user.key)
	queue_free()


func _refresh() -> void:
	sprite.frame = 1 if is_on else 0
