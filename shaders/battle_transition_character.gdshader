shader_type canvas_item;

uniform float outline_thickness : hint_range(0.0, 10.0) = 2.0;  // Espessura do contorno
uniform float transition : hint_range(0.0, 1.0) = 0.0;  // Transição de preto para cor original

void fragment() {
	// Coordenadas de UV
	vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

	// Pegando a cor original do sprite
	vec4 original_color = texture(TEXTURE, uv);

	// Variação de UV para verificar pixels ao redor
	float offset = outline_thickness / SCREEN_PIXEL_SIZE.x;

	// Pegando a média da transparência ao redor
	float alpha_left = texture(TEXTURE, uv + vec2(-offset, 0.0)).a;
	float alpha_right = texture(TEXTURE, uv + vec2(offset, 0.0)).a;
	float alpha_up = texture(TEXTURE, uv + vec2(0.0, -offset)).a;
	float alpha_down = texture(TEXTURE, uv + vec2(0.0, offset)).a;

	// Se a transparência ao redor variar, estamos em um contorno
	bool is_outline = original_color.a > 0.0 && (alpha_left == 0.0 || alpha_right == 0.0 || alpha_up == 0.0 || alpha_down == 0.0);

	// Se estivermos no contorno, pintar de preto, senão, manter a cor original
	vec4 final_color = original_color;
	if (is_outline) {
		final_color.rgb = mix(vec3(0.0), original_color.rgb, transition);  // Cor preta no contorno
	}

	// Definir a cor final
	COLOR = final_color;
}
