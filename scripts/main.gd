extends Node

const Arena = preload("res://scripts/arena.gd")
const OnlineArena = preload("res://scripts/online_arena.gd")
const SAVE_PATH := "user://haven_save.cfg"
var save_path := SAVE_PATH
const COSTS := {"Pulse Rifle": 0, "Scatter Blaster": 80, "Longshot": 140}
const GEAR := {
	"Kinetic Shield": {"cost": 90, "slot": "shield", "detail": "Start solo matches with 50 shield"},
	"Armor Plate": {"cost": 120, "slot": "armor", "detail": "Reduce incoming solo damage by 25%"},
	"Tactical Headgear": {"cost": 70, "slot": "headgear", "detail": "A glowing helmet for your character"},
	"Super Dash": {"cost": 140, "slot": "dash", "detail": "Dash faster, farther, and more often"}
}
var coins := 0
var wins := 0
var story_unlocked := 0
var story_mode := false
var story_stage := 0
var owned := ["Pulse Rifle"]
var chosen_weapon := "Pulse Rifle"
var gear_owned: Array = []
var equipped := {"shield": false, "armor": false, "headgear": false, "dash": false}
var profile_choice := false
var profile_name := "Guest"
var player_uid := ""
var friends: Array = []
var recent_players: Array = []
var friend_results: VBoxContainer
var friend_query: LineEdit
var friend_name_input: LineEdit
var friend_uid_input: LineEdit
var friend_address_input: LineEdit
var friend_error: Label
var profile_input: LineEdit
var menu_preview: Node3D
var ui_theme: Theme
var chosen_map := 0
var chosen_difficulty := 1
var chosen_avatar := 0
var audio_level := 0.8
var aim_sensitivity := 0.0022
var intro_camera: Camera3D
var intro_time := 0.0
var background_actors: Array = []
var ui: Control
var arena: Node3D
var online_players := {}
var online_health := {}
var online_scores := {}
var online_slots := {}
var online_weapons := {}
var online_helmets := {}
var online_identities := {}
var online_map := 0
var online_active := false
var online_finished := false
var address_box: LineEdit

func _ready() -> void:
	load_progress()
	if profile_choice and not valid_uid(player_uid):
		player_uid = generate_uid()
		save_progress()
	build_theme()
	apply_audio()
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connection_failed.connect(on_connection_failed)
	multiplayer.server_disconnected.connect(on_server_disconnected)
	if profile_choice:
		show_intro()
	else:
		show_profile_choice()

