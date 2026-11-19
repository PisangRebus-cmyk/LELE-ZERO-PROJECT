extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Ghost"):
		if body.has_method("fill_energy"):
			body.fill_energy(1.5)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Ghost"):
		if body.has_method("decay_energy"):
			body.decay_energy()
