extends SceneTree
func _initialize()->void:
	var BoardPlaneScript=load("res://scripts/board_plane.gd")
	for dims in [Vector2i(16,16),Vector2i(35,31),Vector2i(18,18)]:
		var p=BoardPlaneScript.new(dims.x,dims.y)
		assert(p.project(Vector2.ZERO)==p.TOP_LEFT)
		assert(p.project(Vector2(dims.x,0))==p.TOP_RIGHT)
		assert(p.project(Vector2(0,dims.y))==p.BOTTOM_LEFT)
		assert(p.project(Vector2(dims))==p.BOTTOM_RIGHT)
		for y in range(dims.y):
			for x in range(dims.x):
				var c:Vector2=p.center(x,y);var d:Vector2=p.footprint(x,y)
				assert(c.x>130 and c.x<810 and c.y>350 and c.y<890)
				assert(d.x>0 and d.y>0)
				if x+1<dims.x:assert(p.center(x+1,y).x>c.x)
				if y+1<dims.y:assert(p.center(x,y+1).y>c.y)
	print("BOARD_PLANE_PASS: corners, monotonic grid, independent dimensions and common actor/FX centers")
	quit()