func clear_screen() -> void:
	get_tree().paused = false
	intro_camera = null
	menu_preview = null
	background_actors.clear()
	if is_instance_valid(ui):
		ui.queue_free()
		ui = null
	if is_instance_valid(arena):
		arena.queue_free()
		arena = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func build_screen(kicker: String, title: String, subtitle: String) -> VBoxContainer:
	clear_screen()
	ui = Control.new()
	ui.theme = ui_theme
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var background := ColorRect.new()
	background.color = Color("0b111e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	var side := ColorRect.new()
	side.color = Color(0.04, 0.11, 0.17, 0.64)
	side.anchor_left = 0.72
	side.anchor_right = 1.0
	side.anchor_bottom = 1.0
	ui.add_child(side)
	var glow := ColorRect.new()
	glow.color = Color("08b8cf")
	glow.position = Vector2(66, 64)
	glow.size = Vector2(48, 4)
	ui.add_child(glow)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 68)
	margin.add_theme_constant_override("margin_top", 85)
	margin.add_theme_constant_override("margin_right", 68)
	margin.add_theme_constant_override("margin_bottom", 35)
	ui.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	column.add_child(make_label(kicker.to_upper(), 14, Color("61e2e7")))
	column.add_child(make_label(title, 43, Color("f4f8fc")))
	var desc := make_label(subtitle, 17, Color("a6b6c8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 48)
	column.add_child(desc)
	return column

func make_label(value: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 20:
		label.add_theme_font_override("font", load("res://assets/fonts/Orbitron.ttf"))
	label.add_theme_color_override("font_color", color)
	return label

func button(parent: Node, title: String, action: Callable, width: int = 350) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(width, 48)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func build_theme() -> void:
	ui_theme = Theme.new()
	ui_theme.set_font("font", "Button", load("res://assets/fonts/Orbitron.ttf"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("153247") if state == "normal" else (Color("246078") if state == "hover" else Color("1d4a60"))
		style.set_corner_radius_all(12)
		style.set_border_width_all(1)
		style.border_color = Color("397186") if state == "normal" else Color("75e7ef")
		style.content_margin_left = 14
		style.content_margin_right = 14
		ui_theme.set_stylebox(state, "Button", style)
	ui_theme.set_color("font_color", "Button", Color("eefbff"))
	ui_theme.set_color("font_hover_color", "Button", Color.WHITE)

func show_profile_choice() -> void:
	var col := build_screen("Welcome to Haven", "CHOOSE HOW TO PLAY", "Play as a guest or choose a player name stored on this device.")
	add_portrait("echo")
	col.add_child(make_label("No password or online account is needed.", 18, Color("c8dde6")))
	button(col, "PLAY AS GUEST", func(): set_profile("Guest"))
	button(col, "CREATE LOCAL PLAYER NAME", show_profile_entry, 480)
	col.add_child(make_label("Google sign-in and cloud saves are not connected.", 14, Color("9aafbc")))

func show_profile_entry() -> void:
	var col := build_screen("Local profile", "YOUR PLAYER NAME", "Your name and progress stay on this computer. This is not a password-protected account.")
	profile_input = LineEdit.new()
	profile_input.placeholder_text = "Enter a player name"
	profile_input.max_length = 18
	profile_input.custom_minimum_size = Vector2(390, 52)
	profile_input.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(profile_input)
	button(col, "CONTINUE", func(): set_profile(profile_input.text), 390)
	button(col, "BACK", show_profile_choice)

func set_profile(value: String) -> void:
	profile_name = value.strip_edges().substr(0, 18)
	if profile_name.is_empty(): profile_name = "Guest"
	profile_choice = true
	if not valid_uid(player_uid): player_uid = generate_uid()
	save_progress()
	show_intro()

func add_portrait(kind: String) -> void:
	var container := SubViewportContainer.new()
	container.anchor_left = 0.67
	container.anchor_right = 0.98
	container.anchor_top = 0.16
	container.anchor_bottom = 0.92
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(container)
	ui.move_child(container, ui.get_child_count() - 3)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(400, 550)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	var setting := Environment.new()
	setting.background_mode = Environment.BG_COLOR
	setting.background_color = Color("14283a")
	setting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	setting.ambient_light_color = Color("b6dbea")
	setting.ambient_light_energy = 1.1
	env.environment = setting
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.4
	world.add_child(light)
	if kind == "echo":
		menu_preview = load("res://assets/quaternius/Enemy_EyeDrone.gltf").instantiate()
		menu_preview.scale = Vector3.ONE * 1.5
		menu_preview.position.y = 1.05
		world.add_child(menu_preview)
	else:
		menu_preview = Node3D.new()
		menu_preview.set_script(load("res://scripts/character_visual.gd"))
		world.add_child(menu_preview)
		menu_preview.setup(chosen_avatar, chosen_weapon, bool(equipped.get("headgear", false)))
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 3.1)
	cam.fov = 40
	world.add_child(cam)
	cam.look_at(Vector3(0, 1.05, 0))
	cam.current = true

func show_intro() -> void:
	show_echo_dialogue(0)

func show_echo_dialogue(page: int) -> void:
	var messages := [
		"Hello, " + profile_name + ". I am ECHO, Haven's last active guide.",
		"Haven fell silent. The arenas hold fragments of the people and places we lost.",
		"Move with WASD, aim with your mouse, and fire to recover the echoes. Press Q to dash.",
		"Win matches to earn coins. Find pickups and visit the market to prepare for the next mission.",
		"Every memory brings Haven closer to coming back. Are you ready?"
	]
	var col := build_screen("ECHO  /  transmission %02d of %02d" % [page + 1, messages.size()], "A MESSAGE FROM ECHO", "HAVEN RECOVERY NETWORK")
	add_portrait("echo")
	var message := make_label(messages[page], 23, Color("e9f8fc"))
	message.custom_minimum_size = Vector2(640, 140)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(message)
	button(col, "ENTER HAVEN" if page == messages.size() - 1 else "NEXT  →", func():
		if page + 1 < messages.size(): show_echo_dialogue(page + 1)
		else: show_menu()
	)
	button(col, "SKIP INTRO", show_menu)

func add_intro_scene() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(container)
	ui.move_child(container, 1)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var world := Node3D.new()
	world.set_script(Arena)
	viewport.add_child(world)
	world.build_environment(0)
	world.build_arena(0)
	for point in [Vector3(-8, 4, -4), Vector3(7, 5, -8), Vector3(2, 3, 5)]:
		var drone = load("res://assets/quaternius/Enemy_EyeDrone.gltf").instantiate()
		drone.position = point
		drone.scale = Vector3.ONE * 1.35
		world.add_child(drone)
		background_actors.append({"node": drone, "base": point})
		var animations = drone.find_children("*", "AnimationPlayer", true, false)
		if not animations.is_empty() and animations[0].has_animation("Idle"):
			animations[0].play("Idle")
	intro_camera = Camera3D.new()
	world.add_child(intro_camera)
	intro_camera.position = Vector3(18, 12, 23)
	intro_camera.look_at(Vector3(0, 1, 0))
	intro_camera.current = true
	var tint := ColorRect.new()
	tint.color = Color(0.02, 0.05, 0.1, 0.74)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	ui.move_child(tint, 2)

func _process(delta: float) -> void:
	if is_instance_valid(menu_preview):
		menu_preview.rotation.y += delta * 0.24
		if menu_preview.has_method("animate_motion"):
			menu_preview.animate_motion(delta, 0.0)
	if is_instance_valid(intro_camera):
		intro_time += delta
		for actor in background_actors:
			if is_instance_valid(actor["node"]):
				var node: Node3D = actor["node"]
				var base: Vector3 = actor["base"]
				node.position = base + Vector3(sin(intro_time * 0.7 + base.x) * 1.3, sin(intro_time * 1.3 + base.z) * 0.4, cos(intro_time * 0.5 + base.x) * 1.1)
				node.rotation.y += delta * 0.35
		intro_camera.position = Vector3(sin(intro_time * 0.08) * 18.0, 11.0, cos(intro_time * 0.08) * 22.0)
		intro_camera.look_at(Vector3(0, 1, 0))

func show_menu() -> void:
	story_mode = false
	var col := build_screen("HAVEN  /  BOUNCE BACK", "WELCOME BACK", "Ready, " + profile_name + "? The arena is waiting.")
	add_intro_scene()
	add_portrait("player")
	col.add_child(make_label("%d COINS       %d VICTORIES" % [coins, wins], 17, Color("f9d17d")))
	button(col, "PLAY VS AI  →", show_setup)
	button(col, "MARKET & LOADOUT", show_store)
	button(col, "STORY MISSIONS", show_story)
	button(col, "ONLINE MULTIPLAYER", show_online)
	button(col, "SETTINGS", show_settings)
	var links := HBoxContainer.new()
	links.add_theme_constant_override("separation", 10)
	col.add_child(links)
	button(links, "FRIENDS", show_friends, 170)
	button(links, "HELP", show_help, 170)
	button(col, "QUIT", func(): get_tree().quit())
	col.add_child(make_label("RECOVER THE SIGNAL  •  RESTORE HAVEN", 13, Color("8194a8")))

func show_story() -> void:
	story_mode = false
	var col := build_screen("The Haven archive", "STORY MISSIONS", "Recover the memories hidden across the arenas. Each victory unlocks the next signal.")
	var titles := ["01  THE FIRST SIGNAL  ·  COURTYARD", "02  THE EMPTY PLATFORM  ·  TRANSIT", "03  GHOSTS IN THE GARDEN", "04  THE ARCHIVE VAULT", "05  A CITY RETURNS  ·  SKYLINE"]
	for i in range(5):
		var stage := i
		var unlocked := i <= story_unlocked
		button(col, titles[i] + ("" if unlocked else "  ·  LOCKED"), func():
			if unlocked:
				story_brief(stage)
		, 610)
	button(col, "REPLAY OPENING", show_intro)
	button(col, "BACK", show_menu)

func story_brief(stage: int) -> void:
	var titles := ["THE FIRST SIGNAL", "THE EMPTY PLATFORM", "GHOSTS IN THE GARDEN", "THE ARCHIVE VAULT", "A CITY RETURNS"]
	var briefs := [
		"ECHO: 'The core is awake. Recover its signal and I can open the archive.'",
		"ECHO: 'This station should be empty. Why do I remember waiting here?'",
		"ECHO: 'The fighters were never strangers. They are the people Haven saved.'",
		"ECHO: 'The archive holds the last complete recording of Haven.'",
		"ECHO: 'A signal from the skyline can bring the city back online.'"
	]
	var col := build_screen("Story  /  mission %02d" % (stage + 1), titles[stage], briefs[stage])
	col.add_child(make_label("OBJECTIVE: Recover 8 echoes before time runs out.", 19, Color("b4c9d8")))
	button(col, "SPEAK TO ECHO", func(): show_mission_dialogue(stage, 0))
	button(col, "BACK", show_story)

func show_mission_dialogue(stage: int, page: int) -> void:
	var dialogue := [
		["This courtyard was the heart of Haven. Its signal has just come back.", "Recover eight echoes. Follow the markers and watch for health and shield pickups."],
		["The station carried families to safety. I can hear a voice calling through the static.", "The next signal is guarded. Win here and we may remember who was on the train."],
		["I remember now. The fighters are echoes of the people Haven saved.", "Their memories point towards the archive beneath the old city."],
		["The archive is still running, but its records are fragmented.", "Recover the data and I can find the city's final beacon."],
		["The skyline beacon is ready. Every recovered echo has led us here.", "Win the last match and help Haven find its way home."]
	]
	var col := build_screen("ECHO  /  mission %02d" % (stage + 1), "MISSION BRIEFING", "Haven recovery network")
	add_portrait("echo")
	var line := make_label(dialogue[stage][page], 23, Color("e9f8fc"))
	line.custom_minimum_size = Vector2(650, 145)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(line)
	button(col, "NEXT  →" if page == 0 else "START LEVEL  →", func():
		if page == 0:
			show_mission_dialogue(stage, 1)
		else:
			story_mode = true
			story_stage = stage
			chosen_map = stage
			chosen_difficulty = 2 if stage == 4 else (0 if stage == 0 else 1)
			start_match()
	)
	button(col, "BACK TO LEVELS", show_story)

func add_option(col: VBoxContainer, title: String, values: Array, selected: int, callback: Callable) -> void:
	col.add_child(make_label(title, 14, Color("75dde5")))
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(350, 43)
	option.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for item in values:
		option.add_item(item)
	option.select(selected)
	option.item_selected.connect(callback)
	col.add_child(option)

func show_setup() -> void:
	story_mode = false
	var col := build_screen("Match setup", "ENTER THE ARENA", "Pick a location and difficulty. Your current weapon: " + chosen_weapon)
	add_option(col, "ARENA", ["Core Courtyard", "Transit Station", "Overgrown Garden", "Archive Vault", "Skyline Yard", "Random"], chosen_map, func(i): chosen_map = i)
	add_option(col, "BOT DIFFICULTY", ["Easy", "Medium", "Hard"], chosen_difficulty, func(i): chosen_difficulty = i)
	add_option(col, "YOUR FIGHTER", ["Pathfinder", "Scout", "Guardian"], chosen_avatar, func(i): chosen_avatar = i)
	col.add_child(make_label("WASD move  ·  Mouse aim  ·  Left click fire  ·  Space jump  ·  Q dash", 15, Color("bbcbd5")))
	button(col, "START MATCH  →", start_match)
	button(col, "BACK", show_menu)

func show_settings() -> void:
	var col := build_screen("Preferences", "SETTINGS", "Adjust audio and mouse sensitivity. Your choices are saved on this computer.")
	col.add_child(make_label("MASTER VOLUME", 14, Color("75dde5")))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = audio_level
	volume.custom_minimum_size = Vector2(350, 40)
	volume.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	volume.value_changed.connect(func(value):
		audio_level = value
		apply_audio()
		save_progress()
	)
	col.add_child(volume)
	col.add_child(make_label("MOUSE SENSITIVITY", 14, Color("75dde5")))
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.001
	sensitivity.max_value = 0.006
	sensitivity.step = 0.0001
	sensitivity.value = aim_sensitivity
	sensitivity.custom_minimum_size = Vector2(350, 40)
	sensitivity.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sensitivity.value_changed.connect(func(value):
		aim_sensitivity = value
		save_progress()
	)
	col.add_child(sensitivity)
	button(col, "CHANGE PLAYER NAME", show_profile_entry, 440)
	button(col, "BACK", show_menu)

func apply_audio() -> void:
	AudioServer.set_bus_mute(0, audio_level <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(audio_level, 0.001)))

func show_online() -> void:
	story_mode = false
	var col := build_screen("Private match  /  port 7777", "PLAY ONLINE", "Host a match or join a friend using their IP address. The host chooses the arena.")
	add_option(col, "HOST ARENA", ["Core Courtyard", "Transit Station", "Overgrown Garden", "Archive Vault", "Skyline Yard", "Random"], chosen_map, func(i): chosen_map = i)
	add_option(col, "YOUR AVATAR", ["Pathfinder", "Scout", "Guardian"], chosen_avatar, func(i): chosen_avatar = i)
	button(col, "HOST A MATCH", host_online)
	col.add_child(make_label("HOST ADDRESS", 14, Color("75dde5")))
	address_box = LineEdit.new()
	address_box.placeholder_text = "Host IP address, e.g. 192.168.1.10"
	address_box.text = "127.0.0.1"
	address_box.custom_minimum_size = Vector2(380, 40)
	address_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(address_box)
	button(col, "JOIN MATCH", join_online)
	col.add_child(make_label("Same network: use the host's local IP. Internet play may need UDP port forwarding.", 13, Color("a6b6c8")))
	button(col, "BACK", show_menu)

func online_error(message: String) -> void:
	var col := build_screen("Connection", "CONNECTION PROBLEM", message)
	button(col, "BACK", show_online)

func host_online() -> void:
	ensure_uid()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(7777, 4)
	if error != OK:
		online_error("Could not host on UDP port 7777. Check whether it is already in use.")
		return
	online_active = true
	online_finished = false
	online_map = randi_range(0, 4) if chosen_map == 5 else chosen_map
	online_players = {1: chosen_avatar}
	online_health = {1: 100}
	online_scores = {1: 0}
	online_slots = {1: 0}
	online_weapons = {1: chosen_weapon}
	online_helmets = {1: bool(equipped.get("headgear", false))}
	online_identities = {1: {"uid": player_uid, "name": profile_name}}
	multiplayer.multiplayer_peer = peer
	create_online_world(online_map, 0)

func join_online() -> void:
	start_join(address_box.text)

func start_join(raw_address: String) -> void:
	ensure_uid()
	var address := raw_address.strip_edges()
	if address.is_empty():
		online_error("Enter the host's IP address.")
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, 7777)
	if error != OK:
		online_error("Could not create the connection. Check the address and try again.")
		return
	online_active = true
	online_finished = false
	multiplayer.multiplayer_peer = peer
	var col := build_screen("Private match", "CONNECTING...", "Connecting to " + address + ":7777")
	button(col, "CANCEL", leave_online)

func create_online_world(map_index: int, own_slot: int) -> void:
	clear_screen()
	arena = Node3D.new()
	arena.set_script(OnlineArena)
	add_child(arena)
	arena.return_requested.connect(leave_online)
	arena.avatar_index = chosen_avatar
	arena.equipment = {"headgear": bool(equipped.get("headgear", false))}
	arena.start_online(self, map_index, chosen_weapon, own_slot)
	arena.human.mouse_sensitivity = aim_sensitivity

func on_peer_connected(id: int) -> void:
	if online_active and multiplayer.is_server():
		var slot := 1
		while slot in online_slots.values() and slot < 4:
			slot += 1
		online_slots[id] = mini(slot, 3)
		_online_init.rpc_id(id, online_map, int(online_slots[id]))

func on_peer_disconnected(id: int) -> void:
	if online_active and multiplayer.is_server():
		online_players.erase(id)
		online_health.erase(id)
		online_scores.erase(id)
		online_slots.erase(id)
		online_weapons.erase(id)
		online_helmets.erase(id)
		online_identities.erase(id)
		_online_remove.rpc(id)

func on_connection_failed() -> void:
	if online_active:
		online_active = false
		multiplayer.multiplayer_peer = null
		online_error("Could not connect. Check the host address, firewall, and UDP port 7777.")

func on_server_disconnected() -> void:
	if online_active and not online_finished:
		online_active = false
		multiplayer.multiplayer_peer = null
		online_error("The host disconnected.")

func leave_online() -> void:
	online_active = false
	online_finished = false
	multiplayer.multiplayer_peer = null
	show_menu()

@rpc("authority", "call_remote", "reliable")
func _online_init(map_index: int, slot: int) -> void:
	create_online_world(clampi(map_index, 0, 4), clampi(slot, 0, 3))
	_online_ready.rpc_id(1, chosen_avatar, chosen_weapon, bool(equipped.get("headgear", false)), player_uid, profile_name)

@rpc("any_peer", "call_remote", "reliable")
func _online_ready(avatar: int, weapon: String, helmet: bool, uid: String, display_name: String) -> void:
	if not multiplayer.is_server() or not online_active:
		return
	var id := multiplayer.get_remote_sender_id()
	if online_players.has(id):
		return
	for existing in online_players:
		_online_spawn.rpc_id(id, int(existing), int(online_players[existing]), int(online_slots[existing]), str(online_weapons[existing]), bool(online_helmets[existing]), str(online_identities[existing]["uid"]), str(online_identities[existing]["name"]))
	if not valid_uid(uid): return
	online_identities[id] = {"uid": uid, "name": display_name.strip_edges().substr(0, 18)}
	online_players[id] = clampi(avatar, 0, 2)
	online_weapons[id] = weapon if COSTS.has(weapon) else "Pulse Rifle"
	online_helmets[id] = helmet
	online_health[id] = 100
	online_scores[id] = 0
	_online_spawn.rpc(id, int(online_players[id]), int(online_slots[id]), str(online_weapons[id]), bool(online_helmets[id]), uid, str(online_identities[id]["name"]))

@rpc("authority", "call_local", "reliable")
func _online_spawn(id: int, avatar: int, slot: int, weapon: String, helmet: bool, uid: String, display_name: String) -> void:
	if id != multiplayer.get_unique_id(): remember_player(uid, display_name)
	if is_instance_valid(arena) and arena.has_method("add_remote"):
		arena.add_remote(id, avatar, slot, weapon, helmet)

@rpc("authority", "call_local", "reliable")
func _online_remove(id: int) -> void:
	if is_instance_valid(arena) and arena.has_method("remove_remote"):
		arena.remove_remote(id)

func send_online_position(where: Vector3, yaw: float) -> void:
	if not online_active or online_finished:
		return
	if multiplayer.is_server():
		_online_relay.rpc(1, where, yaw)
	else:
		_online_move.rpc_id(1, where, yaw)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _online_move(where: Vector3, yaw: float) -> void:
	if not multiplayer.is_server() or not online_active:
		return
	var id := multiplayer.get_remote_sender_id()
	if not online_players.has(id):
		return
	if is_instance_valid(arena):
		arena.move_remote(id, where, yaw)
	_online_relay.rpc(id, where, yaw)

@rpc("authority", "call_remote", "unreliable_ordered")
func _online_relay(id: int, where: Vector3, yaw: float) -> void:
	if is_instance_valid(arena) and arena.has_method("move_remote"):
		arena.move_remote(id, where, yaw)

func send_online_shot(from: Vector3, to: Vector3) -> void:
	if not online_active or online_finished: return
	if multiplayer.is_server(): _relay_shot.rpc(1, from, to)
	else: _online_shot.rpc_id(1, from, to)

@rpc("any_peer", "call_remote", "unreliable")
func _online_shot(from: Vector3, to: Vector3) -> void:
	if not multiplayer.is_server() or not online_active: return
	var id := multiplayer.get_remote_sender_id()
	if not online_players.has(id): return
	if is_instance_valid(arena): arena.show_remote_shot(id, from, to)
	_relay_shot.rpc(id, from, to)

@rpc("authority", "call_remote", "unreliable")
func _relay_shot(id: int, from: Vector3, to: Vector3) -> void:
	if id != multiplayer.get_unique_id() and is_instance_valid(arena) and arena.has_method("show_remote_shot"):
		arena.show_remote_shot(id, from, to)

func send_online_hit(victim: int, amount: int) -> void:
	if not online_active or online_finished:
		return
	if multiplayer.is_server():
		server_hit(1, victim, amount)
	else:
		_online_hit.rpc_id(1, victim, amount)

@rpc("any_peer", "call_remote", "reliable")
func _online_hit(victim: int, amount: int) -> void:
	if multiplayer.is_server():
		server_hit(multiplayer.get_remote_sender_id(), victim, amount)

func server_hit(attacker: int, victim: int, amount: int) -> void:
	if online_finished or attacker == victim or not online_players.has(attacker) or not online_players.has(victim):
		return
	var hp: int = int(online_health[victim]) - clampi(amount, 0, 55)
	if hp <= 0:
		online_scores[attacker] = int(online_scores[attacker]) + 1
		online_health[victim] = 100
	else:
		online_health[victim] = hp
	_online_health_update.rpc(victim, hp, attacker, int(online_scores[attacker]))
	if int(online_scores[attacker]) >= 8:
		_online_finish.rpc(attacker)

@rpc("authority", "call_local", "reliable")
func _online_health_update(victim: int, hp: int, attacker: int, attacker_score: int) -> void:
	if is_instance_valid(arena) and arena.has_method("receive_health"):
		arena.receive_health(victim, hp, attacker, attacker_score)

@rpc("authority", "call_local", "reliable")
func _online_finish(winner: int) -> void:
	if online_finished:
		return
	online_finished = true
	var won := winner == multiplayer.get_unique_id()
	if won:
		coins += 80
		wins += 1
		save_progress()
	var title := "MATCH WON" if won else "MATCH COMPLETE"
	var col := build_screen("Online result", title, "The host has completed the match.")
	col.add_child(make_label("COINS EARNED   +%d" % (80 if won else 0), 20, Color("f9d17d")))
	button(col, "LEAVE MATCH", leave_online)

func generate_uid() -> String:
	return "HAVEN-" + Crypto.new().generate_random_bytes(16).hex_encode().to_upper()

func valid_uid(value: String) -> bool:
	if value.length() != 38 or not value.begins_with("HAVEN-"): return false
	for ch in value.substr(6):
		if not "0123456789ABCDEF".contains(ch): return false
	return true

func ensure_uid() -> void:
	if not valid_uid(player_uid):
		player_uid = generate_uid()
		save_progress()

func remember_player(uid: String, display_name: String) -> void:
	uid = uid.strip_edges().to_upper()
	if not valid_uid(uid) or uid == player_uid: return
	display_name = display_name.strip_edges().substr(0, 18)
	if display_name.is_empty(): display_name = "Guest"
	for item in recent_players:
		if item is Dictionary and item.get("uid", "") == uid:
			item["name"] = display_name
			save_progress()
			return
	recent_players.push_front({"uid": uid, "name": display_name, "address": ""})
	if recent_players.size() > 30: recent_players.resize(30)
	save_progress()

func show_friends() -> void:
	ensure_uid()
	var col := build_screen("Social  /  local", "FRIENDS", "Search saved friends and recent match players by name or ID on this device.")
	col.add_child(make_label("YOUR NAME: %s" % profile_name, 17, Color("dceaf0")))
	var id_row := HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 12)
	col.add_child(id_row)
	var own_id := LineEdit.new()
	own_id.editable = false
	own_id.add_theme_color_override("font_uneditable_color", Color("eafaff"))
	own_id.text = player_uid
	own_id.custom_minimum_size = Vector2(590, 42)
	id_row.add_child(own_id)
	button(id_row, "COPY ID", func(): DisplayServer.clipboard_set(player_uid), 150)
	friend_query = LineEdit.new()
	friend_query.placeholder_text = "Search by name or full HAVEN ID"
	friend_query.custom_minimum_size = Vector2(590, 42)
	friend_query.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	friend_query.text_changed.connect(refresh_friends)
	col.add_child(friend_query)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 150)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	friend_results = VBoxContainer.new()
	friend_results.add_theme_constant_override("separation", 8)
	scroll.add_child(friend_results)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	col.add_child(actions)
	button(actions, "ADD FRIEND", func(): show_friend_editor({}), 230)
	button(actions, "BACK", show_menu, 180)
	refresh_friends("")

