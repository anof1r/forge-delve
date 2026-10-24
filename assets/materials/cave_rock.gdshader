shader_type spatial;
render_mode world_vertex_coords;

varying vec3 rock_position;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.13, 0.37, 0.71));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
		mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
		mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

void vertex() {
	rock_position = VERTEX;
}

void fragment() {
	float broad = noise(rock_position * 1.7);
	float grain = noise(rock_position * 25.0) * 0.65 + noise(rock_position * 65.0) * 0.35;
	float layers = sin(rock_position.y * 26.0 + broad * 6.0 + noise(rock_position * 4.0));
	float cracks = smoothstep(0.82, 0.99, layers) * 0.3;
	ALBEDO = mix(vec3(0.035, 0.045, 0.05), vec3(0.17, 0.16, 0.14), broad)
		* (0.7 + grain * 0.5 - cracks);
	ROUGHNESS = 0.94;
	SPECULAR = 0.2;
}
