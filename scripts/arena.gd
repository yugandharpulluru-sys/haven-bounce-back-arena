extends Node3D

signal match_finished(won: bool, score: int, reason: String)
signal return_requested
signal wave_completed(wave: int, reward: int)

const Player = preload("res://scripts/player.gd")
const Bot = preload("res://scripts/bot.gd")
const MAPS := ["AI CITADEL", "DESERT OUTPOST", "OVERGROWN GARDEN", "ARCHIVE VAULT", "SKYLINE YARD"]
var human: CharacterBody3D
var score := 0
var time_left := 180.0
var ended := false
var hud_health: Label
var hud_score: Label
var hud_clock: Label
var hud_message: Label
var hud_hit: Label
var message_time := 0.0
var hit_time := 0.0
var colors := [Color("35d1e0"), Color("ffb659"), Color("90e290"), Color("c79af5"), Color("78b9ff")]
var accent := Color("35d1e0")
var avatar_index := 0
var equipment := {}
var hud_shield: Label
var hud_bar: ProgressBar
var hud_font: FontVariation
var bot_shot_sound: AudioStreamPlayer
var pause_layer: CanvasLayer
var menu_open := false
var online_mode := false
var survival_mode := false
var base_difficulty := 1
var wave := 1
var wave_kills := 0
var wave_target := 8
var ground_texture := "res://assets/polyhaven/concrete_diff.jpg"
var natural_ground := false

func start_match(map_index: int, difficulty: int, weapon: String) -> void:
	accent = colors[map_index]
	base_difficulty = difficulty
	build_environment(map_index)
	build_arena(map_index)
	build_hud(MAPS[map_index], weapon)
	human = CharacterBody3D.new()
	human.set_script(Player)
	add_child(human)
	human.health_changed.connect(update_health)
	human.shield_changed.connect(update_shield)
	human.player_out.connect(func(): end_match(false, "Survived to wave %d." % wave if survival_mode else "All recovery lives were used. Try again."))
	human.setup(self, weapon, Vector3(0, 1, 13))
	human.apply_equipment(equipment)
	for pickup_info in [["health", Vector3(-13, 0, 10)], ["shield", Vector3(13, 0, -12)], ["dash", Vector3(0, 0, -5)]]:
		var pickup := Node3D.new()
		pickup.set_script(load("res://scripts/pickup.gd"))
		pickup.position = pickup_info[1]
		add_child(pickup)
		pickup.setup(pickup_info[0], human)
	var bot_kind := 0
	for point in [Vector3(-10, 1, -9), Vector3(10, 1, -9), Vector3(0, 1, -14), Vector3(13, 1, 1)]:
		var bot := CharacterBody3D.new()
		bot.set_script(Bot)
		add_child(bot)
		bot.setup(self, human, difficulty, point, bot_kind)
		bot_kind += 1
	bot_shot_sound = AudioStreamPlayer.new()
	bot_shot_sound.stream = load("res://assets/audio/impactMetal_000.ogg")
	bot_shot_sound.volume_db = -20
	add_child(bot_shot_sound)
	if survival_mode:
		hud_score.text = "WAVE 1   0 / 8"
		show_message("SURVIVE THE WAVES", 3.0)
	else:
		show_message("RECOVER 8 ECHOES TO WIN", 3.0)

func build_environment(index: int) -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = [Color("1b2940"), Color("101e30"), Color("253d37"), Color("281e40"), Color("25354d")][index]
	sky_material.sky_horizon_color = [Color("78909a"), Color("a37862"), Color("819a82"), Color("988aa2"), Color("a1bcd0")][index]
	sky_material.ground_bottom_color = Color("131c24")
	sky_material.ground_horizon_color = Color("53646b")
	var panorama := PanoramaSkyMaterial.new()
	var skies := ["sunset.hdr", "desert_sky.hdr", "grass_sky.hdr", "sunset.hdr", "sunset.hdr"]
	panorama.panorama = load("res://assets/polyhaven/" + skies[index])
	sky.sky_material = panorama
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c0cbb8")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("fff0d6")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)

