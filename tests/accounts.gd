extends SceneTree
var failed := false
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok:
		failed = true
		push_error(message)
	else: print("PASS: ", message)
func run():
	var folder := "user://account_test_" + str(Time.get_ticks_usec())
	var a = load("res://scenes/main.tscn").instantiate()
	a.accounts.directory = folder
	root.add_child(a)
	check(not a.open_account("Alex", "short", true).is_empty(), "weak password rejected")
	check(a.open_account("Alex", "local-test-secret", true).is_empty(), "account created")
	a.profile_name = "Display name"
	a.coins = 185
	a.wins = 3
	a.chosen_avatar = 2
	a.story_unlocked = 2
	a.friends = [{"name":"Friend", "uid":a.generate_uid(), "address":""}]
	var uid: String = a.player_uid
	a.save_progress()
	var path: String = a.save_path
	var credentials := FileAccess.get_file_as_string(a.accounts.credential_path("Alex"))
	check(not credentials.contains("local-test-secret"), "password never stored as plaintext")
	a.sign_out()
	check(a.coins == 0 and a.friends.is_empty(), "sign out clears active account data")
	check(not a.open_account("alex", "local-test-secret", true).is_empty(), "case-insensitive duplicate username rejected")
	check(not a.open_account("Alex", "wrong-password", false).is_empty() and not a.signed_in, "wrong password cannot open account")
	a.start_guest()
	a.coins = 999
	a.save_progress()
	check(a.accounts.verify("Alex", "local-test-secret").is_empty(), "guest cannot overwrite account credentials")
	a.queue_free()
	await process_frame
	var b = load("res://scenes/main.tscn").instantiate()
	b.accounts.directory = folder
	root.add_child(b)
	check(b.open_account("alex", "local-test-secret", false).is_empty(), "fresh game instance signs in")
	check(b.coins == 185 and b.wins == 3 and b.profile_name == "Display name" and b.chosen_avatar == 2 and b.story_unlocked == 2 and b.friends.size() == 1 and b.player_uid == uid, "progress, name, character, friends and UID survive restart and guest session")
	b.sign_out()
	check(b.open_account("Blair", "second-test-secret", true).is_empty() and b.coins == 0 and b.friends.is_empty(), "second account starts independently")
	b.sign_out()
	var broken := FileAccess.open(path, FileAccess.WRITE)
	broken.store_string("[broken"); broken.close()
	check(not b.open_account("Alex", "local-test-secret", false).is_empty() and not b.signed_in, "damaged progress is not silently overwritten")
	b.queue_free()
	await process_frame
	for filename in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(filename))
	DirAccess.remove_absolute(folder)
	print("ACCOUNT TEST ", "FAILED" if failed else "PASSED")
	quit(1 if failed else 0)
