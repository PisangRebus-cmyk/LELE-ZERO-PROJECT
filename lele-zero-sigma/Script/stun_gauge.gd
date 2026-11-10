class_name StunGauge
extends Node

signal changed(value: float, max_value: float)
signal stunned

@export var max_value := 100.0
@export var decay_per_second := 20.0
@export var decay_delay := 2.0
@export var immunity_time := 1.0

var value := 0.0
var locked := false

var _time_since_add := 0.0
var _immune_left := 0.0


func add(amount: float) -> void:
	if locked or _immune_left > 0.0 or amount <= 0.0:
		return
	value = minf(value + amount, max_value)
	_time_since_add = 0.0
	print(get_parent().name, " stun: ", value) 
	changed.emit(value, max_value)
	if value >= max_value:
		locked = true
		stunned.emit()


func release() -> void:
	value = 0.0
	locked = false
	_immune_left = immunity_time
	changed.emit(value, max_value)


func _process(delta: float) -> void:
	_immune_left = maxf(_immune_left - delta, 0.0)
	if locked or value <= 0.0:
		return
	_time_since_add += delta
	if _time_since_add >= decay_delay:
		value = maxf(value - decay_per_second * delta, 0.0)
		changed.emit(value, max_value)
