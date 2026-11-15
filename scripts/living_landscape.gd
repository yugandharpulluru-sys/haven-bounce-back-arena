extends Node3D
## Premade scanned vegetation, rocks and animated wildlife. Deterministic placement.
var rng := RandomNumberGenerator.new()
var animals: Array[Node3D] = []
var elapsed := 0.0
var forest := false
var bounds_cache := {}
var packed_cache := {}

func asset(id: String, point: Vector3, height: float, wind: float = 0.0) -> Node3D:
	if not packed_cache.has(id): packed_cache[id] = load("res://assets/nature/" + id + ".glb")
	var root := Node3D.new()
	add_child(root)
	var model: Node3D = packed_cache[id].instantiate()
	root.add_child(model)
	if not bounds_cache.has(id):
		var bounds := AABB()
		var first := true
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
			bounds = a if first else bounds.merge(a)
			first = false
		bounds_cache[id] = bounds
	var b: AABB = bounds_cache[id]
	var factor := height / maxf(b.size.y, 0.01)
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z) * factor
	root.position = point
	root.rotation.y = rng.randf_range(-PI, PI)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var source = mesh.get_active_material(i)
			if source is StandardMaterial3D:
				var matte: StandardMaterial3D = source.duplicate()
				matte.metallic = 0.0
				matte.roughness = 0.95
				matte.roughness_texture = null
				mesh.set_surface_override_material(i, matte)
	if wind > 0:
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			for i in range(mesh.mesh.get_surface_count()):
				var original = mesh.get_active_material(i)
				if original is StandardMaterial3D and original.albedo_texture:
					var m := ShaderMaterial.new()
					m.shader = preload("res://assets/shaders/foliage.gdshader")
					m.set_shader_parameter("albedo_tex", original.albedo_texture)
					m.set_shader_parameter("tint", original.albedo_color)
					m.set_shader_parameter("strength", wind)
					mesh.set_surface_override_material(i, m)
	return root

func build(is_forest: bool) -> void:
	add_to_group("living_landscapes")
	forest = is_forest
	rng.seed = 711 if forest else 192
	# Irregular rock escarpments hide the collision boundary and frame the horizon.
	for i in range(48):
		var angle := TAU * i / 48.0
		var radius := rng.randf_range(28, 36)
		var p := Vector3(cos(angle) * radius, -0.6, sin(angle) * radius)
		var rock := asset("rock_07", p, rng.randf_range(5, 11) if not forest else rng.randf_range(2, 3.5))
		rock.scale.x = rng.randf_range(1.3, 2.0)
		if not forest:
			for mesh in rock.find_children("*", "MeshInstance3D", true, false):
				for s in range(mesh.mesh.get_surface_count()):
					var m: StandardMaterial3D = mesh.get_active_material(s).duplicate()
					m.albedo_color = Color("cdaa7e")
					mesh.set_surface_override_material(s, m)
	if forest:
		for i in range(36):
			var angle := i * TAU / 36
			var radius := rng.randf_range(22, 37)
			asset("tree_small_02", Vector3(cos(angle)*radius, 0, sin(angle)*radius), rng.randf_range(12, 18), 0.009)
		for i in range(140):
			var p := Vector3(rng.randf_range(-24,24), 0.02, rng.randf_range(-24,24))
			# Leave a clear central combat lane and spawn area.
			if absf(p.x) < 4 or p.distance_to(Vector3(0,0,13)) < 3: continue
			asset("grass_medium_01" if i % 3 else "fern_02", p, rng.randf_range(0.35,0.85), 0.12)
		for i in range(3):
			var fox := asset("fox", Vector3.ZERO, 0.7)
			var anims := fox.find_children("*", "AnimationPlayer", true, false)
			if not anims.is_empty():
				var anim: AnimationPlayer = anims[0]
				for clip in anim.get_animation_list():
					if "Walk" in clip:
						anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
						anim.play(clip)
			animals.append(fox)
	else:
		for i in range(24):
			var p := Vector3(rng.randf_range(-23,23),0,rng.randf_range(-23,23))
			if absf(p.x) < 8: p.x += 12 * signf(p.x)
			cactus(p, rng.randf_range(1.6,3.5))
		for i in range(25):
			asset("rock_07", Vector3(rng.randf_range(-24,24),-0.1,rng.randf_range(-24,24)),rng.randf_range(0.2,0.55))

func cactus(point: Vector3, height: float) -> void:
	var plant := Node3D.new()
	plant.position = point
	plant.rotation.y = rng.randf_range(0,TAU)
	add_child(plant)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("536f42")
	m.roughness = 0.9
	for data in [[Vector3(0,height/2,0),height,0.22],[Vector3(-0.55,height*0.65,0),height*0.42,0.15],[Vector3(0.6,height*0.8,0),height*0.38,0.14]]:
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = data[2]; capsule.height = data[1]; capsule.radial_segments = 16
		mesh.mesh = capsule; mesh.material_override = m; mesh.position = data[0]; plant.add_child(mesh)
		# Longitudinal ribs catch the sidelight.
		for rib in range(8):
			var line := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.018; cylinder.bottom_radius = 0.018; cylinder.height = float(data[1])*0.78; cylinder.radial_segments = 4
			line.mesh = cylinder; line.material_override = m
			line.position = data[0] + Vector3(cos(rib*TAU/8)*float(data[2]),0,sin(rib*TAU/8)*float(data[2]))
			plant.add_child(line)
	for side in [-1,1]:
		var link := MeshInstance3D.new()
		var capsule := CapsuleMesh.new(); capsule.radius = 0.16; capsule.height = 0.7
		link.mesh = capsule; link.material_override = m; link.rotation.z = PI/2
		link.position = Vector3(side*0.3,height*(0.47 if side < 0 else 0.64),0); plant.add_child(link)

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(animals.size()):
		var angle := elapsed * 0.045 + i * TAU / 3
		var p := Vector3(cos(angle)*20, 0.02, sin(angle)*20)
		animals[i].position = p
		animals[i].rotation.y = -angle
