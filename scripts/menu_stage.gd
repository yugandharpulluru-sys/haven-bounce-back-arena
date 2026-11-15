extends Node3D
## A single live, matte-lit character stage replaces the layered arena/portrait cutouts.
var hero: Node3D
var companion: Node3D
var camera: Camera3D
var time := 0.0
var hero_kind := "player"

func surface(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic_specular = 0.15
	return m

func block(where: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.position = where
	mesh.material_override = material
	# These large surfaces receive character shadows without casting onto each other.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func build(avatar: int, weapon: String, helmet: bool, variant: int) -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("243034")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c5d2d4")
	settings.ambient_light_energy = 0.42
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = settings
	add_child(env)
	var concrete := surface(Color("3a474b"),1.0)
	block(Vector3(0,-0.08,0),Vector3(20,0.16,18),concrete)
	var wall := surface(Color("354247"))
	block(Vector3(0,2.5,-3.8),Vector3(20,5,0.3),wall)
	for x in [-6,-3,0,3,6]:
		block(Vector3(x,2.5,-3.56),Vector3(0.04,5,0.04),surface(Color("1c282d")))
	# Broad architectural shapes and a single workshop light keep the backdrop quiet.
	block(Vector3(2.0,2.5,-3.47),Vector3(3.0,2.8,0.14),surface(Color("263236")))
	block(Vector3(2.0,3.95,-3.3),Vector3(3.2,0.035,0.08),surface(Color("c2ccb5")))
	for x in range(4):
		block(Vector3(-1.8+x*0.22,0.015,-1.4),Vector3(0.09,0.01,0.8),surface(Color("a6ad80")))
	var key := SpotLight3D.new()
	key.position = Vector3(0.2,4.0,3.3)
	key.light_color = Color("f3f0e9")
	key.light_energy = 3.0
	key.spot_range = 12.0
	key.spot_angle = 62
	key.shadow_enabled = true
	key.shadow_bias = 0.08
	add_child(key)
	key.look_at(Vector3(1.4,0.8,0))
	var rim := OmniLight3D.new()
	rim.position = Vector3(3.3,2.5,-1.5)
	rim.light_color = Color("b2ccd5")
	rim.light_energy = 2.7
	rim.omni_range = 5.0
	add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1.3,1.8,2.7)
	fill.light_energy = 0.55
	fill.omni_range = 4.0
	add_child(fill)
	var prop: Node3D = load("res://assets/quaternius/Prop_Barrel1.gltf").instantiate()
	prop.position = Vector3(2.8,0,-2.4)
	prop.scale = Vector3.ONE*0.6
	add_child(prop)
	var names := ["Enemy_EyeDrone", "Enemy_QuadShell", "Enemy_Trilobite"]
	companion = load("res://assets/quaternius/" + names[variant % 3] + ".gltf").instantiate()
	companion.scale = Vector3.ONE*0.36
	companion.position = Vector3(0.35,0.55 if variant % 3 == 0 else 0.0,-2.5)
	add_child(companion)
	var anims := companion.find_children("*","AnimationPlayer",true,false)
	if not anims.is_empty() and anims[0].has_animation("Idle"): anims[0].play("Idle")
	camera = Camera3D.new()
	camera.position = Vector3(0,1.15,5.4)
	camera.fov = 31
	add_child(camera)
	camera.look_at(Vector3(0,1.07,0))
	camera.current = true
	set_hero("player",avatar,weapon,helmet)

func set_hero(kind: String, avatar: int, weapon: String, helmet: bool) -> Node3D:
	if is_instance_valid(hero):
		remove_child(hero)
		hero.queue_free()
	hero_kind = kind
	if kind == "echo":
		hero = load("res://assets/quaternius/Enemy_EyeDrone.gltf").instantiate()
		hero.position = Vector3(1.5,1.2,0)
		hero.scale = Vector3.ONE*1.0
		add_child(hero)
	else:
		hero = Node3D.new()
		hero.set_script(preload("res://scripts/character_visual.gd"))
		add_child(hero)
		hero.setup(avatar,weapon,helmet)
		hero.preview_idle = true
		hero.position = Vector3(1.45,0,0)
		hero.scale = Vector3.ONE * 1.12
		hero.rotation.y = PI - 0.12
	return hero

func _process(delta: float) -> void:
	time += delta
	if is_instance_valid(hero):
		if hero_kind == "player":
			hero.animate_motion(delta,0.0)
			hero.rotation.y = PI - 0.12 + sin(time*0.3)*0.035
		else:
			hero.rotation.y += delta*0.16
			hero.position.y = 1.2+sin(time)*0.06
	if is_instance_valid(companion): companion.rotation.y += delta*0.10
