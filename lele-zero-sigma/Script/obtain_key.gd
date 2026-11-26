class_name ObtainKey
extends PuzzleTrigger

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	sprite.play("default")

func interact(_user: CharacterBody2D) -> void:
	if _user.is_in_group("Player"):
		_user.key += 1
		print(_user.key)
		queue_free()
