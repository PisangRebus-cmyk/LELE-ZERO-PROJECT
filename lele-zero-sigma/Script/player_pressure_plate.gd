class_name PlayerPressurePlate
extends PuzzleTrigger

@export var accepted_group := "Player"
## Seconds the targets stay on after stepping off. 0 = only while standing on it.
@export var hold_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $HoldTimer

var pressing := 0   # a counter, like light_sources


func _ready() -> void:
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(accepted_group):
		return
	pressing += 1
	timer.stop()
	_set_on(true)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(accepted_group):
		return
	pressing = maxi(pressing - 1, 0)
	if pressing > 0:
		return
	if hold_time > 0.0:
		timer.start(hold_time)
	else:
		_set_on(false)


func _on_timer_timeout() -> void:
	_set_on(false)


func _refresh() -> void:
	sprite.frame = 1 if is_on else 0
