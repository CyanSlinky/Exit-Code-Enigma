shader_type spatial;

// Colors for walls, lines, floor, ceiling, and exposed wall layer
uniform vec4 wall_color : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Base wall color
uniform vec4 exposed_wall_color : source_color = vec4(0.5, 0.3, 0.2, 1.0); // Color of the exposed layer
uniform vec4 thick_line_color : source_color = vec4(0.0, 1.0, 1.0, 1.0); // Thicker line color
uniform vec4 thin_line_color : source_color = vec4(0.0, 0.5, 0.5, 1.0); // Thinner line color
uniform vec4 floor_color : source_color = vec4(0.7, 0.7, 0.7, 1.0); // Floor color
uniform vec4 ceiling_color : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Ceiling color

// Line properties
uniform float line_height : hint_range(-100.0, 100.0) = 5.0;
uniform float thick_line_width : hint_range(0.0, 0.5) = 0.05;
uniform float thin_line_width : hint_range(0.0, 0.5) = 0.02;
uniform float line_offset : hint_range(0.0, 1.0) = 0.1;

// Wall texture properties
uniform float wall_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float wall_specular : hint_range(0.0, 1.0) = 0.1;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float threshold : hint_range(0.0, 1.0) = 0.5; // Controls the peeling effect
uniform int noise_octaves = 4;
uniform float noise_persistence : hint_range(0.0, 1.0) = 0.5;

// Additional noise layer properties
uniform float detail_noise_scale : hint_range(0.1, 10.0) = 5.0;
uniform float detail_noise_intensity : hint_range(0.0, 0.5) = 0.1;

// Pixelation properties
uniform float pixel_size : hint_range(0.01, 1.0) = 0.1; // Controls the pixelation level

// Variables for world position and normal
varying vec3 world_pos;
varying vec3 normal_dir;

// 3D Perlin noise function
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

float lerp(float a, float b, float t) {
	return a + t * (b - a);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	
	float n00 = lerp(n000, n100, f.x);
	float n01 = lerp(n001, n101, f.x);
	float n10 = lerp(n010, n110, f.x);
	float n11 = lerp(n011, n111, f.x);
	
	float n0 = lerp(n00, n10, f.y);
	float n1 = lerp(n01, n11, f.y);
	return lerp(n0, n1, f.z);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 1.0;
	float frequency = noise_scale;
	float total_amplitude = 0.0;

	for (int i = 0; i < noise_octaves; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		total_amplitude += amplitude;
		amplitude *= noise_persistence;
	}
	
	return clamp(value / total_amplitude, 0.0, 1.0);
}

// Function to generate a subtle pixelated noise texture
float detail_noise(vec3 p, float n_scale, float p_size) {
	vec3 pixelated_pos = floor(p / p_size) * p_size;
	return noise(pixelated_pos * n_scale);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_dir = NORMAL;
	
	// Apply a small offset along the normal to prevent Z-fighting
	world_pos += normal_dir * 0.001;
}

void fragment() {
	vec3 pixelated_pos = floor(world_pos / pixel_size) * pixel_size;
	
	// Generate procedural plaster texture using 3D fBM noise
	float texture_noise = fbm(pixelated_pos);
	bool is_exposed = texture_noise > threshold;
	
	// Generate subtle detail noise
	float detail = detail_noise(world_pos, detail_noise_scale, pixel_size) * detail_noise_intensity;
	//float fine_detail = detail_noise(world_pos, 20.0, pixel_size / 2.0) * 0.05;
	//float floor_detail = detail_noise(world_pos, 2.0, pixel_size) * 0.02;
	
	// Set base color with additionasl noise for intact wall sections
	if (is_exposed) {
		ALBEDO = exposed_wall_color.rgb + (detail * 0.55);
		ROUGHNESS = wall_roughness + detail;
		SPECULAR = wall_specular + detail;
	} else {
		ALBEDO = wall_color.rgb + detail;
		ROUGHNESS = wall_roughness + detail;
		SPECULAR = wall_specular + detail;
	}
	
	// Calculate distance to the lines
	float distance_to_thick_line = abs(world_pos.y - line_height);
	float distance_to_thin_line = abs(world_pos.y - (line_height - line_offset));
	
	if (distance_to_thick_line < thick_line_width && !is_exposed) {
		ALBEDO = thick_line_color.rgb + detail;
	}
	
	if (distance_to_thin_line < thin_line_width && !is_exposed) {
		ALBEDO = thin_line_color.rgb + detail;
	}
	
	if (normal_dir.y > 0.9) {
		ALBEDO = floor_color.rgb + detail;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	}
	
	if (normal_dir.y < -0.9) {
		ALBEDO = ceiling_color.rgb + detail * 0.5;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	}
}
