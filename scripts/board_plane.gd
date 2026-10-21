extends RefCounted
## Single near-orthographic ground projection. Rules retain integer logical cells.
const TOP_LEFT:=Vector2(175,350)
const TOP_RIGHT:=Vector2(765,350)
const BOTTOM_LEFT:=Vector2(130,890)
const BOTTOM_RIGHT:=Vector2(810,890)
var columns:=16
var rows:=16
func _init(width:int=16,height:int=16)->void:columns=width;rows=height
func project(cell:Vector2)->Vector2:
	var v:float=cell.y/float(rows)
	var left:=TOP_LEFT.lerp(BOTTOM_LEFT,v)
	var right:=TOP_RIGHT.lerp(BOTTOM_RIGHT,v)
	return left.lerp(right,cell.x/float(columns))
func center(x:float,y:float)->Vector2:return project(Vector2(x+.5,y+.5))
func footprint(x:float,y:float)->Vector2:
	var p:=project(Vector2(x,y))
	return Vector2(project(Vector2(x+1,y)).x-p.x,project(Vector2(x,y+1)).y-p.y)
func depth_scale(y:float)->float:return lerpf(.88,1.0,clampf(y/float(rows),0.0,1.0))
