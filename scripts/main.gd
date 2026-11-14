extends Node

const Arena = preload("res://scripts/arena.gd")
const OnlineArena = preload("res://scripts/online_arena.gd")
const SAVE_PATH := "user://haven_save.cfg"
var save_path := SAVE_PATH
const COSTS := {"Pulse Rifle": 0, "Scatter Blaster": 80, "Longshot": 140}
var coins := 0
var wins := 0
var story_unlocked := 0
var story_mode := false
var story_stage := 0
var owned := ["Pulse Rifle"]
var chosen_weapon := "Pulse Rifle"
var chosen_map := 0
var chosen_difficulty := 1
var chosen_avatar := 0
var audio_level := 0.8
var aim_sensitivity := 0.0022
var intro_camera: Camera3D
var intro_time := 0.0
var ui: Control
var arena: Node3D
var online_players := {}
var online_health := {}
var online_scores := {}
var online_slots := {}
var online_map := 0
var online_active := false
var online_finished := false
var address_box: LineEdit

func _ready() -> void:
	load_progress()
	apply_audio()
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	multiplayer.connection_failed.connect(on_connection_failed)
	multiplayer.server_disconnected.connect(on_server_disconnected)
	show_intro()

func clear_screen() -> void:
	get_tree().paused = false
	intro_camera = null
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
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var background := ColorRect.new()
	background.color = Color("0b111e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	var side := ColorRect.new()
	side.color = Color("14283a")
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
	label.add_theme_color_override("font_color", color)
	return label

func button(parent: Node, title: String, action: Callable, width: int = 350) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(width, 47)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func show_intro() -> void:
	var col := build_screen("Incoming transmission  /  01", "HAVEN: BOUNCE BACK", "THE CITY FELL. ITS STORY DID NOT.")
	add_intro_scene()
	col.add_child(make_label("Years ago, Haven went silent.", 23))
	col.add_child(make_label("Now an AI called ECHO is bringing the arena back online.", 20, Color("b4c9d8")))
	col.add_child(make_label("Win matches. Recover memories. Discover who is fighting back.", 20, Color("b4c9d8")))
	col.add_spacer(false)
	button(col, "ENTER HAVEN  →", show_menu)
	col.add_child(make_label("A signal is returning  •  A city is waiting", 13, Color("8194a8")))

func add_intro_scene() -> void:
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(container)
	ui.move_child(container, 1)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var world := Node3D.new()
	world.set_script(Arena)
	viewport.add_child(world)
	world.build_environment(0)
	world.build_arena(0)
	intro_camera = Camera3D.new()
	world.add_child(intro_camera)
	intro_camera.position = Vector3(18, 12, 23)
	intro_camera.look_at(Vector3(0, 1, 0))
	intro_camera.current = true
	var tint := ColorRect.new()
	tint.color = Color(0.02, 0.05, 0.1, 0.66)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	ui.move_child(tint, 2)

func _process(delta: float) -> void:
	if is_instance_valid(intro_camera):
		intro_time += delta
		intro_camera.position = Vector3(sin(intro_time * 0.08) * 18.0, 11.0, cos(intro_time * 0.08) * 22.0)
		intro_camera.look_at(Vector3(0, 1, 0))

func show_menu() -> void:
	story_mode = false
	var col := build_screen("Haven systems  /  online", "WELCOME BACK", "The arena is waiting. Choose how you want to play.")
	col.add_child(make_label("%d COINS       %d VICTORIES" % [coins, wins], 17, Color("f9d17d")))
	button(col, "PLAY VS AI  →", show_setup)
	button(col, "LOADOUT & WEAPONS", show_store)
	button(col, "STORY MISSIONS", show_story)
	button(col, "ONLINE MULTIPLAYER", show_online)
	button(col, "SETTINGS", show_settings)
	button(col, "QUIT", func(): get_tree().quit())
	col.add_child(make_label("RECOVER THE SIGNAL  •  RESTORE HAVEN", 13, Color("8194a8")))

func show_story() -> void:
	story_mode = false
	var col := build_screen("The Haven archive", "STORY MISSIONS", "Recover the memories hidden across the arenas. Each victory unlocks the next signal.")
	var titles := ["01  THE FIRST SIGNAL  ·  CORE COURTYARD", "02  THE EMPTY PLATFORM  ·  TRANSIT", "03  WHAT HAVEN REMEMBERS  ·  GARDEN"]
	for i in range(3):
		var stage := i
		var unlocked := i <= story_unlocked
		button(col, titles[i] + ("" if unlocked else "  ·  LOCKED"), func():
			if unlocked:
				story_brief(stage)
		, 610)
	button(col, "REPLAY OPENING", show_intro)
	button(col, "BACK", show_menu)

func story_brief(stage: int) -> void:
	var titles := ["THE FIRST SIGNAL", "THE EMPTY PLATFORM", "WHAT HAVEN REMEMBERS"]
	var briefs := [
		"ECHO: 'The core is awake. Recover its signal and I can open the archive.'",
		"ECHO: 'This station should be empty. Why do I remember waiting here?'",
		"ECHO: 'The fighters were never strangers. They are the people Haven saved.'"
	]
	var col := build_screen("Story  /  mission %02d" % (stage + 1), titles[stage], briefs[stage])
	col.add_child(make_label("OBJECTIVE: Recover 8 echoes before time runs out.", 19, Color("b4c9d8")))
	button(col, "BEGIN MISSION", func():
		story_mode = true
		story_stage = stage
		chosen_map = stage
		chosen_difficulty = 1
		start_match()
	)
	button(col, "BACK", show_story)

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
	add_option(col, "ARENA", ["Core Courtyard", "Transit Station", "Overgrown Garden", "Random"], chosen_map, func(i): chosen_map = i)
	add_option(col, "BOT DIFFICULTY", ["Easy", "Medium", "Hard"], chosen_difficulty, func(i): chosen_difficulty = i)
	add_option(col, "AVATAR (VISIBLE IN ONLINE MATCHES)", ["Pathfinder", "Scout", "Guardian"], chosen_avatar, func(i): chosen_avatar = i)
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
	button(col, "BACK", show_menu)

func apply_audio() -> void:
	AudioServer.set_bus_mute(0, audio_level <= 0.001)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(audio_level, 0.001)))

