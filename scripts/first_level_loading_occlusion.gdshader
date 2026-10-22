shader_type canvas_item;
render_mode unshaded;
// The incoming ball passes behind the painted cannon, not through its metal.
// The actual rear opening is the only opaque-source region cut away here.
uniform sampler2D cannon_texture : filter_linear;
uniform vec4 cannon_region;
uniform vec2 cannon_size;
uniform vec2 ball_origin;
uniform vec2 ball_scale = vec2(1.0);
uniform float ball_rotation=0.0;
uniform vec2 mouth_0;
uniform vec2 mouth_1;
uniform vec2 mouth_2;
uniform vec2 mouth_3;
uniform vec2 mouth_4;
uniform vec2 mouth_5;
uniform vec2 mouth_6;
uniform vec2 mouth_7;
uniform vec2 mouth_8;
uniform vec2 mouth_9;
varying vec2 cannon_point;
void vertex() {
	vec2 v=VERTEX*ball_scale;
	float c=cos(ball_rotation);float s=sin(ball_rotation);
	cannon_point=ball_origin+vec2(c*v.x-s*v.y,s*v.x+c*v.y);
}
float edge_distance(vec2 a,vec2 b,vec2 p) {
	vec2 v=b-a;vec2 q=p-a;
	return (v.x*q.y-v.y*q.x)/max(length(v),0.001);
}
void fragment() {
	vec2 point=cannon_point/cannon_size;
	float inside=step(0.0,point.x)*step(0.0,point.y)*step(point.x,1.0)*step(point.y,1.0);
	float metal=smoothstep(0.12,0.8,texture(cannon_texture,cannon_region.xy+point*cannon_region.zw).a)*inside;
	// Measured dark-mouth polygon keeps copper sidewalls and front lip.
	float edge=10000.0;
	edge=min(edge,edge_distance(mouth_0,mouth_1,cannon_point));
	edge=min(edge,edge_distance(mouth_1,mouth_2,cannon_point));
	edge=min(edge,edge_distance(mouth_2,mouth_3,cannon_point));
	edge=min(edge,edge_distance(mouth_3,mouth_4,cannon_point));
	edge=min(edge,edge_distance(mouth_4,mouth_5,cannon_point));
	edge=min(edge,edge_distance(mouth_5,mouth_6,cannon_point));
	edge=min(edge,edge_distance(mouth_6,mouth_7,cannon_point));
	edge=min(edge,edge_distance(mouth_7,mouth_8,cannon_point));
	edge=min(edge,edge_distance(mouth_8,mouth_9,cannon_point));
	edge=min(edge,edge_distance(mouth_9,mouth_0,cannon_point));
	float hole=smoothstep(-.25,.5,edge);
	COLOR.a*=max(1.0-metal,hole);
}
