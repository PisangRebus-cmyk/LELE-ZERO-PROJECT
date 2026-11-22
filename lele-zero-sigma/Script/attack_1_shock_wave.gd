class_name Attack1ShockWave
extends BossAttack

const WINDUP := 1.0  
const RING_ACTIVE := 0.5 

@export var ring_step := 0.25

@onready var rings: Array = [$Wave1, $Wave2, $Wave3, $Wave4]

var age := 0.0


func _ready() -> void:
	for ring in rings:
		ring.disabled = true   

func _physics_process(delta: float) -> void:
	age += delta
	for i in rings.size():
		var t: float = age - WINDUP - i * ring_step	
		rings[i].set_deferred("disabled", not (t >= 0.0 and t < RING_ACTIVE))

	var end_time: float = WINDUP + (rings.size() - 1) * ring_step + RING_ACTIVE
	if age >= end_time:
		finished.emit()
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox":
		return
	var target = area.get_parent()
	if not target.is_in_group("Player") or not target.has_method("take_hit"):
		return
	hit(target)
