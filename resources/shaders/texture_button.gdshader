shader_type canvas_item;

uniform bool highlighted = false;
uniform float brightness : hint_range(0.0, 2.0, 0.1) = 0.6;

void fragment() {
	if (highlighted){
		COLOR.rgb = texture(TEXTURE, UV).rgb * brightness;
	}
}
