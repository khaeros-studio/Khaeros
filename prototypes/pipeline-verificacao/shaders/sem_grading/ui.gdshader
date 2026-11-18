shader_type canvas_item;
#include "res://shaders/familias/sem_grading.gdshaderinc"

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
