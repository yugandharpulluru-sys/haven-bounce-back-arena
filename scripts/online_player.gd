extends CharacterBody3D

var arena: Node
var peer_id := 0
var skeleton: Skeleton3D
var left_leg := -1
var right_leg := -1
var left_rest := Quaternion.IDENTITY
var right_rest := Quaternion.IDENTITY
var last_position := Vector3.ZERO
var moving_time := 0.0
var animation_time := 0.0

func setup(world: Node, id: int, avatar: int = 0) -> void:
	arena = world
	peer_id = id
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 1
	add_child(collision)
	var character: String = ["astronaut", "pathfinder", "guardian"][clampi(avatar, 0, 2)]
	var scene = load("res://assets/characters/" + character + ".glb")
	if scene:
		var model = scene.instantiate()
		model.position.y = 0.0
		add_child(model)
		var animations = model.find_children("*", "AnimationPlayer", true, false)
		if not animations.is_empty():
			var player: AnimationPlayer = animations[0]
			for name in player.get_animation_list():
				if str(name).ends_with("Idle_Gun"):
					player.play(name)
					break

func take_damage(amount: int) -> void:
	if is_instance_valid(arena):
		arena.request_hit(peer_id, amount)

func _process(delta: float) -> void:
	if not is_instance_valid(skeleton):
		return
	if global_position.distance_squared_to(last_position) > 0.0004:
		moving_time = 0.18
	else:
		moving_time = maxf(0.0, moving_time - delta)
	last_position = global_position
	animation_time += delta * 9.0
	var swing := sin(animation_time) * 0.36 if moving_time > 0 else 0.0
	if left_leg >= 0:
		skeleton.set_bone_pose_rotation(left_leg, left_rest * Quaternion(Vector3.RIGHT, swing))
	if right_leg >= 0:
		skeleton.set_bone_pose_rotation(right_leg, right_rest * Quaternion(Vector3.RIGHT, -swing))