func refresh_friends(query: String) -> void:
	if not is_instance_valid(friend_results): return
	for child in friend_results.get_children(): child.queue_free()
	var needle := query.strip_edges().to_lower()
	var displayed := {}
	for section in [friends, recent_players]:
		for item in section:
			if not item is Dictionary: continue
			var uid := str(item.get("uid", ""))
			var name := str(item.get("name", "Guest"))
			if not valid_uid(uid) or displayed.has(uid): continue
			if not needle.is_empty() and not name.to_lower().contains(needle) and not uid.to_lower().contains(needle): continue
			displayed[uid] = true
			var saved := friend_index(uid) >= 0
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			friend_results.add_child(row)
			var description := make_label("%s  %s\n%s" % [name, "· SAVED" if saved else "· RECENT", uid], 14, Color("d6e9ef"))
			description.custom_minimum_size = Vector2(510, 48)
			row.add_child(description)
			var copy: Dictionary = item.duplicate()
			button(row, "EDIT" if saved else "ADD", func(): show_friend_editor(copy), 110)
			if saved: button(row, "JOIN", func(): join_friend(copy), 110)
	if displayed.is_empty():
		friend_results.add_child(make_label("No local matches. Add a friend's ID or meet them in a private match.", 15, Color("a6b6c8")))

