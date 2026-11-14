extends Node3D

var skeleton: Skeleton3D
var bone_indices := {}
var rest_rotations := {}
var move_amount := 0.0
var time := 0.0
var recoil := 0.0
var gun_model: Node3D
var muzzle_x := -0.75
var helmet: MeshInstance3D

func setup(avatar: int, weapon: String, wear_helmet: bool = false) -> void:
	var names := ["astronaut", "pathfinder", "guardian"]
	var packed = load("res://assets/characters/" + names[clampi(avatar, 0, 2)] + ".glb")
	if packed:
		var model = packed.instantiate()
		model.rotation.y = PI
		add_child(model)
		var skeletons = model.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty():
			skeleton = skeletons[0]
			for name in ["thigh.L", "thigh.R", "upper_arm.L", "upper_arm.R", "forearm.L", "forearm.R"]:
				var id: int = skeleton.find_bone(name)
				if id >= 0:
					bone_indices[name] = id
					rest_rotations[name] = skeleton.get_bone_pose_rotation(id)
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
	helmet.position = Vector3(0, 1.88, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("53e5ee")
	mat.metallic = 0.65
	mat.roughness = 0.25
	helmet.material_override = mat
	helmet.visible = wear_helmet
	add_child(helmet)

func animate_motion(delta: float, movement: float) -> void:
	time += delta * 9.0
	move_amount = lerpf(move_amount, clampf(movement, 0, 1), minf(1.0, delta * 10.0))
	recoil = maxf(0, recoil - delta * 5.5)
	var swing := sin(time) * move_amount * 0.5
	pose("thigh.L", Vector3.RIGHT, swing)
	pose("thigh.R", Vector3.RIGHT, -swing)
	pose("upper_arm.L", Vector3.RIGHT, -swing * 0.30 - recoil * 0.20)
	pose("upper_arm.R", Vector3.RIGHT, swing * 0.20 - recoil * 0.32)
	if is_instance_valid(gun_model):
		if is_instance_valid(skeleton) and bone_indices.has("hand.L"):
			var hand_transform: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_indices["hand.L"])
			gun_model.position = to_local(hand_transform.origin) + Vector3(0.08, 0.0, -0.12 + recoil * 0.11)
		else:
			gun_model.position.z = -0.12 + recoil * 0.11

func fire_animation() -> void:
	recoil = 1.0

func pose(name: String, axis: Vector3, angle: float) -> void:
	if is_instance_valid(skeleton) and bone_indices.has(name):
		skeleton.set_bone_pose_rotation(bone_indices[name], rest_rotations[name] * Quaternion(axis, angle))

func muzzle_position() -> Vector3:
	if is_instance_valid(gun_model):
		return gun_model.to_global(Vector3(muzzle_x, 0.04, 0))
	return global_position + global_basis * Vector3(-0.48, 1.12, -0.72)
