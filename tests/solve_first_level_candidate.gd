extends SceneTree
const Rules=preload("res://scripts/rescue_rules.gd")
func _initialize()->void:
	var path:="res://data/serpent-levels/serpent-01.json"
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var rules:=Rules.new();assert(rules.load_level(config))
	var inputs:Array=[];var rejected:Array=[];var next_click:=0
	while rules.time_us<145000000 and rules.status in ["ready","running"]:
		if rules.time_us>=next_click and rules.tasks.size()<4:
			var needed:Dictionary={}
			for segment in rules.segments:
				if int(segment.hp)>0:needed[segment.color]=int(needed.get(segment.color,0))+int(segment.hp)
			rules.reachable_cell_ids()
			var routes:Dictionary=rules.get("_routes")
			var best:="";var score:=INF
			for cell_id in routes:
				if rules.reservations.has(cell_id):continue
				var cell:Dictionary=rules.board[cell_id];var color:String=cell.color
				var route:Dictionary=routes[cell_id]
				var owed:=int(needed.get(color,0))-int(rules.inventory.get(color,0))
				for task in rules.tasks.values():
					if task.color==color:owed-=1
				var cost:=float(route.path.size()) + (0.0 if owed>0 else 30.0)
				# When remaining colors are buried, open the center of the actual
				# flower instead of dispatching meaningless outer purple stock.
				if owed<=0:cost+=absf(float(cell.x)-7.5)*2.0+float(14-cell.y)*.35
				if cost<score:score=cost;best=color
			if not best.is_empty():
				var result:Dictionary=rules.click_color(best)
				if result.ok:inputs.append({"at_sec":float(rules.time_us)/1000000.0,"color":best})
				else:rejected.append(result)
				next_click=rules.time_us+2000000+(1200000 if inputs.size()%5==0 else 0)
		rules.update_us(50000)
	var result:Dictionary={"status":rules.status,"time_sec":float(rules.time_us)/1000000.0,"inputs":inputs,"remaining":rules.board.size(),"rejected":rejected,"conservation":rules.conservation_errors(),"scope":"Computed feasible input schedule only, two-second input gaps plus deliberate 1.2s think pauses. Not human playtest."}
	print(JSON.stringify(result))
	var file:=FileAccess.open("res://reports/first-level/computed-solution.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"\t"));file.close()
	if rules.status=="victory":
		config.solution={"kind":"timed_single_click_no_tool_core_replay","minimum_input_gap_sec":2.0,"inputs":inputs}
		file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(config,"\t"));file.close()
	quit(0 if rules.status=="victory" and rejected.is_empty() and rules.conservation_errors().is_empty() else 1)
