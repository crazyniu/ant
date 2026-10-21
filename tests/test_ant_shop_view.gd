extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var shop=load("res://scripts/ant_shop_view.gd").new()
	shop.set_data({"points":0,"owned_types":["worker"],"equipped_type":"worker","carry_level":1,"ready":true,"type_multipliers":{"worker":1.,"swift":1.2},"level_multiplier":1.},JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")))
	root.add_child(shop)
	assert(shop.content.get_node("EquipButton_worker").disabled)
	assert(shop.content.get_node("BuyButton_swift").disabled)
	assert(shop.content.get_node("TrainingButton").disabled)
	assert(shop.content.get_node("TrainingButton").size.y>=83.)
	shop.economy.points=500;shop.rebuild()
	assert(not shop.content.get_node("BuyButton_swift").disabled)
	assert(not shop.content.get_node("TrainingButton").disabled)
	shop.queue_free();await process_frame;await process_frame
	print("ANT_SHOP_VIEW_OK");quit()
