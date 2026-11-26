class_name Lever
extends PuzzleTrigger

@export var one_shot := false   # true = tidak bisa dibalik lagi
@export var link_id := ""
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if link_id != "":
		add_to_group("lever_link_" + link_id)

func interact(_user: Node2D) -> void:
	if one_shot and is_on:
		return
	_set_on(not is_on)
	if link_id != "":
		get_tree().call_group("lever_link_" + link_id, "sync_state", is_on, self)

func sync_state(on: bool, source: Node) -> void:
	if source == self:
		return
	is_on = on
	_refresh()
	
func _refresh() -> void:
	sprite.frame = 4 if is_on else 0
