@tool
extends Control

signal mouse_pressed

@export var texture: Texture2D = null
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		$TextureRect.flip_h = value
@export var flip_v: bool = false:
	set(value):
		flip_v = value
		$TextureRect.flip_v = value

var default_texture := PlaceholderTexture2D.new()


func _ready() -> void:
	if texture != null:
		$TextureRect.texture = texture
	else:
		$TextureRect.texture = default_texture


func _on_texture_rect_mouse_entered() -> void:
	$TextureRect.material.set_shader_parameter("highlighted", true);


func _on_texture_rect_mouse_exited() -> void:
	$TextureRect.material.set_shader_parameter("highlighted", false);


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if texture != null and $TextureRect.texture != texture:
			$TextureRect.texture = texture
		elif texture == null and $TextureRect.texture != default_texture:
			$TextureRect.texture = default_texture


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouse_pressed.emit()
