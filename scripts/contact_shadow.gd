extends Control
var radius:=Vector2(18,6)
var strength:=.16
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw()->void:
	for i in range(6,0,-1):
		var k:=float(i)/6.0
		draw_set_transform(Vector2.ZERO,0,Vector2(radius.x*k,radius.y*k))
		draw_circle(Vector2.ZERO,1,Color(.23,.13,.045,strength/6.0))
	draw_set_transform(Vector2.ZERO)
