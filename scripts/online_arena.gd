extends "res://scripts/arena.gd"

const RemotePlayer = preload("res://scripts/online_player.gd")
var controller: Node
var remotes := {}
var update_timer := 0.0
var own_score := 0
var own_slot := 0
var remote_shots_seen := 0

func start_online(main: Node, map_index: int, weapon: String, slot: int) -> void:
	controller = main
	own_slot = slot
	online_mode = true
	accent = colors[map_index]
	build_environment(map_index)
	build_arena(map_index)
	build_hud(MAPS[map_index] + "  /  ONLINE", weapon)
	hud_clock.text = "ONLINE"
	hud_score.text = "ELIMINATIONS  0 / 8"
	human = CharacterBody3D.new()
	human.set_script(Player)
	add_child(human)
	human.health_changed.connect(update_health)
	human.shield_changed.connect(update_shield)
	human.setup(self, weapon, spawn_for(own_slot))
	show_message("WAITING FOR OPPONENTS", 3.0)

func spawn_for(slot: int) -> Vector3:
	var points := [Vector3(0, 1, 13), Vector3(0, 1, -13), Vector3(13, 1, 8), Vector3(-13, 1, -8)]
	return points[clampi(slot, 0, 3)]

func add_remote(id: int, avatar: int = 0, slot: int = 0, weapon: String = "Pulse Rifle", helmet: bool = false) -> void:
	if id == multiplayer.get_unique_id() or remotes.has(id):
		return
	var actor := CharacterBody3D.new()
	actor.set_script(RemotePlayer)
	add_child(actor)
	actor.setup(self, id, avatar, weapon, helmet)
	actor.position = spawn_for(slot)
	remotes[id] = actor
	show_message("PLAYER JOINED THE ARENA", 2.0)

func remove_remote(id: int) -> void:
	if remotes.has(id):
		remotes[id].queue_free()
		remotes.erase(id)
		show_message("PLAYER LEFT", 2.0)

func move_remote(id: int, where: Vector3, yaw: float) -> void:
	if remotes.has(id) and is_instance_valid(remotes[id]):
		remotes[id].global_position = where
		remotes[id].rotation.y = yaw

func broadcast_shot(from: Vector3, to: Vector3) -> void:
	controller.send_online_shot(from, to)

func show_remote_shot(id: int, from: Vector3, to: Vector3) -> void:
	remote_shots_seen += 1
	if remotes.has(id):
		remotes[id].show_fire()
	spawn_pulse(from, to)

func request_hit(id: int, amount: int) -> void:
	controller.send_online_hit(id, amount)

func receive_health(id: int, new_health: int, attacker: int, attacker_score: int) -> void:
	if id == multiplayer.get_unique_id():
		human.health = maxi(0, new_health)
		update_health(human.health, 1)
		if new_health <= 0:
			human.global_position = spawn_for(own_slot)
			human.velocity = Vector3.ZERO
			human.health = 100
			update_health(100, 1)
			show_message("REBOOTED", 1.5)
	if attacker == multiplayer.get_unique_id() and new_health <= 0:
		own_score = attacker_score
		hud_score.text = "ELIMINATIONS  %d / 8" % own_score
		show_message("OPPONENT ELIMINATED", 1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(human) or not is_instance_valid(controller):
		return
	message_time -= delta
	if message_time <= 0:
		hud_message.text = ""
	hit_time -= delta
	if hit_time <= 0:
		hud_hit.visible = false
	update_timer -= delta
	if update_timer <= 0:
		update_timer = 0.06
		controller.send_online_position(human.global_position, human.rotation.y)
