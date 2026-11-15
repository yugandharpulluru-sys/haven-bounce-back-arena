extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failed = true; push_error(message)
	else: print("PASS: ",message)
func run():
	var main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.start_guest()
	main.start_match()
	var game=main.arena
	var player=game.human
	player.set_physics_process(false)
	player.invulnerability=10000
	player.position=Vector3(-9,0,12)
	for i in range(5): await physics_frame
	check(game.navigation.ready_for_paths,"shared clearance grid builds after physics sync")
	var bots=get_nodes_in_group("bots")
	for other in bots: other.set_physics_process(false)
	var bot=bots[1]
	bot.global_position=Vector3(-9,0,-10)
	bot.velocity=Vector3.ZERO
	bot.attack_timer=1000
	bot.set_physics_process(true)
	var start_distance: float=bot.global_position.distance_to(player.global_position)
	var deviation := 0.0
	var saw_run := false
	Engine.time_scale=4.0
	for i in range(300):
		await physics_frame
		deviation=maxf(deviation,absf(bot.position.x+9.0))
		if is_instance_valid(bot.animator) and bot.animator.current_animation == "Run": saw_run = true
	Engine.time_scale=1.0
	check(bot.global_position.distance_to(player.global_position) < start_distance-8.0,"bot pursues player instead of staying at its spawn")
	check(saw_run,"ground robot uses its running animation while pursuing")
	check(deviation > 1.5,"bot routes around solid cover")
	check(bot.global_position.distance_to(player.global_position) < 8.0,"close-range bot presses inside the old 13-metre strafe range")
	bot.global_position=Vector3(-9,0,-7)
	player.global_position=Vector3(-9,0,0)
	player.health=100
	player.invulnerability=0
	bot.attack_timer=0
	bot.velocity=Vector3.ZERO
	for i in range(3): await physics_frame
	check(not bot.has_sight and player.health == 100,"solid cover blocks bot fire")
	bot.take_damage(10000)
	check(not bot.alive,"bot defeat still works")
	bot.respawn()
	check(bot.alive and bot.path.is_empty(),"respawn clears old route")
	main.queue_free()
	await process_frame
	print("BOT NAVIGATION TEST ","FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
