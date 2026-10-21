extends RefCounted
## One finite presentation curve. Rule units map to baked arc length, never modulo.
var curve:=Curve2D.new()
var goal_s:=1.0
var baked_length:=0.0
func configure(knots:Array,rule_goal:float)->void:
	curve.clear_points();curve.bake_interval=2.0;goal_s=maxf(.001,rule_goal)
	for knot in knots:
		var point:Vector2=knot.position
		curve.add_point(point,knot.get("in",Vector2.ZERO),knot.get("out",Vector2.ZERO))
	baked_length=curve.get_baked_length()
func point_at(s:float)->Vector2:
	if baked_length<=0:return Vector2.ZERO
	return curve.sample_baked(clampf(s/goal_s,0,1)*baked_length,true)
func tangent_at(s:float)->Vector2:
	if baked_length<=0:return Vector2.RIGHT
	var offset:=clampf(s/goal_s,0,1)*baked_length
	return curve.sample_baked_with_rotation(offset,true).x.normalized()
func points()->PackedVector2Array:return curve.get_baked_points()
