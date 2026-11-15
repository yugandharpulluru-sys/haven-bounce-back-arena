extends Node
## One clearance grid per match, shared by all bots. Built after physics sync.
var grid := AStarGrid2D.new()
var ready_for_paths := false
var sync_frames := 2
func build() -> void:
	sync_frames = 2
	set_physics_process(true)
func _physics_process(_delta: float) -> void:
	sync_frames -= 1
	if sync_frames > 0: return
	set_physics_process(false)
	scan_obstacles()
func scan_obstacles() -> void:
	grid.region = Rect2i(-23, -23, 47, 47)
	grid.cell_size = Vector2.ONE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.68
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	var space: PhysicsDirectSpaceState3D = get_parent().get_world_3d().direct_space_state
	for x in range(-23,24):
		for z in range(-23,24):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x,1.0,z))
			for hit in space.intersect_shape(query, 16):
				if hit["collider"] is StaticBody3D:
					grid.set_point_solid(Vector2i(x,z))
					break
	ready_for_paths = true
func nearest(point: Vector3) -> Vector2i:
	var cell := Vector2i(clampi(roundi(point.x),-23,23),clampi(roundi(point.z),-23,23))
	if not grid.is_point_solid(cell): return cell
	for radius in range(1,6):
		for x in range(-radius,radius+1):
			for z in range(-radius,radius+1):
				var candidate := cell + Vector2i(x,z)
				if grid.region.has_point(candidate) and not grid.is_point_solid(candidate): return candidate
	return cell
func route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not ready_for_paths: return result
	var start := nearest(from)
	var goal := nearest(to)
	if grid.is_point_solid(start) or grid.is_point_solid(goal): return result
	for p in grid.get_id_path(start,goal): result.append(Vector3(p.x,0,p.y))
	return result
