shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 tint_region = vec4(0.0,0.0,1.0,1.0);
uniform bool is_dragon = false;
uniform bool tint_all = false;
uniform float collapse = 0.0;
uniform vec4 dragon_region = vec4(0.0143229167,0.1416015625,0.46484375,0.46875);
varying vec4 item_modulate;
void vertex(){
	item_modulate=COLOR;
	if(is_dragon){
		vec2 p=(UV-dragon_region.xy)/dragon_region.zw;
		// Forward deformation on the bounded 2D mesh, never inverse sampling.
		// Plant paws while lowering hips, bowing neck and folding wing tips by
		// distinct amounts. The derivative stays monotone, preventing folds.
		float planted=max(0.0,0.97-p.y);
		float head=smoothstep(0.54,0.74,p.x)*(1.0-smoothstep(0.55,0.97,p.y));
		float wing=(1.0-smoothstep(0.47,0.66,p.x))*(1.0-smoothstep(0.35,0.90,p.y));
		vec2 shift=vec2(0.018*head-0.020*wing,0.22*planted+0.075*head+0.080*wing);
		VERTEX+=shift*vec2(394.0,203.0)*collapse;
	}
}
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	float within=step(tint_region.x,UV.x)*step(tint_region.y,UV.y)*step(UV.x,tint_region.z)*step(UV.y,tint_region.w);
	float mask=smoothstep(0.08,0.3,c.r-max(c.g*1.2,c.b*1.2))*within;
	float shade=max(c.r,max(c.g,c.b));
	vec3 painted=mix(tint.rgb*shade,vec3(shade),min(c.g,c.b)*0.35);
	if(tint_all){
		float neutral=dot(c.rgb,vec3(0.299,0.587,0.114));
		painted=mix(tint.rgb*(0.40+0.60*neutral),vec3(neutral),smoothstep(0.80,0.99,neutral)*0.22);
		mask=within;
	}
	COLOR=vec4(mix(c.rgb,painted,mask),c.a)*item_modulate;
}
