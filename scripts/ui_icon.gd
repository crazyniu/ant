extends Control
class_name RescueIcon
var kind := "pause"
var ink := Color("fff9e8")
var fill := Color("ef3526")
var sculpted_icon: Texture2D

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var paths := {
		"shuffle": '<path d="M19 31H29C44 31 48 69 65 69H78M19 69H29C44 69 48 31 65 31H78"/><path d="M67 20L80 31 67 43M67 57L80 69 67 81"/>',
		"recall": '<path d="M22 42A30 30 0 0 1 76 34L79 43M79 58A30 30 0 0 1 25 66L22 57"/><path d="M80 24L80 44 61 41M20 76L20 56 39 59"/>',
		"hint": '<path d="M34 59C34 50 25 47 25 34A25 25 0 0 1 75 34C75 47 66 50 66 59V66H34Z" fill="url(#g)"/><path d="M37 74H63M40 83H60M45 90H55M50 2V-3M16 14L11 9M84 14L89 9"/>'
	}
	if paths.has(kind):
		var svg: String='<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="-10 -10 120 120"><defs><linearGradient id="g" x2=".2" y2="1"><stop stop-color="#ffffff"/><stop offset="1" stop-color="#ffe8ae"/></linearGradient></defs><g transform="translate(0 3)" fill="none" stroke="#683917" stroke-opacity=".28" stroke-width="10" stroke-linecap="round" stroke-linejoin="round">%s</g><g fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % [paths[kind],"#"+ink.to_html(false),paths[kind]]
		var im:=Image.new();im.load_svg_from_string(svg);sculpted_icon=ImageTexture.create_from_image(im)

