extends RefCounted
## Programmatic UI QA fixture, not production content or unlock progression.
static func config()->Dictionary:
	var result:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/validation-01.json"))
	result.content_version="qa-p3-ui"
	result.width=18;result.height=1;result.grid=["RRRBBBYYYGGGPPPWWW"]
	result.palette={"R":"red","B":"blue","Y":"yellow","G":"green","P":"purple","W":"white"}
	result.columns=[];result.armors=[];result.tools=[]
	var colors:Array[String]=["red","blue","yellow","green","purple","white"]
	for i in range(5):result.columns.append({"id":"qa-column-%d"%i,"teams":[{"id":"qa-"+colors[i],"color":colors[i],"quota":3}]})
	result.columns[0].teams.append({"id":"qa-white","color":"white","quota":3})
	for color in colors:result.armors.append({"id":"qa-armor-"+color,"color":color,"demand":3})
	for id in ["extra_slot","shuffle","recall","scout"]:result.tools.append({"id":id,"unlock_level":1,"uses_per_level":1})
	result.parameters={"dispatch_interval_sec":.1,"transport_speed_cells_sec":10.0,"max_inflight_ants":20,"cannon_cooldown_sec":.5,"projectile_flight_sec":.2}
	result.dragon={"route_length":100.0,"speed_units_sec":1.0,"initial_position":0.0,"knockback_distance":0.0,"max_knockback_distance":0.0}
	return result