func friend_index(uid: String) -> int:
	for i in range(friends.size()):
		if friends[i] is Dictionary and friends[i].get("uid", "") == uid: return i
	return -1

func show_friend_editor(entry: Dictionary) -> void:
	var col := build_screen("Friends  /  local address book", "SAVE A FRIEND", "Enter the ID exactly. Names may be shared; the ID identifies the saved entry.")
	friend_name_input = LineEdit.new()
	friend_name_input.placeholder_text = "Friend's player name"
	friend_name_input.text = str(entry.get("name", ""))
	friend_name_input.max_length = 18
	friend_name_input.custom_minimum_size = Vector2(590, 43)
	friend_name_input.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(friend_name_input)
	friend_uid_input = LineEdit.new()
	friend_uid_input.placeholder_text = "HAVEN-... ID"
	friend_uid_input.text = str(entry.get("uid", ""))
	friend_uid_input.max_length = 38
	friend_uid_input.custom_minimum_size = Vector2(590, 43)
	friend_uid_input.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(friend_uid_input)
	friend_address_input = LineEdit.new()
	friend_address_input.placeholder_text = "Host IP address (optional, needed to join)"
	friend_address_input.text = str(entry.get("address", ""))
	friend_address_input.custom_minimum_size = Vector2(590, 43)
	friend_address_input.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(friend_address_input)
	friend_error = make_label("", 15, Color("ffb4a8"))
	col.add_child(friend_error)
	button(col, "SAVE FRIEND", save_friend, 390)
	var old_uid := str(entry.get("uid", ""))
	if friend_index(old_uid) >= 0:
		button(col, "REMOVE FRIEND", func():
			var idx := friend_index(old_uid)
			if idx >= 0: friends.remove_at(idx)
			save_progress()
			show_friends()
		, 390)
	button(col, "BACK", show_friends, 390)