func _draw() -> void:
	if sculpted_icon!=null:
		draw_texture_rect(sculpted_icon,Rect2(Vector2.ZERO,size),false)
		return
	var c:=size*0.5
	var r:=minf(size.x,size.y)*0.34
	match kind:
		"play":
			var triangle:=PackedVector2Array([c+Vector2(-r*.6,-r),c+Vector2(r,0),c+Vector2(-r*.6,r)])
			var shadow:=PackedVector2Array();for p in triangle:shadow.append(p+Vector2(0,5))
			draw_colored_polygon(shadow,Color("527323"));draw_colored_polygon(triangle,ink)
			triangle.append(triangle[0]);draw_polyline(triangle,Color("fff6cf"),3,true)
		"levels":
			for row in 3:
				for col in 3:
					var box:=StyleBoxFlat.new();box.bg_color=ink;box.set_corner_radius_all(3)
					box.border_color=Color("fff3c5");box.set_border_width_all(2)
					draw_style_box(box,Rect2(c+Vector2((col-1)*r*.82-r*.3,(row-1)*r*.82-r*.3),Vector2.ONE*r*.6))
		"home":
			var pts:=PackedVector2Array([c+Vector2(-r,r),c+Vector2(-r,-r*.15),c+Vector2(0,-r),c+Vector2(r,-r*.15),c+Vector2(r,r)])
			draw_colored_polygon(pts,ink);pts.append(pts[0]);draw_polyline(pts,Color("fff2c7"),3,true)
			draw_rect(Rect2(c+Vector2(-r*.25,r*.2),Vector2(r*.5,r*.8)),Color("8b572b"))
		"clock":
			draw_arc(c,r,0,TAU,24,ink,3,true)
			draw_line(c,c+Vector2(0,-r*.62),ink,3,true);draw_line(c,c+Vector2(r*.48,r*.18),ink,3,true)
		"check":
			draw_polyline(PackedVector2Array([c+Vector2(-r*.8,0),c+Vector2(-r*.2,r*.6),c+Vector2(r*.85,-r*.65)]),ink,4,true)
		"pause":
			for x in [-0.35,0.35]:
				var s:=StyleBoxFlat.new();s.bg_color=ink;s.set_corner_radius_all(4)
				draw_style_box(s,Rect2(c+Vector2(x*r-4,-r),Vector2(8,r*2)))
		"plus":
			draw_line(c-Vector2(r,0),c+Vector2(r,0),Color("297a30"),16,true)
			draw_line(c-Vector2(0,r),c+Vector2(0,r),Color("297a30"),16,true)
			draw_line(c-Vector2(r,0),c+Vector2(r,0),ink,12,true)
			draw_line(c-Vector2(0,r),c+Vector2(0,r),ink,12,true)
		"shield":
			var pts:=PackedVector2Array([c+Vector2(-r,-r*.7),c+Vector2(-r*.4,-r*.8),c+Vector2(0,-r),c+Vector2(r*.4,-r*.8),c+Vector2(r,-r*.7),c+Vector2(r*.88,r*.45),c+Vector2(0,r*1.1),c+Vector2(-r*.88,r*.45)])
			draw_colored_polygon(pts,fill.darkened(.35));draw_polyline(pts,Color("fff5d6"),4,true)
			var inner:=PackedVector2Array();for p in pts:inner.append(c+(p-c)*.82)
			draw_colored_polygon(inner,fill)
			draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r*.56),c+Vector2(r*.38,0),c+Vector2(0,r*.58),c+Vector2(-r*.38,0)]),ink)
		"hint":
			draw_circle(c-Vector2(0,r*.25),r*.65,ink)
			draw_line(c+Vector2(-r*.28,r*.5),c+Vector2(r*.28,r*.5),ink,8,true)
			draw_line(c+Vector2(-r*.22,r*.78),c+Vector2(r*.22,r*.78),ink,6,true)
			for a in [-2.7,-1.57,-.44]:
				draw_line(c+Vector2(cos(a),sin(a))*r*.9,c+Vector2(cos(a),sin(a))*r*1.13,ink,4,true)
		"recall":
			for a in [0.0,PI]:
				draw_arc(c,r*.83,a+.32,a+2.65,18,ink,9,true)
				var e:=c+Vector2(cos(a+.32),sin(a+.32))*r*.83
				draw_colored_polygon(PackedVector2Array([e+Vector2(-11,-9).rotated(a),e+Vector2(12,-4).rotated(a),e+Vector2(6,14).rotated(a)]),ink)
		"shuffle":
			for f in [-1.0,1.0]:
				var line:=PackedVector2Array([c+Vector2(-r,-r*.62*f),c+Vector2(-r*.45,-r*.62*f),c+Vector2(r*.4,r*.58*f),c+Vector2(r,r*.58*f)])
				draw_polyline(line,ink,8,true)
				draw_colored_polygon(PackedVector2Array([c+Vector2(r-8,r*.58*f-12),c+Vector2(r+8,r*.58*f),c+Vector2(r-8,r*.58*f+12)]),ink)
		"arrow":
			var points:=PackedVector2Array([c+Vector2(-r*.62,-r*.78),c+Vector2(r*.72,0),c+Vector2(-r*.62,r*.78)])
			draw_polyline(points,Color("fff5d6"),11,true)
			draw_polyline(points,ink,7,true)
		"star":
			var points:=PackedVector2Array()
			for i in range(10):
				var a:float=-PI/2+i*PI/5;points.append(c+Vector2(cos(a),sin(a))*r*(1.0 if i%2==0 else .45))
			draw_colored_polygon(points,ink);points.append(points[0]);draw_polyline(points,Color("d48d20"),2,true)
		"barrier":
			# Physical route obstruction, deliberately not an ownership padlock.
			draw_line(c+Vector2(-r*.62,-r*.05),c+Vector2(-r*.8,r),ink,3,true)
			draw_line(c+Vector2(r*.62,-r*.05),c+Vector2(r*.8,r),ink,3,true)
			var board:=Rect2(c+Vector2(-r,-r*.66),Vector2(r*2,r*.72))
			draw_rect(board,ink)
			for x in [-.6,.0,.6]:draw_line(c+Vector2(r*x,-r*.62),c+Vector2(r*(x-.27),0),Color("fff1cc"),2,true)

		"lock":
			draw_arc(c-Vector2(0,r*.25),r*.58,PI,TAU,16,ink,3,true)
			var s:=StyleBoxFlat.new();s.bg_color=ink;s.set_corner_radius_all(2);draw_style_box(s,Rect2(c+Vector2(-r*.73,0),Vector2(r*1.46,r)))
		"music":
			draw_line(c+Vector2(-r*.2,-r*.8),c+Vector2(-r*.2,r*.5),ink,6,true)
			draw_line(c+Vector2(-r*.2,-r*.8),c+Vector2(r*.7,-r*.5),ink,6,true)
			draw_circle(c+Vector2(-r*.5,r*.5),r*.35,ink)
