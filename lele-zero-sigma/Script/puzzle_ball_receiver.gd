class_name BallReceiver
extends PuzzleTrigger

@export var hold_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer: Timer = $HoldTimer

func _ready() -> void:
	timer.one_shot = true
	timer.timeout.connect(func(): _set_on(false))
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is PuzzleBall:
		area.queue_free()
		_set_on(true)
		if hold_time > 0.0:
			timer.start(hold_time)

func _refresh() -> void:
	sprite.frame = 1 if is_on else 0
