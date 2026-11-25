extends Area2D

@export var one_shot := true
@export var ui : CanvasLayer
var used := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	print("masuk: ", body.name)
	if used:
		return
	if not body.is_in_group("Player"):
		return
	if ui == null:
		push_warning("BuffUI belum ada di scene")
		return
	ui.open(body)
	if one_shot:
		used = true
		set_deferred("monitoring", false)
