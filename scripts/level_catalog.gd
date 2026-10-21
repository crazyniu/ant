extends RefCounted
## Explicit source registry. Draft opt-in never replaces the validation catalog.
const PAGE_SIZE := 10
const VALIDATION_IDS := ["validation-01", "validation-02", "validation-03"]

static func level_ids(campaign_drafts:bool)->Array[String]:
	var result:Array[String]=[]
	if campaign_drafts:
		for number in range(1,31):result.append("campaign-%02d"%number)
	else:result.assign(VALIDATION_IDS)
	return result

static func level_path(number:int,campaign_drafts:bool)->String:
	if number<1 or number>(30 if campaign_drafts else 3):return ""
	return ("res://data/campaign-drafts/campaign-%02d.json" if campaign_drafts else "res://data/levels/validation-%02d.json")%number

static func profile_path(root:String,campaign_drafts:bool)->String:
	if root.is_empty():root="user://ant-rescue"
	# Even an environment override is a parent, not permission to mix catalogs.
	return root.path_join("campaign-drafts") if campaign_drafts else root

static func check_identity(config:Dictionary,number:int,campaign_drafts:bool)->Dictionary:
	var ids:=level_ids(campaign_drafts)
	if number<1 or number>ids.size() or config.get("level_id","")!=ids[number-1]:
		return {"ok":false,"reason":"level_catalog_identity_mismatch"}
	if campaign_drafts and (config.get("content_kind","")!="authoring_draft" or config.get("campaign_draft_number",0)!=number or config.get("level_number",0)!=number):
		return {"ok":false,"reason":"campaign_draft_identity_mismatch"}
	return {"ok":true,"config":config}
