extends CharacterBody3D

var arena: Node3D
var player: CharacterBody3D
var health := 100
var max_health := 100
var difficulty := 1
var attack_timer := 0.0
var move_timer := 0.0
var strafe_sign := 1.0
var alive := true
var visual: Node3D
var hit_flash := 0.0
var respawn_timer := 0.0
var home := Vector3.ZERO
var role := 0
var path := PackedVector3Array()
var path_index := 0
var repath_timer := 0.0
var has_sight := false
var warning_light: OmniLight3D
var behaviour := "PURSUE"
var animator: AnimationPlayer
var attack_pose := 0.0

func setup(game: Node3D, human: CharacterBody3D, level: int, spawn: Vector3, kind: int = 0) -> void:
	role = kind % 3
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
		if not animations.is_empty():
			animator = animations[0]
			for clip in ["Idle","Walk","Run"]:
				if animator.has_animation(clip): animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			if animator.has_animation("Idle"): animator.play("Idle")
	var light := OmniLight3D.new()
	warning_light = light
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
	if arena.ended or not player.can_act:
		velocity = Vector3.ZERO
		return
	attack_pose = maxf(0.0, attack_pose-delta)
	attack_timer -= delta
	repath_timer -= delta
	move_timer -= delta
	var toward := player.global_position - global_position
	toward.y = 0
	var distance := toward.length()
	var direction := toward.normalized()
	var from := global_position + Vector3(0,1.1,0)
	var to := player.global_position + Vector3(0,1.0,0)
	var query := PhysicsRayQueryParameters3D.create(from,to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var previously_seen := has_sight
	has_sight = not hit.is_empty() and hit.get("collider") == player
	if has_sight and not previously_seen:
		attack_timer = maxf(attack_timer, [0.65,0.45,0.3][clampi(difficulty,0,2)])
	var preferred: float = [5.0,2.8,7.0][role]
	var goal := player.global_position
	var move := true
	if has_sight and distance <= preferred + 1.0:
		behaviour = "ENGAGE"
		move = false
		if distance < 1.8:
			goal = global_position - direction * 2.0
			move = true
		elif role == 2 and move_timer <= 0:
			strafe_sign *= -1.0
			move_timer = 2.8
		if role == 2 and move_timer > 1.8:
			goal = player.global_position - direction * preferred + Vector3(-direction.z,0,direction.x) * strafe_sign * 3.0
			move = true
			behaviour = "FLANK"
	else:
		behaviour = "PURSUE" if has_sight else "REPOSITION"
		if has_sight: goal -= direction * (preferred - 0.5)
	if move and is_instance_valid(arena.navigation) and arena.navigation.ready_for_paths:
		if repath_timer <= 0 or path_index >= path.size():
			path = arena.navigation.route(global_position,goal)
			path_index = 0
			repath_timer = 0.55 + role * 0.12
		while path_index < path.size() and Vector2(global_position.x,global_position.z).distance_to(Vector2(path[path_index].x,path[path_index].z)) < 0.4:
			path_index += 1
	var motion := Vector3.ZERO
	if move and path_index < path.size():
		motion = path[path_index] - global_position
		motion.y = 0
		motion = motion.normalized()
		# Keep teammates from piling into the same waypoint.
		for other in get_tree().get_nodes_in_group("bots"):
			if other == self or not other.alive: continue
			var away: Vector3 = global_position - other.global_position
			away.y = 0
			if away.length() > 0.01 and away.length() < 1.35: motion += away.normalized() * 0.45
		motion = motion.normalized()
	var speed: float = [2.6,3.4,4.2][clampi(difficulty,0,2)]
	velocity.x = move_toward(velocity.x,motion.x*speed,delta*12.0)
	velocity.z = move_toward(velocity.z,motion.z*speed,delta*12.0)
	if is_on_floor(): velocity.y = 0
	else: velocity.y -= 22.0 * delta
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*6.0)
	if is_instance_valid(animator):
		var clip := "Attack" if attack_pose > 0 else ("Run" if Vector2(velocity.x,velocity.z).length() > 0.6 else "Idle")
		if not animator.has_animation(clip): clip = "Idle"
		if animator.current_animation != clip: animator.play(clip,0.12)
	warning_light.light_energy = 2.6 if has_sight and attack_timer < 0.35 else 0.6
	if attack_timer <= 0 and distance < 26 and has_sight:
		attack_timer = randf_range(1.1,1.6) * [1.5,1.0,0.68][clampi(difficulty,0,2)]
		attack_pose = 0.35
		arena.bot_shot(from,to)
		if randf() < [0.35,0.55,0.72][clampi(difficulty,0,2)]: player.take_damage([9,13,17][clampi(difficulty,0,2)])

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
	health = max_health
	alive = true
	visible = true
	collision_layer = 1
	collision_mask = 1
	attack_timer = 2.0
	repath_timer = 0.0
	path.clear()
	path_index = 0
