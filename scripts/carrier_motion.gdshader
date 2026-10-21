shader_type canvas_item;
render_mode unshaded;

// Normalized atlas region, never the entire six-ant texture. The art regions
// have only 7..10 transparent edge pixels, so samples outside this region must
// become transparent rather than pulling a neighboring ant into the outline.
uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);
// x/z = opposing horizontal foot strides; y/w = nonnegative swing-foot lift.
uniform vec4 gait = vec4(0.0);
// body drop, thorax sway, antenna sway, pickup crouch. All in local art UVs.
uniform vec4 posture = vec4(0.0);
varying vec4 item_modulate;

void vertex() {
	item_modulate = COLOR;
}

float capsule(vec2 p, vec2 a, vec2 b, float inner, float outer) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return 1.0 - smoothstep(inner, outer, length(p - a - ab * t));
}

vec2 articulation(vec2 p) {
	// Coordinates measured on the actual RGBA ant crop (394x347 for red).
	// Front/rear near legs form one visible tripod side; the smaller far legs
	// oppose them. Feathering at the hip avoids a pasted-on detached-limb look.
	float rear = capsule(p, vec2(0.405, 0.730), vec2(0.285, 0.935), 0.052, 0.100);
	rear *= smoothstep(0.710, 0.875, p.y);
	float front = capsule(p, vec2(0.640, 0.735), vec2(0.730, 0.935), 0.055, 0.105);
	front *= smoothstep(0.690, 0.880, p.y);
	float far_middle = capsule(p, vec2(0.525, 0.714), vec2(0.530, 0.785), 0.040, 0.072);
	far_middle *= smoothstep(0.710, 0.780, p.y);
	float far_front = capsule(p, vec2(0.750, 0.690), vec2(0.805, 0.805), 0.048, 0.087);
	far_front *= smoothstep(0.680, 0.790, p.y);
	float near_pair = max(rear, front);
	float far_pair = max(far_middle, far_front) * (1.0 - near_pair);
	vec2 shift = vec2(gait.x, -gait.y) * near_pair;
	shift += vec2(gait.z, -gait.w * 0.80) * far_pair;

	// Translate the body/antennae locally, tapering to zero before the contact
	// line. A crouch bends/compresses the legs, not the entire actor's transform.
	float body = 1.0 - smoothstep(0.610, 0.950, p.y);
	shift.y += posture.x * body;
	shift.x += posture.y * body;
	float antenna = (1.0 - smoothstep(0.080, 0.295, p.y)) * smoothstep(0.480, 0.620, p.x);
	shift.x += posture.z * antenna;
	// Small head-leading pickup gesture with the abdomen and ground unchanged.
	shift.x += posture.w * 0.012 * smoothstep(0.55, 0.78, p.x) * body;
	return shift;
}

void fragment() {
	vec2 p = (UV - atlas_rect.xy) / atlas_rect.zw;
	// Two bounded inverse-warp iterations retain the original painted anatomy
	// while the limb silhouettes move. No extra sprite, draw call, or texture.
	vec2 source = p - articulation(p);
	source = p - articulation(source);
	float inside = step(0.0, source.x) * step(0.0, source.y)
		* step(source.x, 1.0) * step(source.y, 1.0);
	vec2 atlas_uv = atlas_rect.xy + source * atlas_rect.zw;
	vec2 half_pixel = TEXTURE_PIXEL_SIZE * 0.5;
	atlas_uv = clamp(atlas_uv, atlas_rect.xy + half_pixel,
		atlas_rect.xy + atlas_rect.zw - half_pixel);
	COLOR = texture(TEXTURE, atlas_uv) * item_modulate;
	COLOR.a *= inside;
}
