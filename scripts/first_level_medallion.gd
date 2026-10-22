extends Control
## Code-native live HUD, not a painted fake control or a new gameplay ability.
var kind:="pause"
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw()->void:
	var center:=size*.5
	if kind=="gear_only":
		var points:=PackedVector2Array()
		for i in 48:
			var radius:=23.0 if i%6 in [0,1,4,5] else 18.0
			points.append(center+Vector2.from_angle(float(i)*TAU/48)*radius)
		draw_colored_polygon(points,Color("ffde91"));draw_circle(center,10,Color("654324"));return
	draw_circle(center+Vector2(0,3),43,Color("35210f"))
	draw_circle(center,42,Color("d59a45"))
	draw_circle(center,38,Color("ffe0a1"))
	draw_circle(center,34,Color("654324"))
	draw_arc(center,35,PI,TAU,48,Color("ba8647"),3,true)
	if kind=="pause":
		for x in [-14,4]:
			draw_style_box(_bar(),Rect2(center+Vector2(x,-18),Vector2(10,36)))
	else:
		var points:=PackedVector2Array()
		for i in 48:
			var radius:=23.0 if i%6 in [0,1,4,5] else 18.0
			points.append(center+Vector2.from_angle(float(i)*TAU/48)*radius)
		draw_colored_polygon(points,Color("ffde91"));draw_circle(center,10,Color("654324"))
func _bar()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("ffe4a1");style.corner_radius_top_left=3;style.corner_radius_top_right=3;style.corner_radius_bottom_left=3;style.corner_radius_bottom_right=3;return style
