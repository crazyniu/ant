shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0);
void fragment(){
	vec4 c=texture(TEXTURE,UV);
	float mask=smoothstep(0.035,0.19,c.b-max(c.r,c.g));
	float value=max(c.r,max(c.g,c.b));
	vec3 recolored=tint.rgb/max(max(tint.r,tint.g),tint.b)*value;
	recolored=mix(recolored,vec3(value),smoothstep(.62,.98,min(c.r,c.g)));
	COLOR=vec4(mix(c.rgb,recolored,mask),c.a)*COLOR;
}