func save_friend() -> void:
	var uid := friend_uid_input.text.strip_edges().to_upper()
	var name := friend_name_input.text.strip_edges().substr(0, 18)
	if not valid_uid(uid) or uid == player_uid:
		friend_error.text = "Enter another player's complete HAVEN ID."
		return
	if name.is_empty():
		friend_error.text = "Enter your friend's player name."
		return
	var data := {"uid": uid, "name": name, "address": friend_address_input.text.strip_edges().substr(0, 255)}
	var idx := friend_index(uid)
	if idx >= 0: friends[idx] = data
	else: friends.append(data)
	save_progress()
	show_friends()

func join_friend(entry: Dictionary) -> void:
	var address := str(entry.get("address", "")).strip_edges()
	if address.is_empty():
		show_friend_editor(entry)
		friend_error.text = "Add the host's IP address to join this friend."
		return
	start_join(address)

func show_help() -> void:
	var col := build_screen("Haven guide", "HELP & COMMUNITY", "A fair arena is better for everyone.")
	for line in [
		"PLAY: WASD move · mouse aim · click fire · SPACE jump · Q dash · ESC menu.",
		"RECOVER: Win matches, collect power-ups, and use coins in the market.",
		"RESPECT: Be kind. No harassment, hate, threats, or bullying.",
		"FAIR PLAY: Do not cheat, exploit bugs, impersonate others, or disrupt matches.",
		"PRIVACY: Do not share someone else's personal information or account details.",
		"FRIENDS: IDs and contacts are stored locally. Search covers saved and recent players."
	]:
		var text_line := make_label(line, 17, Color("d6e9ef"))
		text_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(text_line)
	button(col, "BACK", show_menu)

