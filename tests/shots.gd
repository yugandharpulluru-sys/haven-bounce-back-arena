extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failed = true; push_error(message)
	else: print("PASS: ", message)
func run():
	var arena := Node3D.new()
	arena.set_script(load("res://scripts/arena.gd"))
	root.add_child(arena)
	arena.spawn_pulse(Vector3.ZERO,Vector3(0,0,-10),Color.CYAN,false)
	check(get_nodes_in_group("shot_effects").size() == 1,"tracer spawns with a bright core and trail")
	await create_timer(0.3).timeout
	check(get_nodes_in_group("impact_effects").is_empty(),"missed shot does not create a floating impact")
	arena.spawn_pulse(Vector3.ZERO,Vector3(0,0,-5),Color.CYAN,true,Vector3.BACK)
	await create_timer(0.08).timeout
	check(not get_nodes_in_group("impact_effects").is_empty(),"hit creates sparks and impact ring")
	await create_timer(0.4).timeout
	check(get_nodes_in_group("shot_effects").is_empty() and get_nodes_in_group("impact_effects").is_empty(),"transient bullet and hit effects clean up")
	arena.queue_free()
	await process_frame
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_guest()
	game.chosen_weapon = "Scatter Blaster"
	game.start_match()
	await physics_frame
	for bot in get_nodes_in_group("bots"): bot.set_physics_process(false)
	game.arena.human.fire()
	check(get_nodes_in_group("shot_effects").size() == 7,"scatter weapon shows all seven pellets")
	await create_timer(0.8).timeout
	game.queue_free()
	await process_frame
	print("SHOT TEST ","FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
