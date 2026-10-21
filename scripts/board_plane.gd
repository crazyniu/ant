extends RefCounted
## Single near-orthographic ground projection. Rules retain integer logical cells.
const TOP_LEFT:=Vector2(215,365)
const TOP_RIGHT:=Vector2(720,365)
const BOTTOM_LEFT:=Vector2(205,850)
const BOTTOM_RIGHT:=Vector2(735,850)
var columns:=16
var rows:=16
func _init(width:int=16,height:int=16)->void:columns=width;rows=height
func project(cell:Vector2)->Vector2:
	var v:float=cell.y/float(rows)
	# Fit the grid to the ground envelope while keeping rounded-square bead
	# footprints near square, rather than stretching a sparse 10x8 map vertically.
	var fitted_height:=minf(BOTTOM_LEFT.y-TOP_LEFT.y,515.0/float(columns)*float(rows)*.93)
	var top_left:=Vector2(TOP_LEFT.x,BOTTOM_LEFT.y-fitted_height)
	var top_right:=Vector2(TOP_RIGHT.x,BOTTOM_RIGHT.y-fitted_height)
	var left:=top_left.lerp(BOTTOM_LEFT,v)
	var right:=top_right.lerp(BOTTOM_RIGHT,v)
	return left.lerp(right,cell.x/float(columns))
func center(x:float,y:float)->Vector2:return project(Vector2(x+.5,y+.5))
func footprint(x:float,y:float)->Vector2:
	var p:=project(Vector2(x,y))
	return Vector2(project(Vector2(x+1,y)).x-p.x,project(Vector2(x,y+1)).y-p.y)
func depth_scale(y:float)->float:return lerpf(.88,1.0,clampf(y/float(rows),0.0,1.0))