func show_online() -> void:
	story_mode = false
	var col := build_screen("Private match  /  port 7777", "PLAY ONLINE", "Host a match or join a friend using their IP address. The host chooses the arena.")
	add_option(col, "HOST ARENA", ["Core Courtyard", "Transit Station", "Overgrown Garden", "Random"], chosen_map, func(i): chosen_map = i)
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
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(7777, 4)
	if error != OK:
		online_error("Could not host on UDP port 7777. Check whether it is already in use.")
		return
	online_active = true
	online_finished = false
	online_map = randi_range(0, 2) if chosen_map == 3 else chosen_map
	online_players = {1: chosen_avatar}
	online_health = {1: 100}
	online_scores = {1: 0}
	online_slots = {1: 0}
	multiplayer.multiplayer_peer = peer
	create_online_world(online_map, 0)

func join_online() -> void:
	var address := address_box.text.strip_edges()
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
	create_online_world(clampi(map_index, 0, 2), clampi(slot, 0, 3))
	_online_ready.rpc_id(1, chosen_avatar)

@rpc("any_peer", "call_remote", "reliable")
func _online_ready(avatar: int) -> void:
	if not multiplayer.is_server() or not online_active:
		return
	var id := multiplayer.get_remote_sender_id()
	if online_players.has(id):
		return
	for existing in online_players:
		_online_spawn.rpc_id(id, int(existing), int(online_players[existing]), int(online_slots[existing]))
	online_players[id] = clampi(avatar, 0, 2)
	online_health[id] = 100
	online_scores[id] = 0
	_online_spawn.rpc(id, int(online_players[id]), int(online_slots[id]))

@rpc("authority", "call_local", "reliable")
func _online_spawn(id: int, avatar: int, slot: int) -> void:
	if is_instance_valid(arena) and arena.has_method("add_remote"):
		arena.add_remote(id, avatar, slot)

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

func show_store() -> void:
	var col := build_screen("Equipment", "LOADOUT", "Win matches to earn coins. Weapons have different strengths, not just higher damage.")
	col.add_child(make_label("BALANCE: %d COINS" % coins, 18, Color("f9d17d")))
	for weapon in COSTS.keys():
		var status: String = "EQUIPPED" if weapon == chosen_weapon else ("EQUIP" if weapon in owned else "UNLOCK  ·  %d COINS" % COSTS[weapon])
		button(col, "%s   —   %s" % [weapon.to_upper(), status], func(): select_weapon(weapon), 540)
	col.add_child(make_label("Pulse: balanced  ·  Scatter: close range  ·  Longshot: accurate, slower", 14, Color("a6b6c8")))
	button(col, "BACK", show_menu)

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
	arena.match_finished.connect(on_match_finished)
	arena.return_requested.connect(show_menu)
	var map_index := randi_range(0, 2) if chosen_map == 3 else chosen_map
	arena.start_match(map_index, chosen_difficulty, chosen_weapon)
	arena.human.mouse_sensitivity = aim_sensitivity

func on_match_finished(won: bool, score: int, reason: String) -> void:
	var reward: int = [60, 80, 110][chosen_difficulty] if won else 0
	if won:
		coins += reward
		wins += 1
		if story_mode:
			story_unlocked = mini(2, maxi(story_unlocked, story_stage + 1))
		save_progress()
	var title := "MEMORY RECOVERED" if won else "MATCH COMPLETE"
	var col := build_screen("Match result", title, reason)
	col.add_child(make_label("ELIMINATIONS   %d / 8" % score, 23))
	col.add_child(make_label("COINS EARNED   +%d" % reward, 20, Color("f9d17d")))
	if won:
		var fragments := ["ECHO: 'Someone used to call this place home.'", "ECHO: 'These voices... I think I remember them.'", "ECHO: 'Haven is its people. Together, we can bring it back.'"]
		var fragment_index: int = story_stage if story_mode else (wins - 1) % fragments.size()
		col.add_child(make_label(fragments[fragment_index], 19, Color("75dde5")))
	button(col, "PLAY AGAIN", start_match)
	if story_mode:
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
	config.set_value("settings", "volume", audio_level)
	config.set_value("settings", "sensitivity", aim_sensitivity)
	config.save(save_path)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	coins = maxi(0, int(config.get_value("progress", "coins", 0)))
	wins = maxi(0, int(config.get_value("progress", "wins", 0)))
	story_unlocked = clampi(int(config.get_value("progress", "story_unlocked", 0)), 0, 2)
	var saved_owned = config.get_value("progress", "owned", ["Pulse Rifle"])
	if saved_owned is Array:
		owned = saved_owned
	audio_level = clampf(float(config.get_value("settings", "volume", 0.8)), 0.0, 1.0)
	aim_sensitivity = clampf(float(config.get_value("settings", "sensitivity", 0.0022)), 0.001, 0.006)
	chosen_avatar = clampi(int(config.get_value("progress", "avatar", 0)), 0, 2)
	chosen_weapon = str(config.get_value("progress", "weapon", "Pulse Rifle"))
	if chosen_weapon not in owned or not COSTS.has(chosen_weapon):
		chosen_weapon = "Pulse Rifle"
