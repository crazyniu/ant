extends SceneTree
const Rules=preload("res://scripts/rescue_rules.gd")
var failures:Array=[]
var results:Array=[]
var checks:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func solve(config:Dictionary,loadout:Dictionary)->Dictionary:
	var r:=Rules.new();check(r.load_level(config),"load");check(r.set_ant_loadout(loadout),"freeze loadout")
	var input:int=0;var max_carriers:=0;var first_delivery:=-1
	while r.status in ["ready","running"] and r.time_us<60000000:
		while input<config.solution.inputs.size() and r.time_us>=Rules.seconds_to_us(float(config.solution.inputs[input].at_sec)):
			check(r.click_color(str(config.solution.inputs[input].color)).ok,"authored click accepted");input+=1
		r.update_us(10000);max_carriers=maxi(max_carriers,r.tasks.size())
		for event in r.drain_events():
			if event.type=="bead_delivered" and first_delivery<0:first_delivery=int(event.time_us)
	check(r.status=="victory","worker and growth both win")
	check(max_carriers<=4,"same capacity")
	check(r.conservation_errors().is_empty(),"same resource ledger")
	check(not r.set_ant_loadout({"ant_type":"worker","level":1,"speed_multiplier":1.}),"cannot change equipment midrun")
	return {"time_us":r.terminal_time_us,"first_delivery_us":first_delivery,"capacity":max_carriers,"head_speed":config.serpent.speed_units_sec,"remaining_beads":r.board.size()}
func run()->void:
	for number in range(1,4):
		var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-%02d.json"%number))
		var baseline:=solve(config,{"ant_type":"worker","level":1,"speed_multiplier":1.})
		var grown:=solve(config,{"ant_type":"swift","level":4,"speed_multiplier":1.38})
		check(grown.first_delivery_us<baseline.first_delivery_us,"growth delivers sooner")
		check(grown.time_us<baseline.time_us,"growth shortens actual last hit")
		check(grown.head_speed==baseline.head_speed,"enemy is not scaled to growth")
		results.append({"level":number,"baseline":baseline,"swift_level4":grown})
	var report:Dictionary={"checks":checks,"failures":failures,"same_authored_inputs":true,"results":results,"scope":"three current slices only; not human/economy balance or old 30 campaign acceptance"}
	var f:=FileAccess.open("res://reports/rules/ant-growth-integration.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("ANT_GROWTH_INTEGRATION ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
