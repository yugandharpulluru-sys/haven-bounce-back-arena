extends CharacterBody3D

var arena: Node3D
var player: CharacterBody3D
var health := 100
var difficulty := 1
var attack_timer := 0.0
var move_timer := 0.0
var strafe_sign := 1.0
var alive := true
var visual: Node3D
var hit_flash := 0.0
var respawn_timer := 0.0
var home := Vector3.ZERO

func setup(game: Node3D, human: CharacterBody3D, level: int, spawn: Vector3, kind: int = 0) -> void:
	arena = game
	player = human
	difficulty = level
	home = spawn
	position = spawn
	add_to_group("bots")
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	visual = Node3D.new()
	visual.position.y = 1.0 if kind % 3 == 0 else 0.0
	add_child(visual)
	var model_name: String = ["Enemy_EyeDrone", "Enemy_QuadShell", "Enemy_Trilobite"][kind % 3]
	var scene = load("res://assets/quaternius/" + model_name + ".gltf")
	if scene:
		var model = scene.instantiate()
		model.scale = Vector3.ONE * 0.75
		visual.add_child(model)
		var animations = model.find_children("*", "AnimationPlayer", true, false)
		if not animations.is_empty() and animations[0].has_animation("Idle"):
			animations[0].play("Idle")
	var light := OmniLight3D.new()
	light.light_color = Color("ff665a")
	light.light_energy = 0.8
	light.omni_range = 3.0
	visual.add_child(light)
	attack_timer = randf_range(1.2, 3.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(arena):
		return
	if not alive:
		respawn_timer -= delta
		if respawn_timer <= 0:
			respawn()
		return
	attack_timer -= delta
	move_timer -= delta
	if move_timer <= 0:
		move_timer = randf_range(1.0, 2.5)
		strafe_sign = [-1.0, 1.0].pick_random()
	var toward := player.global_position - global_position
	toward.y = 0
	var distance := toward.length()
	var direction := toward.normalized()
	var sideways := Vector3(-direction.z, 0, direction.x) * strafe_sign
	var motion := Vector3.ZERO
	if distance > 13.0:
		motion = direction
	elif distance < 6.0:
		motion = -direction * 0.6 + sideways * 0.4
	else:
		motion = sideways * 0.8
	velocity.x = motion.x * [2.2, 3.0, 3.8][difficulty]
	velocity.z = motion.z * [2.2, 3.0, 3.8][difficulty]
	velocity.y -= 22.0 * delta
	move_and_slide()
	if get_slide_collision_count() > 0 and move_timer > 0.5:
		move_timer = 0.2
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta * 4.0)
	if attack_timer <= 0 and distance < 30:
		attack_timer = randf_range(1.1, 1.6) * [1.5, 1.0, 0.68][difficulty]
		var from := global_position + Vector3(0, 1.1, 0)
		var to := player.global_position + Vector3(0, 1.0, 0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.get("collider") == player:
			arena.bot_shot(from, to)
			if randf() < [0.35, 0.55, 0.72][difficulty]:
				player.take_damage([9, 13, 17][difficulty])

func take_damage(amount: int) -> void:
	if not alive:
		return
	health -= amount
	if health <= 0:
		alive = false
		visible = false
		collision_layer = 0
		collision_mask = 0
		respawn_timer = 3.0
		arena.bot_defeated(global_position)

func respawn() -> void:
	if not is_instance_valid(arena):
		return
	global_position = home
	velocity = Vector3.ZERO
	health = 100
	alive = true
	visible = true
	collision_layer = 1
	collision_mask = 1
	attack_timer = 2.0
