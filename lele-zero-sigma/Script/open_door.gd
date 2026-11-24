class_name OpenDoor
extends  Node2D

@export var wall : ToggleableLayer

func _process(delta: float) -> void:
	pass

func interact(_user: CharacterBody2D) -> void:
	print(_user.health)
	
	if _user.is_in_group("Player") and _user.key == 1:
		wall.set_deferred("enabled", false)
		queue_free()
	