func show_store() -> void:
	var col := build_screen("Haven market", "MARKET & LOADOUT", "Earn coins by winning. Tap an item to buy, equip, or remove it.")
	col.add_child(make_label("YOUR BALANCE   %d COINS" % coins, 19, Color("f9d17d")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 310)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 8)
	scroll.add_child(items)
	items.add_child(make_label("WEAPONS", 16, Color("75dde5")))
	for weapon in COSTS.keys():
		var name: String = weapon
		var status: String = "EQUIPPED" if name == chosen_weapon else ("EQUIP" if name in owned else "%d COINS" % COSTS[name])
		button(items, "%s  ·  %s" % [name.to_upper(), status], func(): select_weapon(name), 590)
	items.add_child(make_label("EQUIPMENT  ·  BONUSES IN SOLO AND STORY", 16, Color("75dde5")))
	for item in GEAR.keys():
		var name: String = item
		var slot: String = GEAR[name]["slot"]
		var status: String = "EQUIPPED" if bool(equipped.get(slot, false)) else ("EQUIP" if name in gear_owned else "%d COINS" % GEAR[name]["cost"])
		button(items, "%s  ·  %s" % [name.to_upper(), status], func(): select_gear(name), 590)
		items.add_child(make_label(GEAR[name]["detail"], 14, Color("a6b6c8")))
	button(col, "BACK", show_menu)

