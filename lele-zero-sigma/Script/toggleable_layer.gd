class_name ToggleableLayer
extends TileMapLayer

@export var solid_when_powered := true
@export var required := 1

var power := 1

func ready() -> void:
	_apply(false)

func set_powered(on: bool) -> void:
	print("setPowerTarget")
	power = maxi(power + (1 if on else -1), 0)
	_apply(power >= required)

func _apply(powered: bool) -> void:
	print("applytarg")
	var solid := (powered == solid_when_powered)
	if solid:
		print("solid")
	set_deferred("enabled", solid)
	
	
