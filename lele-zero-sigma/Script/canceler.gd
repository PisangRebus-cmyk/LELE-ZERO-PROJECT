extends Node2D

@export var required := 0
@export var target : ToggleableLayer
var power := 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_powered(on: bool) -> void:
	power = maxi(power + (1 if on else -1), 0)
	_sync(power >= required)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _sync(a : bool) -> void:
	if a:
		target.set_powered(not a)
	else:
		pass
