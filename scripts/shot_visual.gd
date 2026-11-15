extends Node3D
## Short-lived visual tracer; raycasts remain authoritative for damage.
var origin := Vector3.ZERO
var target := Vector3.ZERO
var age := 0.0
var duration := 0.2
var distance := 0.0
var tint := Color("70dcff")
var impact := true
var impact_normal := Vector3.UP
var streak: Node3D

static func glow(color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func beam(parent: Node3D, radius: float, length: float, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius * 0.25
	shape.bottom_radius = radius
	shape.height = length
	shape.radial_segments = 8
	visual.mesh = shape
	visual.rotation.x = PI / 2
	visual.position.z = length * 0.5
	visual.material_override = glow(color, alpha)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	return visual

func setup(from: Vector3, to: Vector3, color: Color, did_hit: bool, normal: Vector3) -> void:
	origin = from
	target = to
	tint = color
	impact = did_hit
	impact_normal = normal
	distance = from.distance_to(to)
	global_position = from
	if distance < 0.001:
		queue_free()
		return
	look_at(to, Vector3.RIGHT if absf((to-from).normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP)
	duration = clampf(distance / 160.0, 0.055, 0.42)
	streak = Node3D.new()
	add_child(streak)
	beam(streak, 0.025, 0.9, Color("fff4d6"))
	beam(streak, 0.055, 2.5, tint, 0.55)
	beam(streak, 0.095, 4.2, tint, 0.12)
	streak.scale.z = 0.01
	add_to_group("shot_effects")

func _process(delta: float) -> void:
	if not is_instance_valid(streak): return
	age += delta
	var fraction := minf(age / duration, 1.0)
	global_position = origin.lerp(target, fraction)
	streak.scale.z = minf(1.0, distance * fraction / 4.2)
	if fraction >= 1.0:
		if impact and is_instance_valid(get_parent()): get_parent().spawn_impact(target, tint, impact_normal)
		queue_free()
