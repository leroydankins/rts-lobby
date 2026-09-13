shader_type spatial;
uniform int num_active_circles = 0;
uniform vec3 range_color : source_color;
uniform vec3 range_positions[60];
uniform float range_radius;
uniform float outlineThickness = 0.8;
varying vec3 world_position;
varying vec3 base_color;

float circleSDF(vec2 point, int index) {
	return distance(point, range_positions[index].xz) - range_radius;
}

void fragment() {
	if (num_active_circles > 0) {
		vec2 position2D = world_position.xz;
		float totalSDF = 1e5;
		for (int i = 0; i < num_active_circles; i++) {
			float currentSDF = circleSDF(position2D, i);
			totalSDF = min(totalSDF, currentSDF);
		}

	if (abs(totalSDF) < outlineThickness) {
		float emissionBlendFactor = smoothstep(outlineThickness, outlineThickness * 0.5, abs(totalSDF));
		base_color = mix(base_color, range_color.rgb, emissionBlendFactor);
		}
			}
}
