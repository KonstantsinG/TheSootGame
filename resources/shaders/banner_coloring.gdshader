shader_type canvas_item;

uniform float red_value : hint_range(-1.0, 1.0, 0.05) = 0.0;
uniform float green_value : hint_range(-1.0, 1.0, 0.05) = 0.0;
uniform float blue_value : hint_range(-1.0, 1.0, 0.05) = 0.0;
uniform bool is_pale = false;
uniform bool is_bright = false;


void fragment() {
	vec3 tex = texture(TEXTURE, UV).rgb;
	COLOR.rgb = tex + vec3(red_value, green_value, blue_value);
	
	if (is_pale){
		vec3 pale_value = vec3(0.4);
		COLOR.rgb += pale_value;
	}
	if (is_bright){
		vec3 brightness_value = vec3(0.2);
		COLOR.rgb -= brightness_value;
	}
}
