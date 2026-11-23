class_name LightZone
extends Area2D

@export var boost := 2
#======================================================================
func _ready() -> void:
	body_entered.connect(_on_entered)


func _on_entered(body: Node2D) -> void:
	if body.has_method("boost"):
		body.boost(boost)
