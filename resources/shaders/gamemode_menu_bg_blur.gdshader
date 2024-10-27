shader_type canvas_item;

//Blur Sharp
uniform float blur_sharp: hint_range(-5.0, 5.0, 0.1) = 1.0;
uniform float pixel: hint_range(1.0, 5.0, 1.0) = 0.5;

uniform float brightness : hint_range(-1, 1) = 0;
uniform float contrast : hint_range(0, 3) = 1.0;
uniform float saturation : hint_range(0, 3) = 1.0;


mat4 contrastMatrix( float _contrast ){
	float t = ( 1.0 - _contrast ) / 2.0;
	return mat4(
		vec4(_contrast, 0, 0, 0),
		vec4(0, _contrast, 0, 0),
		vec4(0, 0, _contrast, 0),
		vec4(t, t, t, 1));
}

mat4 brightnessMatrix( float _brightness ){
	return mat4( vec4(1, 0, 0, 0),
				 vec4(0, 1, 0, 0),
				 vec4(0, 0, 1, 0),
				 vec4(_brightness, _brightness, _brightness, 1));
}

mat4 saturationMatrix( float _saturation ){
	vec3 luminance = vec3( 0.3086, 0.6094, 0.0820 );
	float oneMinusSat = 1.0 - _saturation;

	float redVal = 1.0;
	float greenVal = 1.0;
	float blueVal = 1.0;

	vec3 red = vec3( luminance.x * oneMinusSat );
	red+= vec3(_saturation, 0, 0)*redVal;
	vec3 green = vec3( luminance.y * oneMinusSat );
	green += vec3( 0,_saturation, 0 )*greenVal;
	vec3 blue = vec3( luminance.z * oneMinusSat );
	blue += vec3( 0, 0,_saturation )*blueVal;

	return mat4(vec4(red, 0),vec4(green,0),vec4(blue,0),vec4(0, 0, 0, 1));
}


void fragment() {
	// Screen Coordinates
	vec2 coord = (1.0 / FRAGCOORD.xy) * UV;
	// Screen Sample
	vec3 screen = texture(TEXTURE, UV).rgb;
	//Blur Sharp Sample
	vec3 N = texture(TEXTURE, UV + (coord * (vec2(0.0, pixel)))).rgb;
	vec3 S = texture(TEXTURE, UV + (coord * (vec2(0.0, -pixel)))).rgb;
	vec3 NE = texture(TEXTURE, UV + (coord * (vec2(pixel, pixel)))).rgb;
	vec3 SE = texture(TEXTURE, UV + (coord * (vec2(pixel, -pixel)))).rgb;
	vec3 NW = texture(TEXTURE, UV + (coord * (vec2(-pixel, pixel)))).rgb;
	vec3 SW = texture(TEXTURE, UV + (coord * (vec2(-pixel,-pixel)))).rgb;
	//Combined Samples
	vec3 combine_sample = ((N + S + NE + SE + NW + SW) / 6.0) * 0.7;
	vec3 blur_screen = clamp((screen * 0.3) + combine_sample, 0.0, 1.0);
	//Final COLOR
	vec3 mix_blur_sharp = mix(screen, blur_screen, blur_sharp);

	COLOR = contrastMatrix(contrast) * brightnessMatrix(brightness) * saturationMatrix(saturation) * vec4(mix_blur_sharp, 1.0);
}