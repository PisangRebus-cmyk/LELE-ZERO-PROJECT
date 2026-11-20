class_name GhostPressurePlate
extends PuzzleTrigger

@export var accepted_group := "Ghost"
## Seconds the targets stay on after stepping off. 0 = only while standing on it.
@export var hold_time := 1.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $HoldTimer



var pressing := 0   # a counter, like light_sources


func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(accepted_group):
		return
	pressing += 1
	print(pressing)
	timer.stop()
	_set_on(true)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(accepted_group):
		return
	pressing -= 1
	if pressing > 0:
		return
	else:
		print("MAXWIN")
		_set_on(false)


func _on_timer_timeout() -> void:
	_set_on(false)


func _refresh() -> void:
	sprite.frame = 1 if is_on else 0
