extends Node3D

var kind := "health"
var human: CharacterBody3D
var visual: Node3D
var unavailable := 0.0
var time := 0.0

func setup(type: String, player: CharacterBody3D) -> void:
	kind = type
	human = player
	visual = Node3D.new()
	visual.position.y = 0.8
	add_child(visual)
	var color := Color("55f3b5") if kind == "health" else (Color("5baeff") if kind == "shield" else Color("ffd26b"))
	var orb := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	orb.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	orb.material_override = mat
	visual.add_child(orb)
	var sign := Label3D.new()
	sign.text = "+" if kind == "health" else ("S" if kind == "shield" else "Q")
	sign.font_size = 56
	sign.position = Vector3(0, 0.55, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = color
	visual.add_child(sign)

func _process(delta: float) -> void:
	if not is_instance_valid(human):
		return
	if unavailable > 0:
		unavailable -= delta
		if unavailable <= 0:
			visual.visible = true
		return
	time += delta
	visual.rotation.y += delta
	visual.position.y = 0.85 + sin(time * 2.5) * 0.15
	if global_position.distance_to(human.global_position) < 1.4 and human.collect_powerup(kind):
		unavailable = 15.0
		visual.visible = false
