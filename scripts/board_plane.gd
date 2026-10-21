extends RefCounted
## Single near-orthographic ground projection. Rules retain integer logical cells.
const TOP_LEFT:=Vector2(215,365)
const TOP_RIGHT:=Vector2(720,365)
const BOTTOM_LEFT:=Vector2(205,850)
const BOTTOM_RIGHT:=Vector2(735,850)
var columns:=16
var rows:=16
var top_left_corner:=TOP_LEFT
var top_right_corner:=TOP_RIGHT
var bottom_left_corner:=BOTTOM_LEFT
var bottom_right_corner:=BOTTOM_RIGHT
var cell_width_basis:=515.0
var depth_ratio:=.93
var entrance_cell:=Vector2.ZERO
var gateway:=Vector2(467,940)
func _init(width:int=16,height:int=16,layout:Dictionary={},entrance:Array=[])->void:
	columns=width;rows=height;entrance_cell=Vector2(width/2,height)
	if entrance.size()==2:entrance_cell=Vector2(entrance[0],entrance[1])
	var ground:Dictionary=layout.get("board_plane",{})
	for key in ["top_left","top_right","bottom_left","bottom_right"]:
		if ground.has(key):set(key+"_corner",Vector2(ground[key][0],ground[key][1]))
	cell_width_basis=float(ground.get("cell_width_basis",515.0));depth_ratio=float(ground.get("depth_ratio",.93))
	if layout.has("nest"):gateway=Vector2(layout.nest.gateway[0],layout.nest.gateway[1])
func project(cell:Vector2)->Vector2:
	var v:float=cell.y/float(rows)
	# Fit the grid to the ground envelope while keeping rounded-square bead
	# footprints near square, rather than stretching a sparse 10x8 map vertically.
	var fitted_height:=minf(bottom_left_corner.y-top_left_corner.y,cell_width_basis/float(columns)*float(rows)*depth_ratio)
	var top_left:=Vector2(top_left_corner.x,bottom_left_corner.y-fitted_height)
	var top_right:=Vector2(top_right_corner.x,bottom_right_corner.y-fitted_height)
	var left:=top_left.lerp(bottom_left_corner,v)
	var right:=top_right.lerp(bottom_right_corner,v)
	return left.lerp(right,cell.x/float(columns))
func center(x:float,y:float)->Vector2:return project(Vector2(x+.5,y+.5))
func footprint(x:float,y:float)->Vector2:
	var p:=project(Vector2(x,y))
	return Vector2(project(Vector2(x+1,y)).x-p.x,project(Vector2(x,y+1)).y-p.y)
func depth_scale(y:float)->float:return lerpf(.88,1.0,clampf(y/float(rows),0.0,1.0))