func select_gear(item: String) -> void:
	if not GEAR.has(item): return
	var cost: int = GEAR[item]["cost"]
	if item not in gear_owned:
		if coins < cost: return
		coins -= cost
		gear_owned.append(item)
	var slot: String = GEAR[item]["slot"]
	equipped[slot] = not bool(equipped.get(slot, false))
	save_progress()
	show_store()

func select_weapon(weapon: String) -> void:
	if weapon not in owned:
		if coins < COSTS[weapon]:
			return
		coins -= COSTS[weapon]
		owned.append(weapon)
	chosen_weapon = weapon
	save_progress()
	show_store()

func start_match() -> void:
	save_progress()
	clear_screen()
	arena = Node3D.new()
	arena.set_script(Arena)
	add_child(arena)
	arena.avatar_index = chosen_avatar
	arena.equipment = equipped.duplicate()
	arena.match_finished.connect(on_match_finished)
	arena.return_requested.connect(show_menu)
	var map_index := randi_range(0, 4) if chosen_map == 5 else chosen_map
	arena.start_match(map_index, chosen_difficulty, chosen_weapon)
	arena.human.mouse_sensitivity = aim_sensitivity

func on_match_finished(won: bool, score: int, reason: String) -> void:
	var reward: int = [60, 80, 110][chosen_difficulty] if won else 0
	if won:
		coins += reward
		wins += 1
		if story_mode:
			story_unlocked = mini(4, maxi(story_unlocked, story_stage + 1))
		save_progress()
	var title := "MEMORY RECOVERED" if won else "MATCH COMPLETE"
	var col := build_screen("Match result", title, reason)
	col.add_child(make_label("ELIMINATIONS   %d / 8" % score, 23))
	col.add_child(make_label("COINS EARNED   +%d" % reward, 20, Color("f9d17d")))
	if won:
		var fragments := ["ECHO: 'Someone used to call this place home.'", "ECHO: 'These voices... I think I remember them.'", "ECHO: 'The archive is still waiting for us.'", "ECHO: 'The final beacon is on the skyline.'", "ECHO: 'Haven is its people. Together, we brought it back.'"]
		var fragment_index: int = story_stage if story_mode else (wins - 1) % fragments.size()
		col.add_child(make_label(fragments[fragment_index], 19, Color("75dde5")))
	button(col, "PLAY AGAIN", start_match)
	if story_mode:
		if won and story_stage < 4:
			button(col, "NEXT LEVEL  →", func(): story_brief(story_stage + 1), 440)
		button(col, "STORY MISSIONS", show_story)
	button(col, "HOME", show_menu)

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "coins", coins)
	config.set_value("progress", "wins", wins)
	config.set_value("progress", "story_unlocked", story_unlocked)
	config.set_value("progress", "owned", owned)
	config.set_value("progress", "weapon", chosen_weapon)
	config.set_value("progress", "avatar", chosen_avatar)
	config.set_value("progress", "gear_owned", gear_owned)
	config.set_value("progress", "equipment", equipped)
	config.set_value("profile", "chosen", profile_choice)
	config.set_value("profile", "name", profile_name)
	config.set_value("profile", "uid", player_uid)
	config.set_value("social", "friends", friends)
	config.set_value("social", "recent", recent_players)
	config.set_value("settings", "volume", audio_level)
	config.set_value("settings", "sensitivity", aim_sensitivity)
	config.save(save_path)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	coins = maxi(0, int(config.get_value("progress", "coins", 0)))
	wins = maxi(0, int(config.get_value("progress", "wins", 0)))
	story_unlocked = clampi(int(config.get_value("progress", "story_unlocked", 0)), 0, 4)
	var saved_owned = config.get_value("progress", "owned", ["Pulse Rifle"])
	if saved_owned is Array:
		owned = saved_owned
	audio_level = clampf(float(config.get_value("settings", "volume", 0.8)), 0.0, 1.0)
	aim_sensitivity = clampf(float(config.get_value("settings", "sensitivity", 0.0022)), 0.001, 0.006)
	var saved_gear = config.get_value("progress", "gear_owned", [])
	if saved_gear is Array: gear_owned = saved_gear
	var saved_equipment = config.get_value("progress", "equipment", {})
	if saved_equipment is Dictionary:
		for slot in equipped.keys(): equipped[slot] = bool(saved_equipment.get(slot, false))
	profile_choice = bool(config.get_value("profile", "chosen", false))
	profile_name = str(config.get_value("profile", "name", "Guest"))
	player_uid = str(config.get_value("profile", "uid", ""))
	var saved_friends = config.get_value("social", "friends", [])
	if saved_friends is Array: friends = saved_friends
	var saved_recent = config.get_value("social", "recent", [])
	if saved_recent is Array: recent_players = saved_recent
	chosen_avatar = clampi(int(config.get_value("progress", "avatar", 0)), 0, 2)
	chosen_weapon = str(config.get_value("progress", "weapon", "Pulse Rifle"))
	if chosen_weapon not in owned or not COSTS.has(chosen_weapon):
		chosen_weapon = "Pulse Rifle"