func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.65
	if emission > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func box(pos: Vector3, size: Vector3, color: Color, solid: bool = true, glow: float = 0.0) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var surface := material(color, 0.35, glow)
	if size.x > 30 and size.z > 30 and size.y < 1:
		surface.albedo_color = (Color("799a64") if ground_texture.ends_with("grass_diff.jpg") else Color("bfa783")) if natural_ground else color.lightened(0.45)
		surface.albedo_texture = load(ground_texture)
		if natural_ground:
			surface.metallic = 0.0
			surface.roughness = 1.0
		else:
			surface.roughness_texture = load("res://assets/polyhaven/concrete_rough.jpg")
		surface.uv1_scale = Vector3(10, 10, 1)
	mesh.material_override = surface
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		add_child(body)
		body.add_child(mesh)
		var collision := CollisionShape3D.new()
		var shape_collision := BoxShape3D.new()
		shape_collision.size = size
		collision.shape = shape_collision
		body.add_child(collision)
	else:
		mesh.position = pos
		add_child(mesh)

func build_arena(index: int) -> void:
	var floor_color: Color = [Color("44535e"), Color("ae8962"), Color("5d7952"), Color("50465e"), Color("465366")][index]
	var wall_color: Color = [Color("253645"), Color("826648"), Color("39533b"), Color("30283c"), Color("273b52")][index]
	natural_ground = index == 1 or index == 2
	ground_texture = "res://assets/polyhaven/dry_diff.jpg" if index == 1 else ("res://assets/polyhaven/grass_diff.jpg" if index == 2 else "res://assets/polyhaven/concrete_diff.jpg")
	box(Vector3(0, -0.35, 0), Vector3(50, 0.7, 50), floor_color)
	if not natural_ground:
		for i in range(-6, 7):
			box(Vector3(i * 4.0, 0.015, 0), Vector3(0.035, 0.02, 49), Color("243743"), false)
			box(Vector3(0, 0.016, i * 4.0), Vector3(49, 0.02, 0.035), Color("243743"), false)
	var wall_height := 3.0 if natural_ground else 8.0
	for side in [-1, 1]:
		box(Vector3(side * 25, wall_height / 2.0, 0), Vector3(1, wall_height, 50), wall_color)
		box(Vector3(0, wall_height / 2.0, side * 25), Vector3(50, wall_height, 1), wall_color)
		if not natural_ground:
			box(Vector3(side * 24.4, 3.7, 0), Vector3(0.08, 0.12, 49), accent, false, 1.4)
			box(Vector3(0, 3.7, side * 24.4), Vector3(49, 0.12, 0.08), accent, false, 1.4)
			for i in [-20, -12, -4, 4, 12, 20]:
				box(Vector3(side * 24.2, 2, i), Vector3(0.4, 4, 0.65), Color("1b2933"))
				box(Vector3(i, 2, side * 24.2), Vector3(0.65, 4, 0.4), Color("1b2933"))
	if not natural_ground:
		for side in [-1, 1]:
			for i in range(-2, 3):
				var height := 11.0 + float((i + 2) % 3) * 3.0
				var x := float(i) * 11.0
				box(Vector3(x, height * 0.5 - 0.2, side * 31.0), Vector3(8, height, 5), wall_color.darkened(0.25), false)
				box(Vector3(x, 9.0, side * 28.4), Vector3(5.5, 0.08, 0.08), accent.darkened(0.35), false, 0.8)
	var cover := []
	match index:
		0: cover = [Vector3(-9, 0, -4), Vector3(9, 0, -4), Vector3(-9, 0, 7), Vector3(9, 0, 7), Vector3(0, 0, 0)]
		1: cover = [Vector3(-11, 0, -5), Vector3(11, 0, -5), Vector3(-5, 0, 5), Vector3(5, 0, 5), Vector3(0, 0, -11)]
		2: cover = [Vector3(-11, 0, 1), Vector3(11, 0, 1), Vector3(-5, 0, -8), Vector3(5, 0, -8), Vector3(0, 0, 6)]
		3: cover = [Vector3(-12, 0, -7), Vector3(12, 0, -7), Vector3(-6, 0, 5), Vector3(6, 0, 5), Vector3(0, 0, -1)]
		4: cover = [Vector3(-12, 0, 6), Vector3(12, 0, 6), Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(0, 0, 1)]
	cover.append_array([Vector3(-19, 0, -3), Vector3(19, 0, 3)])
	for point in cover:
		if natural_ground:
			add_boulder(point, Color("a98b66") if index == 1 else Color("717e6d"), Vector3(1.7, 1.05, 1.3))
		else:
			box(point + Vector3(0, 1, 0), Vector3(3.0, 2.0, 2.0), wall_color.lightened(0.12))
			box(point + Vector3(0, 2.04, 0), Vector3(3.1, 0.08, 2.1), accent.darkened(0.35), false, 0.5)
	if index == 1:
		# Stone ruins and sandstone outcrops give the desert a distinct silhouette.
		for x in [-18, -12, 12, 18]:
			box(Vector3(x, 2.4, -21), Vector3(1.2, 4.8, 1.2), Color("c5a77d"))
			add_boulder(Vector3(x, 0, 21), Color("bd9a70"), Vector3(2.2, 1.4, 1.8))
		box(Vector3(-15, 4.9, -21), Vector3(7, 0.5, 1.4), Color("b39370"))
		box(Vector3(15, 4.9, -21), Vector3(7, 0.5, 1.4), Color("b39370"))
	elif index == 2:
		for x in [-21, -14, 0, 14, 21]:
			add_tree(Vector3(x, 0, -22))
			add_tree(Vector3(x, 0, 22))
		for z in [-14, 0, 14]:
			add_tree(Vector3(-22, 0, z))
			add_tree(Vector3(22, 0, z))
	elif index == 0:
		box(Vector3(0, 4, -18), Vector3(5, 8, 1), wall_color.darkened(0.2))
		box(Vector3(0, 4.8, -17.4), Vector3(0.28, 5, 0.08), accent, false, 2.0)
		box(Vector3(0, 7.5, -17.4), Vector3(3.8, 0.15, 0.08), accent, false, 1.4)
	elif index == 3:
		for x in [-14, -7, 7, 14]:
			box(Vector3(x, 2.2, -16), Vector3(1.6, 4.4, 1.0), wall_color.lightened(0.2))
			box(Vector3(x, 2.2, -15.4), Vector3(1.2, 2.6, 0.08), accent, false, 1.1)
	else:
		for x in [-15, 15]:
			box(Vector3(x, 4.4, 0), Vector3(1.0, 0.3, 35), wall_color.lightened(0.1))
			for z in [-12, 0, 12]: box(Vector3(x, 2.3, z), Vector3(0.7, 4.5, 0.7), wall_color)
	for point in [Vector3(-15, 0, -15), Vector3(15, 0, -15), Vector3(-15, 0, 15), Vector3(15, 0, 15)]:
		if not natural_ground:
			box(point + Vector3(0, 2, 0), Vector3(0.6, 4, 0.6), wall_color.darkened(0.15))
			box(point + Vector3(0, 4.15, 0), Vector3(1.2, 0.15, 1.2), accent, false, 2.0)

