extends CharacterBody3D

var arena: Node
var peer_id := 0
var visual: Node3D
var last_position := Vector3.ZERO
var moving_time := 0.0

func setup(world: Node, id: int, avatar: int = 0, weapon: String = "Pulse Rifle", helmet: bool = false) -> void:
	arena = world
	peer_id = id
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	visual = Node3D.new()
	visual.set_script(load("res://scripts/character_visual.gd"))
	add_child(visual)
	visual.setup(avatar, weapon, helmet)

func take_damage(amount: int) -> void:
	if is_instance_valid(arena): arena.request_hit(peer_id, amount)

func _process(delta: float) -> void:
	if not is_instance_valid(visual): return
	if global_position.distance_squared_to(last_position) > 0.0004:
		moving_time = 0.18
	else:
		moving_time = maxf(0.0, moving_time - delta)
	last_position = global_position
	visual.animate_motion(delta, 1.0 if moving_time > 0 else 0.0)

func show_fire() -> void:
	if is_instance_valid(visual): visual.fire_animation()
