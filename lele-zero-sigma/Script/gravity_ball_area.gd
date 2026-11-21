class_name GravityZone
extends Area2D

@export var push := Vector2(60, 0)
@export var is_active := true

@export_range(0, 3) var facing := 0
@export var grav : Vector2


var inside : Array = []

func _ready() -> void:
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)
	
func _on_entered(area: Area2D) -> void:
	if area.has_method("change_gravity"):
		print("masuk")
		inside.append(area)
	

func _on_exited(area: Area2D) -> void:
	inside.erase(area)

func _physics_process(delta: float) -> void:
	if facing == 0:
		print(facing)
		grav = Vector2(0.1 * gravity, 0)
	elif facing == 1:
		print(facing)
		grav = Vector2(0, -0.1 * gravity)
	elif facing == 2:
		print(facing)
		grav = Vector2(-0.1 * gravity, 0)
	elif facing == 3:
		print(facing)
		grav = Vector2(0, 0.1 * gravity)
	if not is_active:
		return
	for area in inside:
		if is_instance_valid(area):
			area.change_gravity(grav)

	
func set_powered(on: bool) -> void:
	facing = (facing + 1) % 4


	
	
