shader_type canvas_item;
render_mode unshaded;

uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 source_size = vec2(420.0, 400.0);
uniform vec2 foot_anchor = vec2(210.0, 350.0);
// Per-view measured hip/foot capsules, in original source pixels.
uniform vec4 leg_0;
uniform vec4 leg_1;
uniform vec4 leg_2;
uniform vec4 leg_3;
uniform vec4 leg_groups = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 gait_axis = vec2(1.0, 0.0);
// Opposing foot strides/lifts in original source pixels, never whole-body bob.
uniform vec4 gait = vec4(0.0);
uniform vec2 posture = vec2(0.0);
uniform vec4 tint : source_color = vec4(0.408, 0.847, 0.286, 1.0);
varying vec4 item_modulate;

void vertex() {
	item_modulate = COLOR;
}

float limb_weight(vec2 p, vec4 leg) {
	vec2 segment = leg.zw - leg.xy;
	float along = clamp(dot(p - leg.xy, segment) / max(dot(segment, segment), 1.0), 0.0, 1.0);
	float distance_to_limb = length(p - leg.xy - segment * along);
	// Zero at the hip and feathered beyond the foot: the original limb remains
	// joined, while the padded silhouette can swing without an outline seam.
	return (1.0 - smoothstep(18.0, 38.0, distance_to_limb)) * smoothstep(0.0, 0.72, along);
}

vec2 articulation(vec2 p) {
	vec4 weights = vec4(limb_weight(p, leg_0), limb_weight(p, leg_1),
		limb_weight(p, leg_2), limb_weight(p, leg_3));
	float near_pair = max(max(weights.x * (1.0 - leg_groups.x), weights.y * (1.0 - leg_groups.y)),
		max(weights.z * (1.0 - leg_groups.z), weights.w * (1.0 - leg_groups.w)));
	float far_pair = max(max(weights.x * leg_groups.x, weights.y * leg_groups.y),
		max(weights.z * leg_groups.z, weights.w * leg_groups.w));
	// Bounded blend where painted feet overlap. Never add two full offsets.
	float total = max(1.0, near_pair + far_pair);
	vec2 shift = ((gait_axis * gait.x + vec2(0.0, -gait.y)) * near_pair
		+ (gait_axis * gait.z + vec2(0.0, -gait.w)) * far_pair) / total;
	float hips_y = min(min(leg_0.y, leg_1.y), min(leg_2.y, leg_3.y));
	float feet_y = max(max(leg_0.w, leg_1.w), max(leg_2.w, leg_3.w));
	// A shallow pickup crouch, with no translation of the planted foot line.
	float body = 1.0 - smoothstep(hips_y - 18.0, feet_y - 14.0, p.y);
	body *= 1.0 - max(max(weights.x, weights.y), max(weights.z, weights.w));
	shift += posture * body;
	return shift;
}

vec3 recolor_green(vec3 color) {
	// Green-only chroma mask preserves cocoa bands, pupils, eye whites and
	// highlights. Multiplicative luminance keeps the painted volume/shading.
	float green_excess = color.g - max(color.r, color.b);
	float mask = smoothstep(0.025, 0.16, green_excess);
	float value = max(max(color.r, color.g), color.b);
	float chroma = value - min(min(color.r, color.g), color.b);
	mask *= smoothstep(0.08, 0.30, chroma);
	float target_value = max(max(tint.r, tint.g), tint.b);
	vec3 target = tint.rgb / max(target_value, 0.001) * value;
	// Preserve bright reflected specular light instead of dyeing it flat.
	float highlight = smoothstep(0.60, 0.98, min(color.r, color.b));
	target = mix(target, vec3(value), highlight);
	return mix(color, target, mask);
}

void fragment() {
	vec2 point = (UV - atlas_rect.xy) / atlas_rect.zw * source_size;
	// Two bounded inverse-warp steps retain the painted connected silhouette.
	vec2 source = point - articulation(point);
	source = point - articulation(source);
	vec2 local_uv = source / source_size;
	float inside = step(0.0, local_uv.x) * step(0.0, local_uv.y)
		* step(local_uv.x, 1.0) * step(local_uv.y, 1.0);
	vec2 atlas_uv = atlas_rect.xy + local_uv * atlas_rect.zw;
	vec2 half_pixel = TEXTURE_PIXEL_SIZE * 0.5;
	atlas_uv = clamp(atlas_uv, atlas_rect.xy + half_pixel,
		atlas_rect.xy + atlas_rect.zw - half_pixel);
	vec4 painted = texture(TEXTURE, atlas_uv);
	painted.rgb = recolor_green(painted.rgb);
	COLOR = painted * item_modulate;
	COLOR.a *= inside;
}
