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
	scene.save_path = "user://haven_smoke_test.cfg"
	var old_save := ConfigFile.new()
	old_save.set_value("progress", "coins", 999)
	old_save.set_value("profile", "chosen", true)
	old_save.save(scene.save_path)
	root.add_child(scene)
	check(scene.coins == 0 and not scene.profile_choice and not FileAccess.file_exists(scene.save_path), "new run resets profile and progress")
	scene.coins = 0
	scene.wins = 0
	scene.owned = ["Pulse Rifle"]
	scene.chosen_weapon = "Pulse Rifle"
	await process_frame
	check(is_instance_valid(scene.ui), "opening screen loads")
	scene.set_profile("Test Runner")
	check(scene.profile_choice and scene.profile_name == "Test Runner" and scene.valid_uid(scene.player_uid), "local player name and ID are saved")
	var generated := {}
	for sample in range(100): generated[scene.generate_uid()] = true
	check(generated.size() == 100, "generated IDs are distinct in sample")
	var id_one: String = scene.generate_uid()
	var id_two: String = scene.generate_uid()
	scene.show_friend_editor({})
	scene.friend_name_input.text = "Sam"
	scene.friend_uid_input.text = id_one
	scene.save_friend()
	scene.show_friend_editor({})
	scene.friend_name_input.text = "Sam"
	scene.friend_uid_input.text = id_two
	scene.save_friend()
	check(scene.friend_index(id_one) >= 0 and scene.friend_index(id_two) >= 0, "friends can share a username with different IDs")
	scene.refresh_friends("sam")
	await process_frame
	check(scene.friend_results.get_child_count() == 2, "name search returns both matching friends")
	scene.friend_query.text = id_one
	scene.refresh_friends(id_one)
	await process_frame
	check(scene.friend_results.get_child_count() == 1, "friend search finds an exact ID")
	scene.show_help()
	check(is_instance_valid(scene.ui), "help and conduct screen loads")
	scene.show_echo_dialogue(2)
	check(is_instance_valid(scene.menu_preview), "Echo dialogue has an animated 3D portrait")
	scene.show_menu()
	scene.show_setup()
	check(is_instance_valid(scene.ui), "match setup loads")
	var avatar_files := {}
	for avatar_id in range(3):
		var preview := Node3D.new()
		preview.set_script(load("res://scripts/character_visual.gd"))
		root.add_child(preview)
		preview.setup(avatar_id, "Pulse Rifle")
		avatar_files[preview.avatar_file] = true
		check(is_instance_valid(preview.animator) and preview.animator.has_animation("Run_Carry") and preview.animator.has_animation("Roll") and preview.animator.has_animation("Shoot_OneHanded"), "avatar %d has movement and shooting animations" % avatar_id)
		preview.queue_free()
	check(avatar_files.size() == 3, "three different human avatars load")
	for map_id in range(5):
		scene.chosen_map = map_id
		scene.start_match()
		await process_frame
		await physics_frame
		check(is_instance_valid(scene.arena) and is_instance_valid(scene.arena.human), "map %d and player load" % map_id)
		if map_id == 1: check(scene.arena.ground_texture.ends_with("dry_diff.jpg"), "desert uses dry ground")
		if map_id == 2:
			check(scene.arena.ground_texture.ends_with("grass_diff.jpg"), "garden uses grass ground")
			var landscapes := get_nodes_in_group("living_landscapes")
			var living = landscapes[-1]
			check(living.animals.size() == 3 and living.get_child_count() > 100, "forest contains premade vegetation and three animated foxes")
			var before_wildlife: Vector3 = living.animals[0].position
			living._process(1.0)
			check(living.animals[0].position.distance_to(before_wildlife) > 0.1, "forest wildlife moves along its route")
		if map_id == 0:
			scene.arena.toggle_pause()
			check(paused, "offline match pauses")
			scene.arena.toggle_pause()
			check(not paused, "offline match resumes")
		var bots := get_nodes_in_group("bots")
		check(bots.size() >= 4, "map %d spawns four bots" % map_id)
		if map_id == 0 and bots.size() >= 4:
			var game = scene.arena
			check(is_instance_valid(game.human.character) and is_instance_valid(game.human.character.skeleton), "third-person fighter and rig load")
			var character = game.human.character
			check(is_instance_valid(character.animator) and character.animator.has_animation("Run_Carry") and character.animator.has_animation("Roll"), "human fighter has run and roll animations")
			character.animate_motion(0.12, 1.0)
			check(character.animator.current_animation == "Run_Carry", "character uses run animation while moving")
			game.human.perform_roll()
			check(character.animator.current_animation == "Roll" and game.human.roll_cooldown > 0, "dodge roll starts its animation and cooldown")
			game.human.dash_timer = 0
			character.action_time = 0
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
			bot.global_position = game.human.global_position + Vector3(0.7, 0, -4)
			await physics_frame
			for shot in range(4):
				game.human.fire()
			check(not get_nodes_in_group("shot_effects").is_empty(), "weapon creates visible 3D pulse")
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
	scene.coins = 0
	scene.owned = ["Pulse Rifle"]
	scene.select_weapon("Longshot")
	check(scene.market_notice.contains("Not enough coins") and scene.chosen_weapon != "Longshot", "market explains an unaffordable purchase")
	scene.coins = 1000
	scene.select_gear("Kinetic Shield")
	scene.select_gear("Armor Plate")
	scene.select_gear("Tactical Headgear")
	scene.select_gear("Super Dash")
	check(scene.equipped["shield"] and scene.equipped["armor"] and scene.equipped["headgear"] and scene.equipped["dash"], "market purchases and equips all gear")
	scene.chosen_map = 0
	scene.start_match()
	await process_frame
	var fighter = scene.arena.human
	check(fighter.shield == 50 and fighter.has_armor and fighter.super_dash, "equipped gear affects the match")
	fighter.invulnerability = 0
	fighter.take_damage(40)
	check(fighter.shield == 20 and fighter.health == 100, "armor and shield absorb incoming damage")
	fighter.health = 50
	check(fighter.collect_powerup("health") and fighter.health == 85, "health pickup restores health")
	fighter.shield = 0
	check(fighter.collect_powerup("shield") and fighter.shield == 25, "shield pickup recharges shield")
	fighter.dash_cooldown = 2
	check(fighter.collect_powerup("dash") and fighter.dash_cooldown == 0, "dash pickup resets cooldown")
	scene.survival_selected = true
	scene.story_mode = false
	scene.start_match()
	await process_frame
	var coins_before_wave: int = scene.coins
	for i in range(8): scene.arena.bot_defeated(Vector3.ZERO)
	check(scene.arena.wave == 2 and not scene.arena.ended and scene.coins > coins_before_wave, "survival advances to the next rewarding wave")
	scene.survival_selected = false
	scene.coins = 1000
	scene.select_weapon("Scatter Blaster")
	check(scene.chosen_weapon == "Scatter Blaster" and "Scatter Blaster" in scene.owned, "weapon purchase equips and unlocks")
	scene.chosen_weapon = "Pulse Rifle"
	scene.load_progress()
	check(scene.chosen_weapon == "Scatter Blaster" and scene.equipped["shield"] and scene.profile_name == "Test Runner" and scene.valid_uid(scene.player_uid) and scene.friend_index(id_one) >= 0, "in-session save contains progress, gear, ID and friends")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.save_path))
	print("SMOKE TEST ", "FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
