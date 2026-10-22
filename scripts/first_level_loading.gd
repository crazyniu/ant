extends RefCounted
## Presentation-only geometry. Rules retain transport, inventory and fire timing.
const OCCLUSION=preload("res://scripts/first_level_loading_occlusion.gdshader")
const OPENING_POLYGON=[Vector2(94.5,158.75),Vector2(110.25,161.25),Vector2(123,168.75),Vector2(129.5,179.25),Vector2(131.5,189),Vector2(126.75,197.5),Vector2(70,194.5),Vector2(67.25,186.25),Vector2(71.5,173.75),Vector2(81.5,163.5)]
const GUNNER_BALL_OFFSET=Vector2(44.94,-32.81)
const GUNNER_SCALE=62.0/966.0
const AUTHORED_RECEIVE_BALL_SIZE=Vector2(33.5,33.5)
static func receiving_grip_offset()->Vector2:
	# The carrier keeps the sphere's bottom on its back. A taller rendering
	# raises its center, so only the receiving hands follow that height change.
	return Vector2(0.0,-(preload("res://scripts/first_level_bead.gd").WORLD_SIZE.y-AUTHORED_RECEIVE_BALL_SIZE.y)*.5)
static func build_gunner(cannon:Control)->Node2D:
	var gunner:=Node2D.new();gunner.name="LoaderAnt";gunner.show_behind_parent=true;cannon.add_child(gunner)
	var shadow:=Control.new();shadow.set_script(preload("res://scripts/contact_shadow.gd"));shadow.name="ContactShadow";shadow.radius=Vector2(19,4.3);shadow.strength=.16;gunner.add_child(shadow)
	var sprite:=TextureRect.new();sprite.name="Ant";sprite.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var texture:=AtlasTexture.new();texture.atlas=load("res://assets/first-level/cannon-loader.png");texture.region=Rect2(185,223,1040,833);texture.filter_clip=true
	sprite.texture=texture;sprite.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;sprite.size=Vector2(1040,833)*GUNNER_SCALE;sprite.position=-Vector2(386,790)*GUNNER_SCALE;gunner.add_child(sprite)
	var material:=ShaderMaterial.new();material.shader=preload("res://scripts/first_level_loader.gdshader")
	material.set_shader_parameter("atlas_rect",Vector4(185.0/1374,223.0/1145,1040.0/1374,833.0/1145))
	sprite.material=material
	return gunner

static func pose_gunner(gunner:Node2D,cannon:Control,receive_center:Vector2,push_world:Vector2)->void:
	# Grounded worker is grouped with the cannon, not bolted to its recoiling
	# metal. Full affine compensation also removes rotation/shear at the feet.
	gunner.transform=cannon.get_transform().affine_inverse()*Transform2D(0.0,receive_center-GUNNER_BALL_OFFSET)
	gunner.get_node("Ant").material.set_shader_parameter("push",push_world/GUNNER_SCALE)
	gunner.get_node("Ant").material.set_shader_parameter("grip_offset",receiving_grip_offset()/GUNNER_SCALE)
static func prepare_ball(ball:Control,cannon:TextureRect,opening:Vector2)->void:
	var material:=ShaderMaterial.new();material.shader=OCCLUSION
	var atlas:=cannon.texture as AtlasTexture
	material.set_shader_parameter("cannon_texture",atlas.atlas)
	material.set_shader_parameter("cannon_region",Vector4(atlas.region.position.x/atlas.atlas.get_width(),atlas.region.position.y/atlas.atlas.get_height(),atlas.region.size.x/atlas.atlas.get_width(),atlas.region.size.y/atlas.atlas.get_height()))
	material.set_shader_parameter("cannon_size",cannon.size)
	for i in OPENING_POLYGON.size():material.set_shader_parameter("mouth_%d"%i,OPENING_POLYGON[i]+opening-Vector2(97,182))
	ball.material=material
static func transfer_center(source:Vector2,target:Vector2,unload_us:int,delivery_us:int,time_us:int)->Vector2:
	var fraction:=clampf(float(time_us-unload_us)/maxf(1.0,float(delivery_us-unload_us)),0.0,1.0)
	if fraction<=0.0:return source
	if fraction>=1.0:return target
	# First .20 of .80 seconds: visible receiving grip, no early inventory.
	# The rest feeds behind the existing brass and into its real opening.
	var progress:=smoothstep(0.0,1.0,clampf((fraction-.25)/.75,0.0,1.0))
	return source.lerp(target,progress)+Vector2(0.0,-sin(progress*PI)*7.0)

static func attach_ball(ball:Control,cannon:Control,center_in_parent:Vector2)->void:
	# The ball is a true cannon child, but recoil stretch must not distort its
	# shared world footprint. Inverse scale cancels only that nonuniform stretch.
	ball.scale=Vector2.ONE/cannon.scale
	ball.position=cannon.get_transform().affine_inverse()*center_in_parent-(ball.size*ball.scale*.5).rotated(ball.rotation)
	if ball.material is ShaderMaterial:
		ball.material.set_shader_parameter("ball_origin",ball.position)
		ball.material.set_shader_parameter("ball_scale",ball.scale)
		ball.material.set_shader_parameter("ball_rotation",ball.rotation)
