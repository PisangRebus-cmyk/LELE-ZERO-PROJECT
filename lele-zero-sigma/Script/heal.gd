extends Area2D

@export var player : CharacterBody2D

func _on_body_entered(body: Node2D) -> void:
	player.health = player.max_health
