extends RefCounted
## Segmented-serpent schema has a separate catalog/profile from legacy single-dragon.
const PAGE_SIZE := 10
const VALIDATION_IDS := ["serpent-01", "serpent-02", "serpent-03", "serpent-04", "serpent-05", "serpent-06", "serpent-07", "serpent-08"]
static func level_ids(campaign_drafts:bool)->Array[String]:
	var result:Array[String]=[]
	if campaign_drafts:
		# The 30-level scope is retained, not represented by old armor data.
		for number in range(1,31):result.append("serpent-campaign-%02d"%number)
	else:result.assign(VALIDATION_IDS)
	return result
static func level_path(number:int,campaign_drafts:bool)->String:
	if number<1 or number>(30 if campaign_drafts else VALIDATION_IDS.size()):return ""
	return ("res://data/serpent-campaign/serpent-campaign-%02d.json" if campaign_drafts else "res://data/serpent-levels/serpent-%02d.json")%number
static func profile_path(root:String,campaign_drafts:bool)->String:
	if root.is_empty():root="user://ant-rescue"
	var current:=root.path_join("serpent-click-v1")
	return current.path_join("campaign-drafts") if campaign_drafts else current
static func check_identity(config:Dictionary,number:int,campaign_drafts:bool)->Dictionary:
	var ids:=level_ids(campaign_drafts)
	if number<1 or number>ids.size() or config.get("level_id","")!=ids[number-1]:return {"ok":false,"reason":"level_catalog_identity_mismatch"}
	if config.get("schema_version",0)!=3:return {"ok":false,"reason":"serpent_schema_required"}
	if str(config.get("content_version","")).strip_edges().is_empty():return {"ok":false,"reason":"content_version_required"}
	if campaign_drafts and config.get("content_kind","")!="authoring_draft":return {"ok":false,"reason":"serpent_campaign_not_authored"}
	return {"ok":true,"config":config}
