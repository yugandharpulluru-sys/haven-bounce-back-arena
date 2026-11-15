extends CharacterBody3D

signal health_changed(value: int, lives: int)
signal player_out

var arena: Node3D
var weapon := "Pulse Rifle"
var camera: Camera3D
var camera_pivot: SpringArm3D
var character: Node3D
var shield := 0
var max_shield := 50
var has_armor := false
var super_dash := false
signal shield_changed(value: int)
var health := 100
var lives := 3
var fire_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var roll_cooldown := 0.0
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
	character = Node3D.new()
	character.set_script(load("res://scripts/character_visual.gd"))
	add_child(character)
	var avatar: int = game.get("avatar_index") if game.get("avatar_index") != null else 0
	var helmet_on: bool = bool(game.get("equipment").get("headgear", false)) if game.get("equipment") is Dictionary else false
	character.setup(avatar, weapon, helmet_on)
	camera_pivot = SpringArm3D.new()
	camera_pivot.position = Vector3(0.70, 1.75, 0)
	camera_pivot.spring_length = 4.2
	camera_pivot.add_excluded_object(get_rid())
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.fov = 72
	camera.current = true
	camera_pivot.add_child(camera)
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
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * mouse_sensitivity, -0.65, 0.70)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			arena.toggle_pause()
		elif event.keycode == KEY_E and roll_cooldown <= 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			perform_roll()
		elif event.keycode == KEY_Q and dash_cooldown <= 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var v := movement_input()
			dash_direction = v if v.length() > 0.1 else -global_basis.z
			dash_timer = 0.32 if super_dash else 0.20
			dash_cooldown = 2.2 if super_dash else 3.0
			arena.show_message("SUPER DASH" if super_dash else "REBOUND DASH", 0.7)
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
	roll_cooldown = maxf(0.0, roll_cooldown - delta)
	var dir := movement_input() if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Vector3.ZERO
	var speed := 10.0 if Input.is_key_pressed(KEY_SHIFT) else 7.0
	if dash_timer > 0:
		dir = dash_direction
		speed = 23.0 if super_dash else 17.0
	velocity.x = move_toward(velocity.x, dir.x * speed, 35.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 35.0 * delta)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	elif Input.is_key_pressed(KEY_SPACE) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		velocity.y = 8.0
	move_and_slide()
	if is_instance_valid(character):
		character.animate_motion(delta, Vector2(velocity.x, velocity.z).length() / 7.0, is_on_floor())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and fire_timer <= 0:
		fire()
	if position.y < -10:
		take_damage(1000)

func perform_roll() -> void:
	var direction := movement_input()
	dash_direction = direction if direction.length() > 0.1 else -global_basis.z
	dash_timer = 0.36
	roll_cooldown = 2.0
	invulnerability = maxf(invulnerability, 0.25)
	character.roll_animation()
	arena.show_message("DODGE ROLL", 0.7)

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
	character.fire_animation()
	var shot_color := Color("79dcff") if weapon == "Pulse Rifle" else (Color("ffc376") if weapon == "Scatter Blaster" else Color("c9aeff"))
	arena.spawn_muzzle(character.muzzle_position(), -camera.global_basis.z, shot_color)
	for i in range(pellets):
		var direction := (-camera.global_basis.z + camera.global_basis.x * randf_range(-spread, spread) + camera.global_basis.y * randf_range(-spread, spread)).normalized()
		var from := camera.global_position
		var query := PhysicsRayQueryParameters3D.create(from, from + direction * reach)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var destination: Vector3 = hit.get("position", from + direction * reach)
		arena.spawn_pulse(character.muzzle_position(), destination, shot_color, not hit.is_empty(), hit.get("normal", Vector3.UP))
		if i == 0:
			if arena.has_method("broadcast_shot"):
				arena.broadcast_shot(character.muzzle_position(), destination)
		if not hit.is_empty():
			var target = hit.get("collider")
			if is_instance_valid(target) and target.has_method("take_damage"):
				target.take_damage(damage)
				arena.flash_hit()

func take_damage(amount: int) -> void:
	if not can_act or invulnerability > 0:
		return
	if has_armor:
		amount = maxi(1, ceili(amount * 0.75))
	if shield > 0:
		var absorbed := mini(shield, amount)
		shield -= absorbed
		amount -= absorbed
		shield_changed.emit(shield)
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

func apply_equipment(loadout: Dictionary) -> void:
	has_armor = bool(loadout.get("armor", false))
	super_dash = bool(loadout.get("dash", false))
	shield = 50 if bool(loadout.get("shield", false)) else 0
	shield_changed.emit(shield)

func collect_powerup(kind: String) -> bool:
	if kind == "health" and health < 100:
		health = mini(100, health + 35)
		health_changed.emit(health, lives)
		arena.show_message("HEALTH RESTORED +35", 1.1)
		return true
	if kind == "shield" and shield < max_shield:
		shield = mini(max_shield, shield + 25)
		shield_changed.emit(shield)
		arena.show_message("SHIELD RECHARGED +25", 1.1)
		return true
	if kind == "dash" and dash_cooldown > 0:
		dash_cooldown = 0
		arena.show_message("DASH READY", 1.1)
		return true
	return false
