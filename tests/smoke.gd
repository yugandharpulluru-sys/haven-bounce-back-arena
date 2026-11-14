extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + message)
	else:
		print("PASS: ", message)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene.save_path = "user://haven_smoke_test.cfg"
	scene.coins = 0
	scene.wins = 0
	scene.owned = ["Pulse Rifle"]
	scene.chosen_weapon = "Pulse Rifle"
	await process_frame
	check(is_instance_valid(scene.ui), "opening screen loads")
	scene.show_menu()
	scene.show_setup()
	check(is_instance_valid(scene.ui), "match setup loads")
	for map_id in range(3):
		scene.chosen_map = map_id
		scene.start_match()
		await process_frame
		await physics_frame
		check(is_instance_valid(scene.arena) and is_instance_valid(scene.arena.human), "map %d and player load" % map_id)
		if map_id == 0:
			scene.arena.toggle_pause()
			check(paused, "offline match pauses")
			scene.arena.toggle_pause()
			check(not paused, "offline match resumes")
		var bots := get_nodes_in_group("bots")
		check(bots.size() >= 4, "map %d spawns four bots" % map_id)
		if map_id == 0 and bots.size() >= 4:
			var game = scene.arena
			var before_move: Vector3 = game.human.position
			var key := InputEventKey.new()
			key.keycode = KEY_W
			key.pressed = true
			Input.parse_input_event(key)
			for frame in range(15): await physics_frame
			key = InputEventKey.new()
			key.keycode = KEY_W
			key.pressed = false
			Input.parse_input_event(key)
			check(game.human.position.distance_to(before_move) > 0.1, "movement input changes player position")
			var bot = bots[-1]
			bot.global_position = game.human.global_position + Vector3(0, 0, -4)
			await physics_frame
			for shot in range(4):
				game.human.fire()
			check(game.score == 1, "aimed shots damage and defeat a bot")
			var before: int = scene.coins
			for i in range(7): game.bot_defeated(Vector3.ZERO)
			await process_frame
			check(scene.coins == before + 80, "victory pays coins")
			check(is_instance_valid(scene.ui), "result screen loads")
		await process_frame
	scene.story_unlocked = 0
	scene.story_mode = true
	scene.story_stage = 0
	scene.chosen_map = 0
	scene.chosen_difficulty = 1
	scene.start_match()
	await process_frame
	for i in range(8): scene.arena.bot_defeated(Vector3.ZERO)
	await process_frame
	check(scene.story_unlocked == 1, "story victory unlocks next mission")
	scene.coins = 1000
	scene.select_weapon("Scatter Blaster")
	check(scene.chosen_weapon == "Scatter Blaster" and "Scatter Blaster" in scene.owned, "weapon purchase equips and unlocks")
	scene.chosen_weapon = "Pulse Rifle"
	scene.load_progress()
	check(scene.chosen_weapon == "Scatter Blaster", "progress persists to disk")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.save_path))
	print("SMOKE TEST ", "FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
