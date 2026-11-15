extends Control

var item := ""

func _draw() -> void:
	var cyan := Color("d5b493")
	var gold := Color("ffc76d")
	var pale := Color("eee4d7")
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color("292e36"), true)
	draw_arc(size * 0.5, 28, 0, TAU, 32, Color("a47e5f"), 2.0, true)
	var center := size * 0.5
	if item in ["Pulse Rifle", "Scatter Blaster", "Longshot"]:
		var barrel_end := 18.0 if item == "Scatter Blaster" else 35.0
		var barrel_thickness := 12.0 if item == "Scatter Blaster" else 8.0
		var points := PackedVector2Array([Vector2(-36, -barrel_thickness), Vector2(barrel_end - 8, -barrel_thickness), Vector2(barrel_end, -4), Vector2(barrel_end, 2), Vector2(7, 2), Vector2(3, 14), Vector2(-8, 14), Vector2(-7, 3), Vector2(-36, 3)])
		for i in range(points.size()): points[i] += center
		draw_colored_polygon(points, pale)
		draw_line(center + Vector2(-25, -4), center + Vector2(barrel_end - 8, -4), cyan, 3, true)
		if item == "Longshot":
			draw_rect(Rect2(center + Vector2(-5, -17), Vector2(22, 5)), gold, true)
		elif item == "Scatter Blaster":
			draw_line(center + Vector2(-24, 0), center + Vector2(11, 0), gold, 2, true)
	elif item == "Kinetic Shield":
		var points := PackedVector2Array([center + Vector2(0,-29), center + Vector2(23,-19), center + Vector2(20,8), center + Vector2(0,29), center + Vector2(-20,8), center + Vector2(-23,-19)])
		draw_colored_polygon(points, Color("3b91bd"))
		draw_polyline(points + PackedVector2Array([points[0]]), cyan, 3, true)
	elif item == "Armor Plate":
		draw_rect(Rect2(center + Vector2(-20,-23), Vector2(40,46)), Color("64899a"), true)
		draw_line(center + Vector2(-15,-7), center + Vector2(15,-7), cyan, 3, true)
		draw_line(center + Vector2(-15,3), center + Vector2(15,3), cyan, 3, true)
	elif item == "Tactical Headgear":
		draw_circle(center, 22, Color("547886"), true, -1, true)
		draw_rect(Rect2(center + Vector2(-20,-6), Vector2(40,12)), cyan, true)
	elif item == "Super Dash":
		var points := PackedVector2Array([center + Vector2(7,-32), center + Vector2(-16,3), center + Vector2(-2,3), center + Vector2(-8,32), center + Vector2(19,-7), center + Vector2(5,-7)])
		draw_colored_polygon(points, gold)
