shader_type canvas_item;
render_mode unshaded;
uniform vec4 atlas_rect=vec4(0.0,0.0,1.0,1.0);
uniform vec2 source_size=vec2(1040.0,833.0);
// Only the two raised forelegs articulate. Four ground contacts and the head/
// abdomen stay planted; no whole-ant sliding or stretched 70px reach.
uniform vec4 arm_0=vec4(607.0,410.0,851.0,392.0);
uniform vec4 arm_1=vec4(616.0,501.0,937.0,493.0);
uniform vec2 push=vec2(0.0);
varying vec4 item_modulate;
void vertex(){ item_modulate=COLOR; }
float weight(vec2 p,vec4 limb){
    vec2 v=limb.zw-limb.xy;
    float t=clamp(dot(p-limb.xy,v)/max(dot(v,v),1.0),0.0,1.0);
    return (1.0-smoothstep(17.0,35.0,length(p-limb.xy-t*v)))*smoothstep(0.0,.75,t);
}
vec2 offset(vec2 p){return push*max(weight(p,arm_0),weight(p,arm_1));}
void fragment(){
    vec2 p=(UV-atlas_rect.xy)/atlas_rect.zw*source_size;
    vec2 q=p-offset(p);q=p-offset(q);
    vec2 uv=q/source_size;
    float inside=step(0.0,uv.x)*step(0.0,uv.y)*step(uv.x,1.0)*step(uv.y,1.0);
    vec2 atlas_uv=clamp(atlas_rect.xy+uv*atlas_rect.zw,atlas_rect.xy+TEXTURE_PIXEL_SIZE*.5,atlas_rect.xy+atlas_rect.zw-TEXTURE_PIXEL_SIZE*.5);
    COLOR=texture(TEXTURE,atlas_uv)*item_modulate;
    COLOR.a*=inside;
}
