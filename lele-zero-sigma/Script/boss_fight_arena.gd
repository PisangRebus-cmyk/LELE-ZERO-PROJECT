extends Area2D

var player : CharacterBody2D = null

@export var boundary: ToggleableLayer

@onready var lele_zero: LeleZero = $LeleZero
var is_combat := false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_combat = true
		player = body
		print("ya" if is_instance_valid(player) else "anak ambah")
		boundary.set_powered(true)
		

func _physics_process(delta: float) -> void:
	pass
			


func _on_lele_zero_victory() -> void:
	is_combat = false
