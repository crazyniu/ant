extends Control
class_name RescueBead
## Shared generated material; every bead is an independently positioned live node.
static var textures:Dictionary={}
var color_id:="blue"
var edge:=19.0
var footprint_height:=-1.0
func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if footprint_height<0:footprint_height=edge+3
	custom_minimum_size=Vector2(edge,footprint_height)
	if not textures.has(color_id):
		var regions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/fusion/bead-regions.json"))
		var r:Array=regions[color_id];var tex:=AtlasTexture.new();tex.atlas=load("res://assets/ui/fusion/beads.png");tex.region=Rect2(r[0],r[1],r[2],r[3]);tex.filter_clip=true;textures[color_id]=tex
func _draw()->void:
	if textures.has(color_id):draw_texture_rect(textures[color_id],Rect2(0,0,edge,footprint_height),false)