func add_boulder(point: Vector3, color: Color, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = point + Vector3(0, size.y * 0.75, 0)
	add_child(body)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	sphere.radial_segments = 8
	sphere.rings = 5
	mesh.mesh = sphere
	mesh.scale = size
	mesh.rotation.y = point.x * 0.11
	mesh.material_override = material(color.darkened(0.25))
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size * 1.5
	collision.shape = shape
	body.add_child(collision)

func add_tree(point: Vector3) -> void:
	box(point + Vector3(0, 2, 0), Vector3(0.6, 4.0, 0.6), Color("5f4935"))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.7
	sphere.height = 3.0
	crown.mesh = sphere
	crown.position = point + Vector3(0, 4.5, 0)
	crown.material_override = material(Color("426b3b"))
	add_child(crown)

func build_hud(map_title: String, weapon: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var top := ColorRect.new()
	top.color = Color(0.03, 0.06, 0.09, 0.78)
	top.anchor_right = 1
	top.offset_bottom = 65
	root.add_child(top)
	var title := hud_label(map_title, 16, Color("a8c4d1"))
	title.position = Vector2(24, 12)
	root.add_child(title)
	hud_score = hud_label("ECHOES  0 / 8", 21, Color.WHITE)
	hud_score.position = Vector2(24, 32)
	root.add_child(hud_score)
	hud_clock = hud_label("03:00", 23, Color.WHITE)
	hud_clock.anchor_left = 0.5
	hud_clock.anchor_right = 0.5
	hud_clock.offset_left = -30
	hud_clock.offset_top = 19
	root.add_child(hud_clock)
	hud_health = hud_label("✚  HEALTH 100   ·   LIVES 3", 20, Color.WHITE)
	hud_health.anchor_top = 1
	hud_health.anchor_bottom = 1
	hud_health.offset_left = 24
	hud_health.offset_top = -55
	root.add_child(hud_health)
	hud_bar = ProgressBar.new()
	hud_bar.anchor_top = 1
	hud_bar.anchor_bottom = 1
	hud_bar.offset_left = 25
	hud_bar.offset_top = -21
	hud_bar.offset_right = 250
	hud_bar.offset_bottom = -12
	hud_bar.show_percentage = false
	hud_bar.max_value = 100
	hud_bar.value = 100
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("263b49")
	bar_bg.set_corner_radius_all(5)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("55e3ba")
	bar_fill.set_corner_radius_all(5)
	hud_bar.add_theme_stylebox_override("background", bar_bg)
	hud_bar.add_theme_stylebox_override("fill", bar_fill)
	root.add_child(hud_bar)
	hud_shield = hud_label("⬡  SHIELD 0", 15, Color("9ed5ff"))
	hud_shield.anchor_top = 1
	hud_shield.anchor_bottom = 1
	hud_shield.offset_left = 270
	hud_shield.offset_top = -42
	root.add_child(hud_shield)
	var gun_label := hud_label(weapon.to_upper() + "  /  Q DASH", 16, Color("9ce4e4"))
	gun_label.anchor_left = 1
	gun_label.anchor_right = 1
	gun_label.anchor_top = 1
	gun_label.anchor_bottom = 1
	gun_label.offset_left = -300
	gun_label.offset_top = -50
	root.add_child(gun_label)
	var cross := hud_label("+", 28, Color.WHITE)
	cross.anchor_left = 0.5
	cross.anchor_right = 0.5
	cross.anchor_top = 0.5
	cross.anchor_bottom = 0.5
	cross.offset_left = -8
	cross.offset_top = -21
	root.add_child(cross)
	hud_hit = hud_label("×", 35, Color("ffb666"))
	hud_hit.anchor_left = 0.5
	hud_hit.anchor_right = 0.5
	hud_hit.anchor_top = 0.5
	hud_hit.anchor_bottom = 0.5
	hud_hit.offset_left = -9
	hud_hit.offset_top = -26
	hud_hit.visible = false
	root.add_child(hud_hit)
	hud_message = hud_label("", 20, Color("82f4f0"))
	hud_message.anchor_left = 0.5
	hud_message.anchor_right = 0.5
	hud_message.offset_left = -180
	hud_message.offset_right = 180
	hud_message.offset_top = 95
	hud_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hud_message)
	var help := hud_label("WASD MOVE  SHIFT SPRINT  SPACE JUMP  Q DASH  E ROLL  ESC MENU", 12, Color("a8bcc7"))
	help.anchor_left = 0.5
	help.anchor_right = 0.5
	help.anchor_top = 1
	help.anchor_bottom = 1
	help.offset_left = -270
	help.offset_top = -25
	root.add_child(help)

func hud_label(value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	if hud_font == null:
		hud_font = FontVariation.new()
		hud_font.base_font = load("res://assets/fonts/Outfit.ttf")
		hud_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	l.add_theme_font_override("font", hud_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _process(delta: float) -> void:
	if ended or not is_instance_valid(hud_clock):
		return
	if survival_mode:
		hud_clock.text = "ENDLESS"
	else:
		time_left -= delta
		var seconds := maxi(0, ceili(time_left))
		hud_clock.text = "%02d:%02d" % [seconds / 60, seconds % 60]
		if time_left <= 0:
			end_match(false, "The signal faded before enough echoes were recovered.")
	message_time -= delta
	if message_time <= 0:
		hud_message.text = ""
	hit_time -= delta
	if hit_time <= 0:
		hud_hit.visible = false

func update_health(health: int, lives: int) -> void:
	hud_health.text = "✚  HEALTH %d   ·   LIVES %d" % [health, lives]
	if is_instance_valid(hud_bar): hud_bar.value = health
	hud_health.add_theme_color_override("font_color", Color("ff807c") if health < 35 else Color.WHITE)

func update_shield(value: int) -> void:
	if is_instance_valid(hud_shield):
		hud_shield.text = "⬡  SHIELD %d" % value

func spawn_pulse(from: Vector3, to: Vector3, color: Color = Color("6eeaff")) -> void:
	var projectile := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	projectile.mesh = mesh
	projectile.material_override = material(color, 0.0, 2.2)
	projectile.position = to_local(from)
	add_child(projectile)
	projectile.add_to_group("shot_effects")
	var duration := clampf(from.distance_to(to) / 90.0, 0.07, 0.45)
	var tween := create_tween()
	tween.tween_property(projectile, "position", to_local(to), duration)
	tween.tween_callback(func(): spawn_impact(to, color))
	tween.tween_callback(projectile.queue_free)

func spawn_impact(where: Vector3, color: Color) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	flash.mesh = sphere
	flash.material_override = material(color, 0.0, 3.0)
	flash.position = to_local(where)
	add_child(flash)
	var effect := create_tween()
	effect.tween_property(flash, "scale", Vector3.ZERO, 0.18)
	effect.tween_callback(flash.queue_free)

func bot_defeated(_pos: Vector3) -> void:
	if ended:
		return
	score += 1
	if survival_mode:
		wave_kills += 1
		if wave_kills >= wave_target:
			var cleared := wave
			var reward := 30 + mini(cleared, 20) * 5
			wave += 1
			wave_kills = 0
			wave_target = mini(24, 8 + (wave - 1) * 2)
			for bot in get_tree().get_nodes_in_group("bots"):
				if bot.get_parent() == self:
					bot.difficulty = mini(2, base_difficulty + int((wave - 1) / 3))
					bot.max_health = mini(180, 100 + (wave - 1) * 5)
			wave_completed.emit(cleared, reward)
			show_message("WAVE %d CLEAR  +%d COINS" % [cleared, reward], 2.0)
		hud_score.text = "WAVE %d   %d / %d" % [wave, wave_kills, wave_target]
	else:
		hud_score.text = "ECHOES  %d / 8" % score
		show_message("ECHO RECOVERED", 0.8)
		if score >= 8:
			end_match(true, "Haven remembers a little more because of you.")

func bot_shot(from: Vector3, to: Vector3) -> void:
	spawn_pulse(from, to, Color("ff846e"))

func toggle_pause() -> void:
	if menu_open:
		menu_open = false
		get_tree().paused = false
		if is_instance_valid(pause_layer):
			pause_layer.queue_free()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not online_mode:
		get_tree().paused = true
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.04, 0.08, 0.88)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	var title := hud_label("MATCH MENU" if online_mode else "PAUSED", 34, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	if online_mode:
		column.add_child(hud_label("Online matches continue while this menu is open.", 14, Color("a6b6c8")))
	var resume := Button.new()
	resume.text = "RESUME"
	resume.custom_minimum_size = Vector2(350, 48)
	resume.pressed.connect(toggle_pause)
	column.add_child(resume)
	var quit := Button.new()
	quit.text = "LEAVE MATCH"
	quit.custom_minimum_size = Vector2(350, 48)
	quit.pressed.connect(func():
		get_tree().paused = false
		return_requested.emit()
	)
	column.add_child(quit)

func show_message(value: String, duration: float) -> void:
	if is_instance_valid(hud_message):
		hud_message.text = value
		message_time = duration

func flash_hit() -> void:
	hud_hit.visible = true
	hit_time = 0.13

func end_match(won: bool, reason: String) -> void:
	if ended:
		return
	ended = true
	if is_instance_valid(human):
		human.can_act = false
	match_finished.emit(won, score, reason)
