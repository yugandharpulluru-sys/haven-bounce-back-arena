extends Node3D

signal match_finished(won: bool, score: int, reason: String)
signal return_requested

const Player = preload("res://scripts/player.gd")
const Bot = preload("res://scripts/bot.gd")
const MAPS := ["CORE COURTYARD", "TRANSIT STATION", "OVERGROWN GARDEN"]
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
var colors := [Color("35d1e0"), Color("ffb659"), Color("90e290")]
var accent := Color("35d1e0")
var bot_shot_sound: AudioStreamPlayer
var pause_layer: CanvasLayer
var menu_open := false
var online_mode := false

func start_match(map_index: int, difficulty: int, weapon: String) -> void:
	accent = colors[map_index]
	build_environment(map_index)
	build_arena(map_index)
	build_hud(MAPS[map_index], weapon)
	human = CharacterBody3D.new()
	human.set_script(Player)
	add_child(human)
	human.health_changed.connect(update_health)
	human.player_out.connect(func(): end_match(false, "All recovery lives were used. Try again."))
	human.setup(self, weapon, Vector3(0, 1, 13))
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
	show_message("RECOVER 8 ECHOES TO WIN", 3.0)

func build_environment(index: int) -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = [Color("1b2940"), Color("101e30"), Color("253d37")][index]
	sky_material.sky_horizon_color = [Color("78909a"), Color("a37862"), Color("819a82")][index]
	sky_material.ground_bottom_color = Color("131c24")
	sky_material.ground_horizon_color = Color("53646b")
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/polyhaven/sunset.hdr")
	sky.sky_material = panorama
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9c4d0")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("e2f1f4")
	sun.light_energy = 1.3
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
		surface.albedo_color = color.lightened(0.45)
		surface.albedo_texture = load("res://assets/polyhaven/concrete_diff.jpg")
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
	var floor_color: Color = [Color("44535e"), Color("504a4a"), Color("485c52")][index]
	var wall_color: Color = [Color("253645"), Color("34353b"), Color("2b403e")][index]
	box(Vector3(0, -0.35, 0), Vector3(38, 0.7, 38), floor_color)
	# A grid of fine seams creates a readable architectural surface.
	for i in range(-4, 5):
		box(Vector3(i * 4.0, 0.015, 0), Vector3(0.035, 0.02, 37), Color("243743"), false)
		box(Vector3(0, 0.016, i * 4.0), Vector3(37, 0.02, 0.035), Color("243743"), false)
	for side in [-1, 1]:
		box(Vector3(side * 19, 3, 0), Vector3(1, 6, 38), wall_color)
		box(Vector3(0, 3, side * 19), Vector3(38, 6, 1), wall_color)
		box(Vector3(side * 18.4, 3.7, 0), Vector3(0.08, 0.12, 37), accent, false, 1.4)
		box(Vector3(0, 3.7, side * 18.4), Vector3(37, 0.12, 0.08), accent, false, 1.4)
		for i in [-12, -4, 4, 12]:
			box(Vector3(side * 18.2, 2, i), Vector3(0.4, 4, 0.65), Color("1b2933"))
			box(Vector3(i, 2, side * 18.2), Vector3(0.65, 4, 0.4), Color("1b2933"))
	var cover := []
	match index:
		0:
			cover = [Vector3(-9, 0, -4), Vector3(9, 0, -4), Vector3(-9, 0, 7), Vector3(9, 0, 7), Vector3(0, 0, 0)]
		1:
			cover = [Vector3(-11, 0, -5), Vector3(11, 0, -5), Vector3(-5, 0, 5), Vector3(5, 0, 5), Vector3(0, 0, -11)]
		2:
			cover = [Vector3(-11, 0, 1), Vector3(11, 0, 1), Vector3(-5, 0, -8), Vector3(5, 0, -8), Vector3(0, 0, 6)]
	for point in cover:
		box(point + Vector3(0, 1, 0), Vector3(3.0, 2.0, 2.0), wall_color.lightened(0.12))
		box(point + Vector3(0, 2.04, 0), Vector3(3.1, 0.08, 2.1), accent.darkened(0.35), false, 0.5)
		box(point + Vector3(0, 0.45, 1.02), Vector3(1.8, 0.06, 0.03), accent, false, 1.0)
	# A central light tower establishes a landmark without blocking the whole map.
	for point in [Vector3(-15, 0, -15), Vector3(15, 0, -15), Vector3(-15, 0, 15), Vector3(15, 0, 15)]:
		box(point + Vector3(0, 2, 0), Vector3(0.6, 4, 0.6), wall_color.darkened(0.15))
		box(point + Vector3(0, 4.15, 0), Vector3(1.2, 0.15, 1.2), accent, false, 2.0)
		var lamp := OmniLight3D.new()
		lamp.position = point + Vector3(0, 4, 0)
		lamp.light_color = accent
		lamp.light_energy = 0.6
		lamp.omni_range = 9
		add_child(lamp)
	var barrel_scene = load("res://assets/quaternius/Prop_Barrel1.gltf")
	if barrel_scene:
		for p in [Vector3(-13, 0, -3), Vector3(13, 0, 5), Vector3(-3, 0, -15)]:
			var barrel = barrel_scene.instantiate()
			barrel.position = p
			add_child(barrel)
	if index == 0:
		# Core tower and conduits create a recognizable central skyline.
		box(Vector3(0, 4, -18), Vector3(5, 8, 1), wall_color.darkened(0.2))
		box(Vector3(0, 4.8, -17.4), Vector3(0.28, 5, 0.08), accent, false, 2.0)
		box(Vector3(0, 7.5, -17.4), Vector3(3.8, 0.15, 0.08), accent, false, 1.4)
	elif index == 1:
		# Station canopy and parallel platform strips.
		for x in [-14, 14]:
			box(Vector3(x, 5.2, 0), Vector3(2.4, 0.3, 34), wall_color.darkened(0.15))
			box(Vector3(x, 0.03, 0), Vector3(0.12, 0.03, 36), accent, false, 0.8)
		for z in [-12, 0, 12]:
			box(Vector3(0, 5.4, z), Vector3(30, 0.25, 0.6), wall_color)
	if index == 2:
		for x in [-15, -8, 8, 15]:
			box(Vector3(x, 0.3, -17), Vector3(2.1, 0.6, 1), Color("344b35"))
			for n in range(4):
				box(Vector3(x + n * 0.4 - 0.6, 1.0, -17), Vector3(0.12, 1.1, 0.12), Color("699a58"), false)

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
	hud_health = hud_label("HEALTH 100   ·   LIVES 3", 20, Color.WHITE)
	hud_health.anchor_top = 1
	hud_health.anchor_bottom = 1
	hud_health.offset_left = 24
	hud_health.offset_top = -55
	root.add_child(hud_health)
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
	var help := hud_label("WASD MOVE   SPACE JUMP   Q DASH   ESC MATCH MENU", 12, Color("a8bcc7"))
	help.anchor_left = 0.5
	help.anchor_right = 0.5
	help.anchor_top = 1
	help.anchor_bottom = 1
	help.offset_left = -205
	help.offset_top = -25
	root.add_child(help)

func hud_label(value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _process(delta: float) -> void:
	if ended or not is_instance_valid(hud_clock):
		return
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
	hud_health.text = "HEALTH %d   ·   LIVES %d" % [health, lives]
	hud_health.add_theme_color_override("font_color", Color("ff807c") if health < 35 else Color.WHITE)

func bot_defeated(_pos: Vector3) -> void:
	if ended:
		return
	score += 1
	hud_score.text = "ECHOES  %d / 8" % score
	show_message("ECHO RECOVERED", 0.8)
	if score >= 8:
		end_match(true, "Haven remembers a little more because of you.")

func bot_shot(from: Vector3, to: Vector3) -> void:
	var immediate := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ff846e")
	immediate.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	immediate.surface_add_vertex(from)
	immediate.surface_add_vertex(to)
	immediate.surface_end()
	var line := MeshInstance3D.new()
	line.mesh = immediate
	add_child(line)
	get_tree().create_timer(0.10).timeout.connect(line.queue_free)

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
