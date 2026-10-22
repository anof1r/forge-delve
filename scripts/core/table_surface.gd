class_name TableSurface
extends MeshInstance3D
## Деревянный стол таверны под картой. Доски и волокна рисует шейдер, поэтому
## внешние текстуры не нужны; для реального арта достаточно заменить материал.

const SIZE := 120.0

const _SHADER := """
shader_type spatial;

uniform float plank_width = 2.4;
uniform float plank_length = 11.0;
uniform vec3 dark_wood : source_color = vec3(0.26, 0.14, 0.07);
uniform vec3 light_wood : source_color = vec3(0.52, 0.31, 0.15);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float row = floor(p.y / plank_width);
	float shift = hash(vec2(row, 3.0)) * plank_length;
	vec2 q = vec2(p.x + shift, p.y);
	vec2 id = vec2(floor(q.x / plank_length), row);

	float tone = hash(id);
	float grain = fbm(vec2(q.x * 0.5, q.y * 8.0) + tone * 40.0);
	float rings = sin((q.y + grain * 1.6) * 16.0) * 0.5 + 0.5;
	float knots = smoothstep(0.78, 0.95, fbm(q * 0.7 + tone * 20.0));

	vec3 color = mix(dark_wood, light_wood, tone * 0.7 + grain * 0.5);
	color *= 0.85 + 0.3 * rings;
	color *= 1.0 - knots * 0.35;

	vec2 f = vec2(fract(q.x / plank_length), fract(q.y / plank_width));
	float gap = min(min(f.y, 1.0 - f.y) * plank_width, min(f.x, 1.0 - f.x) * plank_length);
	color *= mix(0.25, 1.0, smoothstep(0.0, 0.05, gap));

	ALBEDO = color;
	ROUGHNESS = 0.7;
}
"""


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh = plane
	var shader := Shader.new()
	shader.code = _SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material_override = material
