class_name Combat

extends Area2D


enum State {IDLE, COMBAT, PHASE1, PHASE2, FINISHED}
#===================================================
var player : CharacterBody2D
var is_combat := false
var state := State.IDLE
var state_time := 0.0
var pos = global_position
var current_enemies : Node = null
var is_enemy := false
var phase := 1

@export var barrier: ToggleableLayer

#===================================================
@export_group("Enemies")
@export var Golem_Scene : PackedScene
@export var Archer_Scene : PackedScene
@export var Mage_Scene : PackedScene
@export var Golem_num := 1
@export var Archer_num := 1
@export var Mage_num := 1

#===================================================
const SPAWN_DELAY := 1.0

func _ready() -> void:
	add_to_group("NoContactDamage")
	player = get_tree().get_first_node_in_group("Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	state_time += delta
	match state:
		State.IDLE:
			_state_idle()
		State.COMBAT:
			if is_combat:
				_state_combat()
		State.PHASE1:
			if is_combat:
				_state_phase_1()
		State.PHASE2:
			if is_combat:
				_state_phase_2()
		State.FINISHED:
			_state_finish()
	is_enemy = is_instance_valid(current_enemies)
	
func _change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
	match new_state:
		State.PHASE1:
			for i in range(Golem_num):
				current_enemies = _golem_spawn(Golem_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
			for i in range(Archer_num):
				current_enemies = _archer_spawn(Archer_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
			for i in range(Mage_num):
				current_enemies = _mage_spawn(Mage_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
		State.PHASE2:
			for i in range(randf_range(Golem_num,Golem_num + 1)):
				current_enemies = _golem_spawn(Golem_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
			for i in range(randf_range(Archer_num,Archer_num + 1)):
				current_enemies = _archer_spawn(Archer_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
			for i in range(randf_range(Mage_num,Mage_num + 1)):
				current_enemies = _mage_spawn(Mage_Scene)
			await get_tree().create_timer(SPAWN_DELAY).timeout
func _state_idle() -> void:
	pass
	
func _state_combat() -> void:
	print("combat")
	_change_state(State.PHASE1)
	
func _state_phase_1() -> void:
	var can_phase_2: bool = get_tree().get_nodes_in_group("Phase_1_Enemy").is_empty()
	if can_phase_2:
		phase += 1
		_change_state(State.PHASE2)

func _state_phase_2() -> void:
	var can_finish: bool = get_tree().get_nodes_in_group("Phase_2_Enemy").is_empty()
	if can_finish:
		
		_change_state(State.FINISHED)

func _state_finish() -> void:
	is_combat = false
	barrier.enabled = false

#=================================================================
func _golem_spawn(scene: PackedScene) -> Node:
	if scene == null:
		push_error("Combat: a scene is not assigned in the Inspector")
		return null
	var golem = scene.instantiate()
	get_tree().current_scene.add_child(golem)
	golem.global_position = global_position + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
	if phase == 1:
		golem.add_to_group("Phase_1_Enemy")
	elif phase == 2:
		golem.add_to_group("Phase_2_Enemy")
	return golem

func _archer_spawn(scene: PackedScene) -> Node:
	if scene == null:
		push_error("Combat: a scene is not assigned in the Inspector")
		return null
	var archer = scene.instantiate()
	get_tree().current_scene.add_child(archer)
	archer.global_position = global_position + Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
	if phase == 1:
		archer.add_to_group("Phase_1_Enemy")
	elif phase == 2:
		archer.add_to_group("Phase_2_Enemy")
	return archer
	
func _mage_spawn(scene: PackedScene) -> Node:
	if scene == null:
		push_error("Combat: a scene is not assigned in the Inspector")
		return null
	var mage = scene.instantiate()
	get_tree().current_scene.add_child(mage)
	mage.global_position = global_position + Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
	if phase == 1:
		mage.add_to_group("Phase_1_Enemy")
	elif phase == 2:
		mage.add_to_group("Phase_2_Enemy")
	return mage
	
func _on_body_entered(body: Node2D) -> void:
	if is_combat or not body.is_in_group("Player"):
		print("p")
		return
	is_combat = true
	print("enter")
	_change_state(State.COMBAT)
	barrier.enabled = true
