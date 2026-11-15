extends Node3D

var skeleton: Skeleton3D
var animator: AnimationPlayer
var gun_model: Node3D
var muzzle_x := -0.75
var helmet: MeshInstance3D
var recoil := 0.0
var action_time := 0.0
var action_name := ""
var last_motion := ""
var avatar_file := ""
var preview_idle := false

func setup(avatar: int, weapon: String, wear_helmet: bool = false) -> void:
	var names := ["survivor", "scout", "runner"]
	avatar_file = names[clampi(avatar, 0, 2)]
	var packed = load("res://assets/humans/" + avatar_file + ".glb")
	if packed:
		var model = packed.instantiate()
		model.scale = Vector3.ONE
		model.rotation.y = PI
		add_child(model)
		# The source characters use a placeholder dark-grey skin material.
		var skin_tones := [Color("bc896e"), Color("94654d"), Color("d3aa8d")]
		for mesh_instance in model.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh_instance.mesh.get_surface_count()):
				var original = mesh_instance.mesh.surface_get_material(surface)
				if original is StandardMaterial3D and original.resource_name == "Skin":
					var adjusted: StandardMaterial3D = original.duplicate()
					adjusted.albedo_color = skin_tones[clampi(avatar, 0, 2)]
					mesh_instance.set_surface_override_material(surface, adjusted)
		var skeletons = model.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty(): skeleton = skeletons[0]
		var players = model.find_children("*", "AnimationPlayer", true, false)
		if not players.is_empty():
			animator = players[0]
			for name in ["Idle", "ArmedIdle", "Walk", "Run", "Walk_Carry", "Run_Carry"]:
				if animator.has_animation(name): animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
			play_motion("Idle")
	var asset := "Gun_Rifle" if weapon == "Pulse Rifle" else ("Gun_Pistol" if weapon == "Scatter Blaster" else "Gun_Sniper")
	var gun_scene = load("res://assets/quaternius/" + asset + ".gltf")
	muzzle_x = -0.37 if weapon == "Scatter Blaster" else (-1.27 if weapon == "Longshot" else -0.75)
	if gun_scene:
		gun_model = gun_scene.instantiate()
		gun_model.position = Vector3(-0.48, 1.08, -0.12)
		gun_model.rotation.y = -PI / 2.0
		gun_model.scale = Vector3.ONE * (1.0 if weapon == "Scatter Blaster" else 0.65)
		add_child(gun_model)
	helmet = MeshInstance3D.new()
	var visor := SphereMesh.new()
	visor.radius = 0.17
	visor.height = 0.17
	helmet.mesh = visor
	helmet.position = Vector3(0, 1.72, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("53e5ee")
	mat.metallic = 0.65
	mat.roughness = 0.25
	helmet.material_override = mat
	helmet.visible = wear_helmet
	add_child(helmet)

func play_motion(name: String) -> void:
	if is_instance_valid(animator) and animator.has_animation(name) and animator.current_animation != name:
		animator.play(name, 0.12)
		last_motion = name

func animate_motion(delta: float, movement: float, grounded: bool = true) -> void:
	recoil = maxf(0, recoil - delta * 5.5)
	action_time = maxf(0.0, action_time - delta)
	if action_time > 0:
		play_motion(action_name)
	elif not grounded:
		play_motion("Jump")
	elif movement > 0.18:
		play_motion("Run_Carry" if movement > 0.9 else "Walk_Carry")
	else:
		play_motion("Idle" if preview_idle else "ArmedIdle")
	if is_instance_valid(gun_model) and is_instance_valid(skeleton):
		var hand_id := skeleton.find_bone("hand_r")
		if hand_id >= 0:
			var hand_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(hand_id)
			gun_model.position = to_local(hand_transform.origin) + Vector3(0.0, 0.0, -0.12 + recoil * 0.11)

func fire_animation() -> void:
	recoil = 1.0
	if action_name != "Roll" or action_time <= 0:
		action_name = "Shoot_OneHanded"
		action_time = 0.30
		play_motion(action_name)

func roll_animation() -> void:
	action_name = "Roll"
	action_time = 0.55
	play_motion(action_name)

func muzzle_position() -> Vector3:
	if is_instance_valid(gun_model): return gun_model.to_global(Vector3(muzzle_x, 0.04, 0))
	return global_position + global_basis * Vector3(-0.48, 1.12, -0.72)
