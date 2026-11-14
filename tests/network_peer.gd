extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var role = OS.get_cmdline_user_args()[0]
	if role == "host":
		scene.host_online()
		await create_timer(3.0).timeout
		if scene.online_players.size() != 2 or scene.arena.remotes.size() != 1:
			push_error("host did not receive client")
			quit(1)
			return
		var other: int = int(scene.arena.remotes.keys()[0])
		scene.send_online_hit(other, 55)
		scene.send_online_hit(other, 55)
		await create_timer(1.5).timeout
		if int(scene.online_scores.get(1, 0)) != 1:
			push_error("host scoring failed")
			quit(1)
			return
		print("HOST PASS: connected, spawned peer, transmitted shots and scored")
		await create_timer(2.0).timeout
		quit(0)
	else:
		scene.show_online()
		scene.address_box.text = "127.0.0.1"
		scene.join_online()
		await create_timer(4.0).timeout
		if not is_instance_valid(scene.arena) or scene.arena.remotes.size() != 1:
			push_error("client did not receive host")
			quit(1)
			return
		scene.send_online_hit(1, 55)
		scene.send_online_hit(1, 55)
		await create_timer(1.0).timeout
		if scene.arena.own_score != 1:
			push_error("client scoring failed")
			quit(1)
			return
		print("CLIENT PASS: joined, spawned host, transmitted shots and scored")
		quit(0)
