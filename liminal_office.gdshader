shader_type spatial;

// Colors for walls, lines, floor, ceiling, and exposed wall layer
uniform vec4 wall_color : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Base wall color
//uniform vec4 exposed_wall_color : source_color = vec4(0.5, 0.3, 0.2, 1.0); // Color of the exposed layer
uniform vec4 thick_line_color : source_color = vec4(0.0, 1.0, 1.0, 1.0); // Thicker line color
uniform vec4 thin_line_color : source_color = vec4(0.0, 0.5, 0.5, 1.0); // Thinner line color
uniform vec4 ceiling_color : source_color = vec4(0.9, 0.9, 0.9, 1.0); // Ceiling color
uniform vec3 floor_color : source_color = vec3(0.6, 0.6, 0.6); // Floor color
uniform vec3 floor_color1 : source_color = vec3(0.9, 0.85, 0.8); // Light beige
uniform vec3 floor_color2 : source_color = vec3(0.7, 0.65, 0.6); // Warm gray
uniform vec3 floor_color3 : source_color = vec3(0.5, 0.45, 0.4); // Darker brown

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
uniform float threshold : hint_range(0.0, 1.0) = 0.67; // Controls the peeling effect
uniform int noise_octaves = 4;
uniform float noise_persistence : hint_range(0.0, 1.0) = 0.5;

// Additional noise layer properties
uniform float detail_noise_scale : hint_range(0.1, 10.0) = 5.0;
uniform float detail_noise_intensity : hint_range(0.0, 0.5) = 0.1;

// Pixelation properties
uniform float pixel_size : hint_range(0.01, 1.0) = 0.1; // Controls the pixelation level

// Floor properties
uniform float terrazzo_scale : hint_range(10.0, 100.0) = 10.0; // Controls the density of the specks

// Ceiling properties
uniform float ceiling_tile_size = 0.6; // Controls the size of each ceiling tile
uniform float ceiling_grid_line_width = 0.02; // Controls the width of the grid lines between tiles

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

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 terrazzoPattern(vec2 p, float scale, float p_size) {
	// Pixelation effect
	vec2 pixel_pos = floor(p / p_size) * p_size;
	
	vec2 i = floor(pixel_pos * scale);
	vec2 f = fract(pixel_pos * scale);
	vec3 color = floor_color; // Base color of the concrete or resin
	
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y));
			vec2 r_offset = vec2(hash12(i + offset), hash12(i + offset + vec2(1.0)));
			float dist = length(f - r_offset + offset);
			float radius = 0.1 + 0.1 * hash12(i + offset + vec2(2.0));
			
			if (dist < radius) {
				float mix_ratio = smoothstep(radius, radius - 0.02, dist);
				float color_choice = hash12(i + offset + vec2(6.0)); // Random choice for color
				vec3 speck_color = floor_color1;
				if (color_choice < 0.33) {
					speck_color = floor_color1;
				} else if (color_choice < 0.66) {
					speck_color = floor_color2;
				} else {
					speck_color = floor_color3;
				}
				color = mix(color, speck_color, mix_ratio);
			}
		}
	}
	return color;
}

vec3 ceilingTilePattern(vec2 p, float p_size) {
	// Pixelation effect
	vec2 pixel_pos = floor(p / p_size) * p_size;
	
	// Calculate the position within each tile
	vec2 tile_position = mod(p + ceiling_grid_line_width * 0.5, ceiling_tile_size);
	
	float w = ceiling_grid_line_width;
	// Determine if the position is in the 'grout' area (the seams between tiles)
	bool in_grout = tile_position.x < w || tile_position.y < w;
	
	// Base color is the main ceiling color
	vec3 tile_color = ceiling_color.rgb;
	
	// Darken the grout to simulate depth
	if (in_grout) {
		tile_color *= 0.8;
	}
	
	return tile_color;
}


void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_dir = NORMAL;
	
	// Apply a small offset along the normal to prevent Z-fighting
	world_pos += normal_dir * 0.001;
	VERTEX.y += 0.001;
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
		ALBEDO = (wall_color.rgb * 0.85) + (detail * 0.55);
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
		vec3 terrazzo_color = terrazzoPattern(world_pos.xz, terrazzo_scale, pixel_size * 0.5);
		ALBEDO = terrazzo_color + detail * 0.4;
		ROUGHNESS = 0.5 + detail * 0.4; // Adjust for a slightly glossy finish
		SPECULAR = 0.3 + detail * 0.4; // Terrazzo floors can be quite reflective
	}
	
	if (normal_dir.y < -0.9) {
		vec3 ceiling_tile_color = ceilingTilePattern(world_pos.xz, pixel_size);
		ALBEDO = ceiling_tile_color + detail * 0.5;
		ROUGHNESS = 0.8 + detail * 0.5;
		SPECULAR = 0.1 + detail * 0.5;
	}
}
