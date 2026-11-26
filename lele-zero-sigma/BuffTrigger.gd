extends Area2D

@export var one_shot := true
@onready var sprite: Sprite2D = $Sprite2D

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	sprite.visible = false
	if used:
		return
	if not body.is_in_group("player"):
		return
	var ui = get_tree().get_first_node_in_group("buff_ui")
	if ui == null:
		push_warning("BuffUI belum ada di scene")
		return
	ui.open(body)
	if one_shot:
		used = true
		set_deferred("monitoring", false)
