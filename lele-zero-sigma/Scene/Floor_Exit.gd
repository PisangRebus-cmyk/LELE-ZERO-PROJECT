extends Area2D

@export_file("*.tscn") var next_scene: String

var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if not (body.is_in_group("Player") or body.is_in_group("Ghost")):
		return
	if body.get("is_dead"):
		return
	triggered = true
	SaveManager.change_floor(next_scene)
