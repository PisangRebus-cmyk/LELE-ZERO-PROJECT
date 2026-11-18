extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("enter_light"):
			body.enter_light()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("exit_light"):
			body.exit_light()
