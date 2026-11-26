extends Marker2D

@export var player_offset := Vector2(20, 0)
@export var ghost_offset := Vector2(-20, 0)


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player:
		player.global_position = global_position + player_offset
	var ghost := get_tree().get_first_node_in_group("Ghost") as Node2D
	if ghost:
		ghost.global_position = global_position + ghost_offset
