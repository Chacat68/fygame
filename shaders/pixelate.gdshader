shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 100.0, 1.0) = 100.0;

void fragment() {
	// 获取纹理大小
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// 计算像素化效果
	float x = floor(UV.x * texture_size.x / pixel_size) * pixel_size / texture_size.x;
	float y = floor(UV.y * texture_size.y / pixel_size) * pixel_size / texture_size.y;
	
	// 应用像素化效果
	vec4 color = texture(TEXTURE, vec2(x, y));
	
	// 输出颜色
	COLOR = color;
}