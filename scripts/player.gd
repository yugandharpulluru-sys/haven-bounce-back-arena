extends CharacterBody3D

signal health_changed(value: int, lives: int)
signal player_out

var arena: Node3D
var weapon := "Pulse Rifle"
var camera: Camera3D
var health := 100
var lives := 3
var fire_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector3.ZERO
var mouse_sensitivity := 0.0022
var sound: AudioStreamPlayer
var can_act := true
var invulnerability := 2.0

func setup(game: Node3D, gun: String, spawn: Vector3) -> void:
	arena = game
	weapon = gun
	position = spawn
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.75
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.57, 0)
	camera.fov = 78
	camera.current = true
	add_child(camera)
	var gun_asset := "Gun_Rifle" if weapon == "Pulse Rifle" else ("Gun_Pistol" if weapon == "Scatter Blaster" else "Gun_Sniper")
	var model = load("res://assets/quaternius/" + gun_asset + ".gltf")
	if model:
		var gun_model = model.instantiate()
		gun_model.position = Vector3(0.33, -0.31, -0.58)
		gun_model.rotation = Vector3(0, PI, 0)
		gun_model.scale = Vector3.ONE * 0.45
		camera.add_child(gun_model)
	sound = AudioStreamPlayer.new()
	sound.stream = load("res://assets/audio/laserLarge_000.ogg")
	sound.volume_db = -12
	add_child(sound)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, lives)

func _unhandled_input(event: InputEvent) -> void:
	if not can_act:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity, -1.25, 1.25)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			arena.toggle_pause()
		elif event.keycode == KEY_Q and dash_cooldown <= 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var v := movement_input()
			dash_direction = v if v.length() > 0.1 else -global_basis.z
			dash_timer = 0.20
			dash_cooldown = 3.0
			arena.show_message("REBOUND DASH", 0.7)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func movement_input() -> Vector3:
	var direction := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S): direction += transform.basis.z
	if Input.is_key_pressed(KEY_A): direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D): direction += transform.basis.x
	direction.y = 0
	return direction.normalized()

func _physics_process(delta: float) -> void:
	if not can_act or not is_instance_valid(arena):
		return
	invulnerability = maxf(0.0, invulnerability - delta)
	fire_timer = maxf(0.0, fire_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	var dir := movement_input() if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Vector3.ZERO
	var speed := 7.0
	if dash_timer > 0:
		dir = dash_direction
		speed = 17.0
	velocity.x = move_toward(velocity.x, dir.x * speed, 35.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 35.0 * delta)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif Input.is_key_pressed(KEY_SPACE) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		velocity.y = 8.0
	move_and_slide()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and fire_timer <= 0:
		fire()
	if position.y < -10:
		take_damage(1000)

func fire() -> void:
	var pellets := 1
	var damage := 25
	var reach := 80.0
	var spread := 0.003
	match weapon:
		"Scatter Blaster":
			pellets = 7
			damage = 8
			reach = 22.0
			spread = 0.035
			fire_timer = 0.7
		"Longshot":
			damage = 55
			spread = 0.001
			fire_timer = 0.8
		_:
			fire_timer = 0.20
	sound.pitch_scale = randf_range(0.94, 1.06)
	sound.play()
	for i in range(pellets):
		var direction := (-camera.global_basis.z + camera.global_basis.x * randf_range(-spread, spread) + camera.global_basis.y * randf_range(-spread, spread)).normalized()
		var from := camera.global_position
		var query := PhysicsRayQueryParameters3D.create(from, from + direction * reach)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var target = hit.get("collider")
			if is_instance_valid(target) and target.has_method("take_damage"):
				target.take_damage(damage)
				arena.flash_hit()

func take_damage(amount: int) -> void:
	if not can_act or invulnerability > 0:
		return
	health -= amount
	if health <= 0:
		lives -= 1
		if lives <= 0:
			health = 0
			can_act = false
			health_changed.emit(health, lives)
			player_out.emit()
			return
		health = 100
		invulnerability = 2.0
		global_position = Vector3(0, 1.0, 13)
		velocity = Vector3.ZERO
		arena.show_message("REBOOTED  ·  %d LIVES LEFT" % lives, 1.8)
	health_changed.emit(health, lives)
