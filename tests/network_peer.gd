extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func wait_for(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if condition.call(): return true
		await create_timer(0.05).timeout
	return false

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	var role = OS.get_cmdline_user_args()[0]
	scene.save_path = "user://haven_network_test_" + role + ".cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.save_path))
	root.add_child(scene)
	await process_frame
	scene.set_profile("Net " + role)
	if role == "host":
		scene.host_online()
		await wait_for(func(): return is_instance_valid(scene.arena) and scene.online_players.size() == 2 and scene.arena.remotes.size() == 1)
		if scene.online_players.size() != 2 or scene.arena.remotes.size() != 1:
			push_error("host did not receive client")
			quit(1)
			return
		if scene.recent_players.size() < 1 or scene.recent_players[0]["name"] != "Net client":
			push_error("host did not receive the client identity")
			quit(1)
			return
		var other: int = int(scene.arena.remotes.keys()[0])
		scene.send_online_shot(Vector3(0, 1, 0), Vector3(2, 1, 0))
		scene.send_online_hit(other, 55)
		scene.send_online_hit(other, 55)
		await wait_for(func(): return int(scene.online_scores.get(1, 0)) == 1)
		if int(scene.online_scores.get(1, 0)) != 1:
			push_error("host scoring failed")
			quit(1)
			return
		print("HOST PASS: connected, spawned peer, transmitted shots and scored")
		await wait_for(func(): return int(scene.online_scores.get(other, 0)) == 1)
		await create_timer(0.5).timeout
		quit(0)
	else:
		scene.show_online()
		scene.address_box.text = "127.0.0.1"
		scene.join_online()
		await wait_for(func(): return is_instance_valid(scene.arena) and scene.arena.remotes.size() == 1 and scene.arena.remote_shots_seen >= 1)
		if not is_instance_valid(scene.arena) or scene.arena.remotes.size() != 1:
			push_error("client did not receive host")
			quit(1)
			return
		if scene.recent_players.size() < 1 or scene.recent_players[0]["name"] != "Net host":
			push_error("client did not receive the host identity")
			quit(1)
			return
		if scene.arena.remote_shots_seen < 1:
			push_error("remote pulse was not replicated")
			quit(1)
			return
		scene.send_online_hit(1, 55)
		scene.send_online_hit(1, 55)
		await wait_for(func(): return scene.arena.own_score == 1)
		if scene.arena.own_score != 1:
			push_error("client scoring failed")
			quit(1)
			return
		print("CLIENT PASS: joined, spawned host, transmitted shots and scored")
		quit(0)
