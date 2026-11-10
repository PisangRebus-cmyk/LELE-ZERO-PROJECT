class_name AttackTelegraph
extends Node2D

const BACK_COLOR := Color(1.0, 0.15, 0.15, 0.25)   
const FILL_COLOR := Color(1.0, 0.15, 0.15, 0.55)

var hitbox: Area2D = null
var progress := 0.0


func show_for(area: Area2D) -> void:
	hitbox = area
	progress = 0.0
	queue_redraw()


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func hide_telegraph() -> void:
	if hitbox == null:
		return
	hitbox = null
	queue_redraw()


func _draw() -> void:
	if hitbox == null:
		return
	var nodes := hitbox.find_children("*", "CollisionShape2D", true, false)
	nodes.append_array(hitbox.find_children("*", "CollisionPolygon2D", true, false))
	for node in nodes:
		var n:= node as Node2D
		_draw_zone(n, 1.0, BACK_COLOR)
		_draw_zone(n, progress, FILL_COLOR)


func _draw_zone(node: Node2D, grow: float, color: Color) -> void:
	if grow < 0.02:
		return
		
	var xf := Transform2D.IDENTITY.scaled(Vector2(grow, grow)) * global_transform.affine_inverse() * node.global_transform
	draw_set_transform_matrix(xf)
	
	var shape_node := node as CollisionShape2D
	if shape_node != null:
		var circle := shape_node.shape as CircleShape2D
		var rect := shape_node.shape as RectangleShape2D
		if circle != null:
			draw_circle(Vector2.ZERO, circle.radius, color)
		elif rect != null:
			draw_rect(Rect2(-rect.size / 2.0, rect.size), color)
	else:
		draw_colored_polygon((node as CollisionPolygon2D).polygon, color)

	
