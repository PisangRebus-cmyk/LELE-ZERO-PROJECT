class_name Lever
extends PuzzleTrigger

@export var one_shot := false  
@export var link_id := ""
@export var frame_time := 0.06 
@onready var sprite: Sprite2D = $Sprite2D

const FRAME_OFF := 0
const FRAME_ON := 4

var _tween: Tween

func _ready() -> void:
	if link_id != "":
		add_to_group("lever_link_" + link_id)
	
	sprite.frame = FRAME_ON if is_on else FRAME_OFF

func interact(_user: Node2D) -> void:
	if one_shot and is_on:
		return
	_set_on(not is_on)
	_refresh()
	if link_id != "":
		get_tree().call_group("lever_link_" + link_id, "sync_state", is_on, self)

func sync_state(on: bool, source: Node) -> void:
	if source == self:
		return
	is_on = on
	_refresh()

func _refresh() -> void:
	_animate_to(FRAME_ON if is_on else FRAME_OFF)

func _animate_to(target: int) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	var distance: int = abs(target - sprite.frame)
	if distance == 0:
		return
	_tween = create_tween()
	_tween.tween_property(sprite, "frame", target, distance * frame_time)
