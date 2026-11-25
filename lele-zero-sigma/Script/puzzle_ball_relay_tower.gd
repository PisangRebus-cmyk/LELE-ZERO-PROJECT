class_name RelayTower
extends Area2D

## 0 = right, 1 = down, 2 = left, 3 = up (clockwise)
@export_range(0, 3) var facing := 0
@export var mouth_distance := 18.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_refresh()


func interact(_user: Node2D) -> void:
	facing = (facing + 1) % 4
	_refresh()


func _refresh() -> void:
	sprite.rotation = facing * PI / 2.0


func _on_area_entered(area: Area2D) -> void:
	if area is PuzzleBall:
		var dir := Vector2.RIGHT.rotated(facing * PI / 2.0)
		area.redirect.call_deferred(global_position + dir * mouth_distance, dir)
