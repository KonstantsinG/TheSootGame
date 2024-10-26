@tool
extends Control

signal mouse_pressed

@export var base_texture : Texture2D = null
@export var title_texture : Texture2D = null

var default_texture = PlaceholderTexture2D.new()


func _ready() -> void:
	if base_texture != null:
		$VBoxContainer/BaseTexture.texture = base_texture
	else:
		$VBoxContainer/BaseTexture.texture = default_texture
	
	if title_texture != null:
		$VBoxContainer/TitleTexture.texture = title_texture
	else:
		$VBoxContainer/TitleTexture.texture = title_texture


func _on_mouse_entered() -> void:
	material.set_shader_parameter("highlighted", true)


func _on_mouse_exited() -> void:
	material.set_shader_parameter("highlighted", false)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if base_texture != null and $VBoxContainer/BaseTexture.texture != base_texture:
			$VBoxContainer/BaseTexture.texture = base_texture
		elif base_texture == null and $VBoxContainer/BaseTexture.texture != default_texture:
			$VBoxContainer/BaseTexture.texture = default_texture
		
		if title_texture != null and $VBoxContainer/TitleTexture.texture != title_texture:
			$VBoxContainer/TitleTexture.texture = title_texture
		elif title_texture == null and $VBoxContainer/TitleTexture.texture != default_texture:
			$VBoxContainer/TitleTexture.texture = default_texture


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouse_pressed.emit()
