shader_type canvas_item;
#ifdef GL_ES
precision mediump float;
#endif
uniform vec2 u_resolution; // canvas size (width, height)
uniform vec2 u_mouse; // mouse position in screen pixels
uniform float u_time; //Time in seconds


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR = vec4(.3,.25,.8,abs(sin(TIME * 0.75)));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
