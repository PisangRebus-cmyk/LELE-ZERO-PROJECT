extends Area2D

@export var illustrations: Array[Texture2D] = []
@export var one_shot := true

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if used or not body.is_in_group("Player"):
		return
	var ui = get_tree().get_first_node_in_group("illustration_ui")
	if ui == null:
		push_warning("IllustrationUI belum ada di scene")
		return
	ui.open(illustrations)
	if one_shot:
		used = true
		set_deferred("monitoring", false)
