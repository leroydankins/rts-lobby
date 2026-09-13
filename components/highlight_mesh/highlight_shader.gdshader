shader_type spatial;

uniform vec3 line_color = vec3(1.0, 1.0, 0.0);
uniform float radius = 0.5;
uniform float line_width = 0.01;
uniform float alpha = 1;
uniform bool hollow = false;
float circle(vec2 position, float rad, float feather) {
	return smoothstep(radius, rad + feather, dot(position, position) * 4.0);
}

void fragment() {
	float dist = length(UV - vec2(0.5));
	if (hollow)
	{
		if (dist > radius - line_width && dist < radius)
		{
			circle(UV, radius, 0.005);
			ALBEDO = line_color;
			ALPHA = alpha;
		}
			else {
		ALPHA = 0.0;
		}
	}
	else
	{
		if (dist < radius)
		{
		circle(UV, radius, 0.005);
		ALBEDO = line_color;
		ALPHA = alpha;
		}
		else {
		ALPHA = 0.0;
		}
	}


}

void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
