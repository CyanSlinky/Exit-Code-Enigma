shader_type canvas_item;

uniform float circleRadius = 0.1;

float sdCircle( in vec2 p, in float r ) 
{
	return length(p)-r;
}

void fragment() {
	float d = sdCircle(UV - 0.5, circleRadius);
	float w = fwidth(0.5*d) * 2.0;
	vec3 colorResult = vec3(1);
	float alphaResult = 1.0-smoothstep(-w, w, d);
	COLOR = vec4(colorResult, alphaResult);
}
